output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.this.id
}

output "private_subnet_ids" {
  description = "ID of the private subnets of this VPC"
  value       = aws_subnet.private[*].id
}

output "public_subnet_ids" {
  description = "ID of the public subnets of this VPC"
  value       = aws_subnet.public[*].id
}