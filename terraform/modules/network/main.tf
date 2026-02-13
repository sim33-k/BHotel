# Network Module - VPC and Subnets
# Creates the foundational network infrastructure

# ============================================
# VPC - Virtual Private Cloud
# ============================================
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true  # Required for ECS and service discovery
  enable_dns_support   = true  # Required for DNS resolution

  tags = {
    Name = "${var.project_name}-${var.environment}-vpc"
  }
}

# ============================================
# Public Subnets - For ALB and Frontend
# ============================================
# These subnets have internet access via Internet Gateway

resource "aws_subnet" "public" {
  count = length(var.availability_zones)

  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index + 1)  # 10.0.1.0/24, 10.0.2.0/24
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true  # Instances get public IPs automatically

  tags = {
    Name = "${var.project_name}-${var.environment}-public-${var.availability_zones[count.index]}"
    Type = "Public"
  }
}

# ============================================
# Private App Subnets - For Backend ECS Tasks
# ============================================
# These subnets access internet via NAT Gateway

resource "aws_subnet" "private_app" {
  count = length(var.availability_zones)

  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + 11)  # 10.0.11.0/24, 10.0.12.0/24
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name = "${var.project_name}-${var.environment}-app-${var.availability_zones[count.index]}"
    Type = "Private-App"
  }
}

# ============================================
# Private DB Subnets - For RDS Database
# ============================================
# These subnets are isolated, only backend can access

resource "aws_subnet" "private_db" {
  count = length(var.availability_zones)

  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + 21)  # 10.0.21.0/24, 10.0.22.0/24
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name = "${var.project_name}-${var.environment}-db-${var.availability_zones[count.index]}"
    Type = "Private-DB"
  }
}
