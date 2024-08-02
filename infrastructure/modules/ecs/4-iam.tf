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

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
  role       = aws_iam_role.ecs_task_execution_role.name
}

data "aws_iam_policy_document" "ecs_auto_scale_role" {
  version = "2012-10-17"
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["application-autoscaling.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_auto_scale_role" {
  name               = "${var.environment}-${var.cluster_name}-ecs-autosclaing-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_auto_scale_role.json
}

resource "aws_iam_role_policy_attachment" "ecs_auto_scale_role" {
  role       = aws_iam_role.ecs_auto_scale_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceAutoscaleRole"
}