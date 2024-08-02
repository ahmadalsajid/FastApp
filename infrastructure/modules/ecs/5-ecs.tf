resource "aws_ecs_cluster" "app_cluster" {
  name = "${var.environment}-${var.cluster_name}-ecs-cluster"

  tags = {
    Name        = "${var.environment}-${var.cluster_name}-ecs-cluster"
    ManagedBy   = "Terraform"
    environment = var.environment
  }
}

resource "aws_ecs_task_definition" "app" {
  family                   = "${var.environment}-${var.cluster_name}-ecs-task-definition"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.fargate_cpu
  memory                   = var.fargate_memory

  container_definitions = templatefile("${path.module}/templates/ecs/app.json.tpl",
    {
      name           = "${var.environment}-${var.cluster_name}"
      app_image      = var.app_image
      app_port       = var.app_port
      fargate_cpu    = var.fargate_cpu
      fargate_memory = var.fargate_memory
      aws_region     = var.aws_region
    }
  )

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "ARM64"
  }

  tags = {
    Name        = "${var.environment}-${var.cluster_name}-ecs-task-definition"
    ManagedBy   = "Terraform"
    environment = var.environment
  }
}

resource "aws_ecs_service" "app" {
  name            = "${var.environment}-${var.cluster_name}-ecs-app-service"
  cluster         = aws_ecs_cluster.app_cluster.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = var.app_count
  launch_type     = "FARGATE"

  network_configuration {
    security_groups  = [aws_security_group.ecs_tasks_sg.id]
    subnets          = data.aws_subnets.public.ids
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.elb_target_group.arn
    container_name   = "${var.environment}-${var.cluster_name}"
    container_port   = var.app_port
  }

  depends_on = [
    aws_lb_listener.app_lb_listener, aws_iam_role_policy_attachment.ecs_task_execution_role_policy_attachment
  ]
}

resource "aws_appautoscaling_target" "target" {
  max_capacity       = var.max_capacity
  min_capacity       = var.min_capacity
  resource_id        = "service/${aws_ecs_cluster.app_cluster.name}/${aws_ecs_service.app.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
  role_arn           = aws_iam_role.ecs_auto_scale_role.arn
}

resource "aws_appautoscaling_policy" "scale_out" {
  name               = "${var.environment}-${var.cluster_name}-scale-out"
  resource_id        = "service/${aws_ecs_cluster.app_cluster.name}/${aws_ecs_service.app.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 60
    metric_aggregation_type = "Maximum"

    step_adjustment {
      metric_interval_lower_bound = 0
      scaling_adjustment          = 1
    }
  }

  depends_on = [aws_appautoscaling_target.target]
}

resource "aws_appautoscaling_policy" "scale_in" {
  name               = "${var.environment}-${var.cluster_name}-scale-in"
  resource_id        = "service/${aws_ecs_cluster.app_cluster.name}/${aws_ecs_service.app.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 60
    metric_aggregation_type = "Maximum"

    step_adjustment {
      metric_interval_lower_bound = 0
      scaling_adjustment          = -1
    }
  }

  depends_on = [aws_appautoscaling_target.target]
}

resource "aws_cloudwatch_metric_alarm" "service_cpu_high" {
  alarm_name          = "${var.environment}-${var.cluster_name}_cpu_utilization_high"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "60"
  statistic           = "Average"
  threshold           = "85"

  dimensions = {
    ClusterName = aws_ecs_cluster.app_cluster.name
    ServiceName = aws_ecs_service.app.name
  }

  alarm_actions = [aws_appautoscaling_policy.scale_out.arn]
}

# CloudWatch alarm that triggers the autoscaling down policy
resource "aws_cloudwatch_metric_alarm" "service_cpu_low" {
  alarm_name          = "${var.environment}-${var.cluster_name}_cpu_utilization_low"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "60"
  statistic           = "Average"
  threshold           = "10"

  dimensions = {
    ClusterName = aws_ecs_cluster.app_cluster.name
    ServiceName = aws_ecs_service.app.name
  }

  alarm_actions = [aws_appautoscaling_policy.scale_in.arn]
}

resource "aws_cloudwatch_log_group" "app_log_group" {
  name              = "/ecs/${var.environment}-${var.cluster_name}"
  retention_in_days = 30

  tags = {
    Name        = "${var.environment}-${var.cluster_name}-log-group"
    ManagedBy   = "Terraform"
    environment = var.environment
  }
}

resource "aws_cloudwatch_log_stream" "cb_log_stream" {
  name           = "${var.environment}-${var.cluster_name}-log-stream"
  log_group_name = aws_cloudwatch_log_group.app_log_group.name
}