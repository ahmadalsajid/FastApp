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
  name   = "${var.environment}-${var.cluster_name}-ecs-tasks-sg"
  vpc_id = data.aws_vpc.this.id

  tags = {
    Name        = "${var.environment}-${var.cluster_name}-ecs-tasks-sg"
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