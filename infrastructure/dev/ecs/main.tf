terraform {
  required_version = ">= 1.0.0, < 2.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

}

data "aws_vpc" "this" {
  filter {
    name = "vpc-id"
    values = [var.vpc_id]
  }
}

data "aws_subnets" "private" {
  filter {
    name = "vpc-id"
    values = [data.aws_vpc.this.id]
  }
  tags = {
    Name = "*private*"
  }
}

data "aws_subnets" "public" {
  filter {
    name = "vpc-id"
    values = [data.aws_vpc.this.id]
  }

  tags = {
    Name = "*public*"
  }
}

resource "aws_security_group" "alb_sg" {
  name   = "${var.environment}-${var.cluster_name}-alb-sg"
  vpc_id = data.aws_vpc.this.id

  tags = {
    Name        = "${var.environment}-${var.cluster_name}-alb-sg"
    ManagedBy   = "Terraform"
    environment = var.environment
  }
}

resource "aws_security_group_rule" "alb_sg_inbound" {
  security_group_id = aws_security_group.alb_sg.id
  from_port         = local.http_port
  protocol          = local.tcp_protocol
  to_port           = local.http_port
  type              = "ingress"
  cidr_blocks       = local.all_ips
}

resource "aws_security_group_rule" "alb_sg_outbound" {
  security_group_id = aws_security_group.alb_sg.id
  from_port         = local.any_port
  protocol          = local.any_protocol
  to_port           = local.any_port
  type              = "egress"
  cidr_blocks       = local.all_ips
}

resource "aws_security_group" "ecs_tasks_sg" {
  name   = "${var.environment}-${var.cluster_name}-ecs-taska-sg"
  vpc_id = data.aws_vpc.this.id

  tags = {
    Name        = "${var.environment}-${var.cluster_name}-ecs-taska-sg"
    ManagedBy   = "Terraform"
    environment = var.environment
  }
}

resource "aws_security_group_rule" "ecs_tasks_sg_inbound" {
  security_group_id = aws_security_group.ecs_tasks_sg.id
  from_port         = var.app_port
  protocol          = local.tcp_protocol
  to_port           = var.app_port
  type              = "ingress"
  cidr_blocks       = local.all_ips
}

resource "aws_security_group_rule" "ecs_tasks_sg_outbound" {
  security_group_id = aws_security_group.ecs_tasks_sg.id
  from_port         = local.any_port
  protocol          = local.any_protocol
  to_port           = local.any_port
  type              = "egress"
  cidr_blocks       = local.all_ips
}

resource "aws_lb" "this" {
  name               = "${var.environment}-${var.cluster_name}-alb"
  subnets            = data.aws_subnets.public.ids
  security_groups = [aws_security_group.alb_sg.id]
  load_balancer_type = "application"

  tags = {
    Name        = "${var.environment}-${var.cluster_name}-alb"
    ManagedBy   = "Terraform"
    environment = var.environment
  }
}

resource "aws_lb_target_group" "elb_target_group" {
  name        = "${var.environment}-${var.cluster_name}-alb-tg"
  port        = local.http_port
  protocol    = local.http_protocol
  vpc_id      = data.aws_vpc.this.id
  target_type = "ip"

  health_check {
    healthy_threshold   = 3
    interval            = 60
    protocol            = local.http_protocol
    matcher             = "200-399"
    timeout             = 30
    path                = var.health_check_path
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener" "app_lb_listener" {
  load_balancer_arn = aws_lb.this.id
  port              = local.http_port
  protocol          = local.http_protocol

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.elb_target_group.id
  }
}

resource "aws_ecs_cluster" "app_cluster" {
  name = "${var.environment}-${var.cluster_name}-ecs-cluster"

  tags = {
    Name        = "${var.environment}-${var.cluster_name}-ecs-cluster"
    ManagedBy   = "Terraform"
    environment = var.environment
  }
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name = "${var.environment}-${var.cluster_name}-ecs-task-execution-role"

  assume_role_policy = <<-EOF
                            {
                             "Version": "2012-10-17",
                             "Statement": [
                               {
                                 "Action": "sts:AssumeRole",
                                 "Principal": {
                                   "Service": "ecs-tasks.amazonaws.com"
                                 },
                                 "Effect": "Allow",
                                 "Sid": ""
                               }
                             ]
                            }
                          EOF

  tags = {
    Name        = "${var.environment}-${var.cluster_name}-ecs-task-execution-role"
    ManagedBy   = "Terraform"
    environment = var.environment
  }
}

resource "aws_iam_role" "ecs_task_role" {
  name = "${var.environment}-${var.cluster_name}-ecs-task-role"

  assume_role_policy = <<-EOF
                            {
                             "Version": "2012-10-17",
                             "Statement": [
                               {
                                 "Action": "sts:AssumeRole",
                                 "Principal": {
                                   "Service": "ecs-tasks.amazonaws.com"
                                 },
                                 "Effect": "Allow",
                                 "Sid": ""
                               }
                             ]
                            }
                          EOF

  tags = {
    Name        = "${var.environment}-${var.cluster_name}-ecs-task-role"
    ManagedBy   = "Terraform"
    environment = var.environment
  }
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
  role       = aws_iam_role.ecs_task_execution_role.name
}

resource "aws_iam_role_policy_attachment" "task_s3" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
  role       = aws_iam_role.ecs_task_role.name
}

data "aws_iam_policy_document" "ecs_auto_scale_role" {
  version = "2012-10-17"
  statement {
    effect = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type = "Service"
      identifiers = ["application-autoscaling.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_auto_scale_role" {
  name               = "${var.environment}-${var.cluster_name}-ecs-autosclaing-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_auto_scale_role.json
}

# ECS auto scale role policy attachment
resource "aws_iam_role_policy_attachment" "ecs_auto_scale_role" {
  role       = aws_iam_role.ecs_auto_scale_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceAutoscaleRole"
}


# data "template_file" "app_template" {
#   template = templatefile("./templates/ecs/app.json.tpl",
#     {
#       name           = "${var.environment}-${var.cluster_name}"
#       app_image      = var.app_image
#       app_port       = var.app_port
#       fargate_cpu    = var.fargate_cpu
#       fargate_memory = var.fargate_memory
#       aws_region     = var.aws_region
#     }
#   )
# }

resource "aws_ecs_task_definition" "app" {
  family             = "${var.environment}-${var.cluster_name}-ecs-task-definition"
  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn
  network_mode       = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                = var.fargate_cpu
  memory = var.fargate_memory
  #   container_definitions = data.template_file.app_template.rendered

  container_definitions = templatefile("./templates/ecs/app.json.tpl",
    {
      name           = "${var.environment}-${var.cluster_name}"
      app_image      = var.app_image
      app_port       = var.app_port
      fargate_cpu    = var.fargate_cpu
      fargate_memory = var.fargate_memory
      aws_region     = var.aws_region
    }
  )

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
    security_groups = [aws_security_group.ecs_tasks_sg.id]
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