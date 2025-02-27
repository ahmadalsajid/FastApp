resource "aws_vpc" "this" {
  cidr_block = var.vpc_cidr_block

  enable_dns_hostnames = true

  tags = {
    Name        = "${var.environment}-${var.cluster_name}-vpc"
    ManagedBy   = "Terraform"
    environment = var.environment
  }
}

resource "aws_subnet" "private" {
  count = length(var.private_subnets)

  vpc_id            = aws_vpc.this.id
  cidr_block        = var.private_subnets[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name        = "${var.environment}-${var.cluster_name}-private-subnet-${var.availability_zones[count.index]}"
    ManagedBy   = "Terraform"
    environment = var.environment
  }
}

resource "aws_subnet" "public" {
  count = length(var.public_subnets)

  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.public_subnets[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name        = "${var.environment}-${var.cluster_name}-public-subnet-${var.availability_zones[count.index]}"
    ManagedBy   = "Terraform"
    environment = var.environment
  }
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name        = "${var.environment}-${var.cluster_name}-igw"
    ManagedBy   = "Terraform"
    environment = var.environment
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = var.all_ips
    gateway_id = aws_internet_gateway.this.id
  }

  tags = {
    Name        = "${var.environment}-${var.cluster_name}-public-rt"
    ManagedBy   = "Terraform"
    environment = var.environment
  }
}

resource "aws_route_table_association" "public" {
  count = length(var.public_subnets)

  route_table_id = aws_route_table.public.id
  subnet_id      = aws_subnet.public[count.index].id
}