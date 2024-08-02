resource "aws_lb" "this" {
  name               = "${var.environment}-${var.cluster_name}-alb"
  subnets            = data.aws_subnets.public.ids
  security_groups    = [aws_security_group.alb_sg.id]
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