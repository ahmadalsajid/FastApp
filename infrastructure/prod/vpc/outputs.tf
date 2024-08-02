output "vpc_id" {
  description = "ID of the newly created VPC"
  value       = module.vpc.vpc_id
}

output "private_subnet_ids" {
  description = "VPC private subnets"
  value       = module.vpc.private_subnet_ids
}

output "public_subnet_ids" {
  description = "VPC public subnets"
  value       = module.vpc.public_subnet_ids
}