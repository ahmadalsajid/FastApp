output "ec2_ip" {
  description = "Public IP of the EC2 instance"
  value       = aws_instance.test_ec2.public_ip
}

output "vpc" {
  value = data.aws_vpc.this.id
}

output "public_subnets" {
  value = data.aws_subnets.private.ids
}

output "private_subnets" {
  value = data.aws_subnets.public.ids
}