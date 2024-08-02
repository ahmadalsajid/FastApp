output "vpc" {
  description = "VPC ID of the ECS"
  value       = data.aws_vpc.this.id
}
output "alb_hostname" {
  description = "Application Load Balancer DNS name"
  value       = aws_lb.this.dns_name
}