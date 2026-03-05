# terraform.tfvars is gitignored for security

# Project Configuration
project_name = "bhotel"
environment  = "dev"
aws_region   = "ap-southeast-1"

# Network Configuration
vpc_cidr           = "10.0.0.0/16"
availability_zones = ["ap-southeast-1a", "ap-southeast-1b"]

# Database Configuration
db_username = "postgres"
db_password = "Simaak#2002"
db_name     = "bhotel"

# ECS Task Configuration
frontend_cpu    = 256
frontend_memory = 512
backend_cpu     = 512
backend_memory  = 1024
desired_count   = 2 
