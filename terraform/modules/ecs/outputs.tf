# ECS Module Outputs
# Information about the ECS cluster and task definitions

output "cluster_id" {
  description = "ID of the ECS cluster"
  value       = aws_ecs_cluster.main.id
}

output "cluster_name" {
  description = "Name of the ECS cluster"
  value       = aws_ecs_cluster.main.name
}

output "cluster_arn" {
  description = "ARN of the ECS cluster"
  value       = aws_ecs_cluster.main.arn
}

output "frontend_task_definition_arn" {
  description = "ARN of the frontend task definition"
  value       = aws_ecs_task_definition.frontend.arn
}

output "frontend_task_definition_family" {
  description = "Family of the frontend task definition"
  value       = aws_ecs_task_definition.frontend.family
}

output "backend_task_definition_arn" {
  description = "ARN of the backend task definition"
  value       = aws_ecs_task_definition.backend.arn
}

output "backend_task_definition_family" {
  description = "Family of the backend task definition"
  value       = aws_ecs_task_definition.backend.family
}

output "ecs_task_execution_role_arn" {
  description = "ARN of the ECS task execution role"
  value       = aws_iam_role.ecs_task_execution_role.arn
}

output "ecs_task_role_arn" {
  description = "ARN of the ECS task role"
  value       = aws_iam_role.ecs_task_role.arn
}

output "frontend_log_group_name" {
  description = "Name of the CloudWatch log group for frontend"
  value       = aws_cloudwatch_log_group.frontend.name
}

output "backend_log_group_name" {
  description = "Name of the CloudWatch log group for backend"
  value       = aws_cloudwatch_log_group.backend.name
}
