# Network Module - VPC and Subnets
# Creates the foundational network infrastructure

# ============================================
# VPC - Virtual Private Cloud
# ============================================
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true # Required for ECS and service discovery
  enable_dns_support   = true # Required for DNS resolution

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
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index + 1) # 10.0.1.0/24, 10.0.2.0/24
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true # Instances get public IPs automatically

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
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + 11) # 10.0.11.0/24, 10.0.12.0/24
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
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + 21) # 10.0.21.0/24, 10.0.22.0/24
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name = "${var.project_name}-${var.environment}-db-${var.availability_zones[count.index]}"
    Type = "Private-DB"
  }
}

# ============================================
# Internet Gateway - For Public Subnets
# ============================================
# Allows resources in public subnets to access the internet

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-${var.environment}-igw"
  }
}

# ============================================
# Elastic IP for NAT Gateway
# ============================================
# NAT Gateway needs a static public IP

resource "aws_eip" "nat" {
  domain = "vpc" # Previously called 'vpc = true'

  tags = {
    Name = "${var.project_name}-${var.environment}-nat-eip"
  }

  # NAT Gateway must exist before EIP can be destroyed
  depends_on = [aws_internet_gateway.main]
}

# ============================================
# NAT Gateway - For Private Subnets
# ============================================
# Allows resources in private subnets to access internet (outbound only)
# Deployed in first public subnet only (cost optimization)

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id # Deploy in first public subnet

  tags = {
    Name = "${var.project_name}-${var.environment}-nat"
  }

  # Internet Gateway must exist before NAT Gateway
  depends_on = [aws_internet_gateway.main]
}

# ============================================
# Route Table - Public Subnets
# ============================================
# Routes traffic from public subnets to Internet Gateway

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0" # All internet traffic
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-public-rt"
  }
}

# Associate public subnets with public route table
resource "aws_route_table_association" "public" {
  count = length(var.availability_zones)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# ============================================
# Route Table - Private Subnets
# ============================================
# Routes traffic from private subnets to NAT Gateway

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0" # All internet traffic
    nat_gateway_id = aws_nat_gateway.main.id
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-private-rt"
  }
}

# Associate private app subnets with private route table
resource "aws_route_table_association" "private_app" {
  count = length(var.availability_zones)

  subnet_id      = aws_subnet.private_app[count.index].id
  route_table_id = aws_route_table.private.id
}

# Associate private db subnets with private route table
resource "aws_route_table_association" "private_db" {
  count = length(var.availability_zones)

  subnet_id      = aws_subnet.private_db[count.index].id
  route_table_id = aws_route_table.private.id
}
