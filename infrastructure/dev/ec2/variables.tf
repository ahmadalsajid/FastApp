variable "cluster_name" {
  description = "Cluster name to identify all resources"
  type        = string
  default     = "Fast-App"
}
variable "environment" {
  description = "the environment we will be deploying for"
  type        = string
  default     = "dev"
}

variable "server_port" {
  description = "The port the server will use for HTTP requests"
  type        = number
  default     = 80
}

variable "vpc_id" {
  description = "ID of the newly created VPC"
  type        = string
  default     = "vpc-05f402e2447cef5cf"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}