variable "cluster_name" {
  description = "Cluster name to identify all resources"
  type        = string
  default     = "Fast-App"
}

variable "aws_region" {
  description = "The AWS region things are created in"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "the environment we will be deploying for"
  type        = string
  default     = "dev"
}
variable "vpc_cidr_block" {
  description = "CIDR (Classless Inter-Domain Routing)"
  type        = string
  default     = "10.0.0.0/16"
}

variable "all_ips" {
  description = "CIDR (Classless Inter-Domain Routing) for all IP"
  type        = string
  default     = "0.0.0.0/0"
}

variable "availability_zones" {
  description = "Subnet Availability Zones"
  type = list(string)
  default = ["us-east-1a", "us-east-1b"]
}

variable "private_subnets" {
  description = "CIDR ranges for private subnets"
  type = list(string)
  default = ["10.0.0.0/19", "10.0.32.0/19"]
}

variable "public_subnets" {
  description = "CIDR ranges for public subnets"
  type = list(string)
  default = ["10.0.64.0/19", "10.0.96.0/19"]
}



