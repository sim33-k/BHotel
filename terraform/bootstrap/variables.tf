variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-south-1"
}

variable "project_name" {
  description = "Project name used for naming resources"
  type        = string
  default     = "bhotel"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "shared"
}