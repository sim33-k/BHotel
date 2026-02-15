# ECS Module Variables
# Inputs required for the ECS cluster and task definitions

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
}

variable "frontend_repository_url" {
  description = "URL of the frontend ECR repository"
  type        = string
}

variable "backend_repository_url" {
  description = "URL of the backend ECR repository"
  type        = string
}

variable "db_secret_arn" {
  description = "ARN of the Secrets Manager secret containing database credentials"
  type        = string
}

variable "frontend_cpu" {
  description = "CPU units for frontend task (1024 = 1 vCPU)"
  type        = number
  default     = 256
}

variable "frontend_memory" {
  description = "Memory for frontend task in MB"
  type        = number
  default     = 512
}

variable "backend_cpu" {
  description = "CPU units for backend task (1024 = 1 vCPU)"
  type        = number
  default     = 512
}

variable "backend_memory" {
  description = "Memory for backend task in MB"
  type        = number
  default     = 1024
}

variable "frontend_port" {
  description = "Port that frontend container listens on"
  type        = number
  default     = 80
}

variable "backend_port" {
  description = "Port that backend container listens on"
  type        = number
  default     = 3000
}

# ============================================
# ECS Service Variables
# ============================================

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "private_app_subnet_ids" {
  description = "List of private app subnet IDs for ECS tasks"
  type        = list(string)
}

variable "frontend_security_group_id" {
  description = "Security group ID for frontend ECS tasks"
  type        = string
}

variable "backend_security_group_id" {
  description = "Security group ID for backend ECS tasks"
  type        = string
}

variable "frontend_target_group_arn" {
  description = "ARN of the frontend target group"
  type        = string
}

variable "backend_target_group_arn" {
  description = "ARN of the backend target group"
  type        = string
}

variable "frontend_desired_count" {
  description = "Desired number of frontend tasks"
  type        = number
  default     = 1
}

variable "backend_desired_count" {
  description = "Desired number of backend tasks"
  type        = number
  default     = 1
}
