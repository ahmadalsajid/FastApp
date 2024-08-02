variable "aws_region" {
  description = "The AWS region things are created in"
  type        = string
  # default     = "us-east-1"
}
variable "cluster_name" {
  description = "Cluster name to identify all resources"
  type        = string
  # default     = "FastApp"
}
variable "environment" {
  description = "the environment we will be deploying for"
  type        = string
  # default     = "dev"
}

variable "vpc_id" {
  description = "VPC ID where all the ECS resources will be created"
  type        = string
  #   # default     = ""
}

variable "app_image" {
  description = "Docker image to run in the ECS cluster"
  type        = string
  # default     = "ahmadalsajid/fast-app:latest"
}

variable "app_port" {
  description = "Port exposed by the docker image to redirect traffic to"
  type        = number
  # default     = 8000

}

variable "app_count" {
  description = "Number of docker containers to run"
  type        = number
  # default     = 1
}

variable "max_capacity" {
  description = "Maximum number of docker containers to run"
  type        = number
  # default     = 3
}

variable "min_capacity" {
  description = "Minimum of docker containers to run"
  type        = number
  # default     = 1
}

variable "health_check_path" {
  description = "App healthcheck path"
  type        = string
  # default     = "/"
}

variable "fargate_cpu" {
  description = "Fargate instance CPU units to provision (1 vCPU = 1024 CPU units)"
  type        = number
  # default     = 512
}

variable "fargate_memory" {
  description = "Fargate instance memory to provision (in MiB)"
  type        = number
  # default     = 1024
}

locals {
  http_port      = 80
  https_port     = 443
  any_port       = 0
  any_protocol   = "-1"
  tcp_protocol   = "tcp"
  http_protocol  = "HTTP"
  https_protocol = "HTTPS"
  all_ips        = ["0.0.0.0/0"]
}