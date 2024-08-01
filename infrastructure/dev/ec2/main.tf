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
  region = "us-east-1"
}

locals {
  http_port    = 8000
  any_port     = 0
  any_protocol = "-1"
  tcp_protocol = "tcp"
  all_ips = ["0.0.0.0/0"]
}

data "aws_vpc" "this" {
  filter {
    name = "vpc-id"
    values = [var.vpc_id]
  }
}

data "aws_subnets" "private" {
  filter {
    name = "vpc-id"
    values = [data.aws_vpc.this.id]
  }
  tags = {
    Name = "*private*"
  }
}

data "aws_subnets" "public" {
  filter {
    name = "vpc-id"
    values = [data.aws_vpc.this.id]
  }

  tags = {
    Name = "*public*"
  }
}

data "aws_ami" "ubuntu_ami-latest" {
  owners = ["099720109477"] # Canonical
  most_recent = true

  filter {
    name = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }
}

resource "aws_security_group" "ec2_security_group" {
  name   = "${var.environment}-${var.cluster_name}-ec2-sg"
  vpc_id = data.aws_vpc.this.id

  tags = {
    Name        = "${var.environment}-${var.cluster_name}-ec2-sg"
    ManagedBy   = "Terraform"
    environment = var.environment
  }
}

resource "aws_security_group_rule" "allow_server_inbound" {
  from_port         = local.http_port
  protocol          = local.tcp_protocol
  security_group_id = aws_security_group.ec2_security_group.id
  to_port           = local.http_port
  type              = "ingress"
  cidr_blocks       = local.all_ips
}

resource "aws_security_group_rule" "allow_server_outbound" {
  from_port         = local.any_port
  protocol          = local.any_protocol
  security_group_id = aws_security_group.ec2_security_group.id
  to_port           = local.any_port
  type              = "egress"
  cidr_blocks       = local.all_ips
}

resource "aws_instance" "test_ec2" {
  ami           = data.aws_ami.ubuntu_ami-latest.id
  instance_type = var.instance_type

  subnet_id = data.aws_subnets.public.ids[0]
  vpc_security_group_ids = [aws_security_group.ec2_security_group.id]

  root_block_device {
    volume_size = 12

    tags = {
      Name        = "${var.environment}-${var.cluster_name}-ec2-ebs-volume"
      ManagedBy   = "Terraform"
      environment = var.environment
    }
  }

  user_data = <<-EOF
              #!/bin/bash
              echo "Hello, world" > index.html
              nohup busybox httpd -f -p ${local.http_port} &
              EOF

  associate_public_ip_address = true

  tags = {
    Name        = "${var.environment}-${var.cluster_name}-ec2-instance"
    ManagedBy   = "Terraform"
    environment = var.environment
  }
}