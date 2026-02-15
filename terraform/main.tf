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

  project_name          = var.project_name
  environment           = var.environment
  vpc_id                = module.network.vpc_id
  private_db_subnet_ids = module.network.private_db_subnet_ids
  db_security_group_id  = module.security.rds_security_group_id
  db_name               = var.db_name
  db_username           = var.db_username
  db_password           = var.db_password
}

# ============================================
# ALB Module - Application Load Balancer
# ============================================
module "alb" {
  source = "./modules/alb"

  project_name          = var.project_name
  environment           = var.environment
  vpc_id                = module.network.vpc_id
  public_subnet_ids     = module.network.public_subnet_ids
  alb_security_group_id = module.security.alb_security_group_id
}

# ============================================
# ECS Module - Container Orchestration
# ============================================
module "ecs" {
  source = "./modules/ecs"

  project_name            = var.project_name
  environment             = var.environment
  frontend_repository_url = module.ecr.frontend_repository_url
  backend_repository_url  = module.ecr.backend_repository_url
  db_secret_arn           = module.rds.db_secret_arn

  # Network configuration for ECS services
  vpc_id                 = module.network.vpc_id
  private_app_subnet_ids = module.network.private_app_subnet_ids

  # Security groups for ECS tasks
  frontend_security_group_id = module.security.frontend_ecs_security_group_id
  backend_security_group_id  = module.security.backend_ecs_security_group_id

  # ALB target groups
  frontend_target_group_arn = module.alb.frontend_target_group_arn
  backend_target_group_arn  = module.alb.backend_target_group_arn
}

