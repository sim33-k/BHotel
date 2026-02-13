# Output Values
# These values will be displayed after terraform apply

# ============================================
# Network Outputs
# ============================================
output "vpc_id" {
  description = "ID of the VPC"
  value       = module.network.vpc_id
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = module.network.public_subnet_ids
}

output "private_app_subnet_ids" {
  description = "List of private app subnet IDs"
  value       = module.network.private_app_subnet_ids
}

output "private_db_subnet_ids" {
  description = "List of private database subnet IDs"
  value       = module.network.private_db_subnet_ids
}

output "nat_gateway_public_ip" {
  description = "Public IP address of the NAT Gateway"
  value       = module.network.nat_gateway_public_ip
}

# ============================================
# Security Group Outputs
# ============================================
output "alb_security_group_id" {
  description = "ID of the ALB security group"
  value       = module.security.alb_security_group_id
}

output "frontend_ecs_security_group_id" {
  description = "ID of the frontend ECS security group"
  value       = module.security.frontend_ecs_security_group_id
}

output "backend_ecs_security_group_id" {
  description = "ID of the backend ECS security group"
  value       = module.security.backend_ecs_security_group_id
}

output "rds_security_group_id" {
  description = "ID of the RDS security group"
  value       = module.security.rds_security_group_id
}

# ============================================
# ECR Outputs
# ============================================
output "frontend_repository_url" {
  description = "URL of the frontend ECR repository"
  value       = module.ecr.frontend_repository_url
}

output "backend_repository_url" {
  description = "URL of the backend ECR repository"
  value       = module.ecr.backend_repository_url
}

# ============================================
# RDS Outputs
# ============================================
output "db_endpoint" {
  description = "RDS PostgreSQL connection endpoint"
  value       = module.rds.db_endpoint
}

output "db_address" {
  description = "RDS PostgreSQL hostname"
  value       = module.rds.db_address
}

output "db_secret_arn" {
  description = "ARN of Secrets Manager secret containing database credentials"
  value       = module.rds.db_secret_arn
}
