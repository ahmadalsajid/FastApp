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

module "ecs_cluster" {
  source = "../../modules/ecs"

  vpc_id            = var.vpc_id
  app_count         = var.app_count
  app_image         = var.app_image
  app_port          = var.app_port
  aws_region        = var.aws_region
  cluster_name      = var.cluster_name
  environment       = var.environment
  fargate_cpu       = var.fargate_cpu
  fargate_memory    = var.fargate_memory
  health_check_path = var.health_check_path
  max_capacity      = var.max_capacity
  min_capacity      = var.min_capacity
}