# Main Terraform Configuration
# This is the root module that orchestrates all other modules

# ============================================
# Network Module - VPC and Subnets
# ============================================
module "network" {
  source = "./modules/network"

  project_name       = var.project_name
  environment        = var.environment
  vpc_cidr           = var.vpc_cidr
  availability_zones = var.availability_zones
}

# ============================================
# Security Module - Security Groups
# ============================================
module "security" {
  source = "./modules/security"

  project_name = var.project_name
  environment  = var.environment
  vpc_id       = module.network.vpc_id
}

# ============================================
# ECR Module - Container Registries
# ============================================
module "ecr" {
  source = "./modules/ecr"

  project_name = var.project_name
  environment  = var.environment
}

# ============================================
# RDS Module - PostgreSQL Database
# ============================================
module "rds" {
  source = "./modules/rds"

  project_name           = var.project_name
  environment            = var.environment
  vpc_id                 = module.network.vpc_id
  private_db_subnet_ids  = module.network.private_db_subnet_ids
  db_security_group_id   = module.security.rds_security_group_id
  db_name                = var.db_name
  db_username            = var.db_username
  db_password            = var.db_password
}

# Future modules:
# - Security module (Security groups)
# - ECR module (Container registries)
# - RDS module (PostgreSQL database)
# - ALB module (Load balancer)
# - ECS module (Container orchestration)
