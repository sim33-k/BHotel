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

# Future modules:
# - Security module (Security groups)
# - ECR module (Container registries)
# - RDS module (PostgreSQL database)
# - ALB module (Load balancer)
# - ECS module (Container orchestration)
