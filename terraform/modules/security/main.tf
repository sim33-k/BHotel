# Security Module - Security Groups
# Creates firewall rules for each tier of the application

# ============================================
# ALB Security Group
# ============================================
# Allows HTTP/HTTPS traffic from the internet

resource "aws_security_group" "alb" {
  name        = "${var.project_name}-${var.environment}-alb-sg"
  description = "Security group for Application Load Balancer"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.project_name}-${var.environment}-alb-sg"
  }
}

# Inbound: Allow HTTP from anywhere
resource "aws_security_group_rule" "alb_http_inbound" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]  # Internet
  security_group_id = aws_security_group.alb.id
  description       = "Allow HTTP from internet"
}

# Inbound: Allow HTTPS from anywhere
resource "aws_security_group_rule" "alb_https_inbound" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]  # Internet
  security_group_id = aws_security_group.alb.id
  description       = "Allow HTTPS from internet"
}

# Outbound: Allow traffic to frontend containers
resource "aws_security_group_rule" "alb_to_frontend" {
  type                     = "egress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.frontend_ecs.id
  security_group_id        = aws_security_group.alb.id
  description              = "Allow traffic to frontend ECS tasks"
}

# ============================================
# Frontend ECS Security Group
# ============================================
# Allows traffic from ALB only

resource "aws_security_group" "frontend_ecs" {
  name        = "${var.project_name}-${var.environment}-frontend-ecs-sg"
  description = "Security group for frontend ECS tasks"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.project_name}-${var.environment}-frontend-ecs-sg"
  }
}

# Inbound: Allow port 80 from ALB
resource "aws_security_group_rule" "frontend_from_alb" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb.id
  security_group_id        = aws_security_group.frontend_ecs.id
  description              = "Allow HTTP from ALB"
}

# Outbound: Allow port 3000 to backend
resource "aws_security_group_rule" "frontend_to_backend" {
  type                     = "egress"
  from_port                = 3000
  to_port                  = 3000
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.backend_ecs.id
  security_group_id        = aws_security_group.frontend_ecs.id
  description              = "Allow traffic to backend ECS tasks"
}

# Outbound: Allow HTTPS for ECR image pulls
resource "aws_security_group_rule" "frontend_to_internet" {
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.frontend_ecs.id
  description       = "Allow HTTPS for ECR pulls"
}

# ============================================
# Backend ECS Security Group
# ============================================
# Allows traffic from frontend only

resource "aws_security_group" "backend_ecs" {
  name        = "${var.project_name}-${var.environment}-backend-ecs-sg"
  description = "Security group for backend ECS tasks"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.project_name}-${var.environment}-backend-ecs-sg"
  }
}

# Inbound: Allow port 3000 from frontend
resource "aws_security_group_rule" "backend_from_frontend" {
  type                     = "ingress"
  from_port                = 3000
  to_port                  = 3000
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.frontend_ecs.id
  security_group_id        = aws_security_group.backend_ecs.id
  description              = "Allow traffic from frontend ECS tasks"
}

# Outbound: Allow port 5432 to RDS (PostgreSQL)
resource "aws_security_group_rule" "backend_to_rds" {
  type                     = "egress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.rds.id
  security_group_id        = aws_security_group.backend_ecs.id
  description              = "Allow PostgreSQL traffic to RDS"
}

# Outbound: Allow HTTPS for ECR pulls and external APIs
resource "aws_security_group_rule" "backend_to_internet" {
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.backend_ecs.id
  description       = "Allow HTTPS for ECR pulls and external APIs"
}

# ============================================
# RDS Security Group
# ============================================
# Allows PostgreSQL traffic from backend only

resource "aws_security_group" "rds" {
  name        = "${var.project_name}-${var.environment}-rds-sg"
  description = "Security group for RDS PostgreSQL"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.project_name}-${var.environment}-rds-sg"
  }
}

# Inbound: Allow port 5432 from backend
resource "aws_security_group_rule" "rds_from_backend" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.backend_ecs.id
  security_group_id        = aws_security_group.rds.id
  description              = "Allow PostgreSQL from backend ECS tasks"
}

# No outbound rules needed for RDS - it only receives connections
