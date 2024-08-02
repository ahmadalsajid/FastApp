output "vpc" {
  description = "VPC ID of the ECS cluster"
  value       = module.ecs_cluster.vpc
}
output "alb_hostname" {
  description = "Application Load Balancer DNS name"
  value       = module.ecs_cluster.alb_hostname
}