# ECS Module - Cluster and Task Definitions
# Creates the ECS cluster and defines how to run frontend and backend containers

# ============================================
# ECS Cluster
# ============================================
resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-${var.environment}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-ecs-cluster"
    Environment = var.environment
    Project     = var.project_name
  }
}

# ============================================
# IAM Roles for ECS Tasks
# ============================================

# Task Execution Role - Used by ECS to pull images and manage tasks
# This role is assumed by ECS agent itself
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "${var.project_name}-${var.environment}-ecs-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-${var.environment}-ecs-task-execution-role"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Attach AWS managed policy for ECS task execution
resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Additional policy to allow reading secrets from Secrets Manager
resource "aws_iam_role_policy" "ecs_task_execution_secrets_policy" {
  name = "${var.project_name}-${var.environment}-ecs-secrets-policy"
  role = aws_iam_role.ecs_task_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = [
          var.db_secret_arn
        ]
      }
    ]
  })
}

# Task Role - Used by the container application itself (if it needs AWS permissions)
# For now, this is a basic role. We can add policies later if the app needs AWS access
resource "aws_iam_role" "ecs_task_role" {
  name = "${var.project_name}-${var.environment}-ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-${var.environment}-ecs-task-role"
    Environment = var.environment
    Project     = var.project_name
  }
}

# ============================================
# CloudWatch Log Groups for Container Logs
# ============================================
resource "aws_cloudwatch_log_group" "frontend" {
  name              = "/ecs/${var.project_name}-${var.environment}/frontend"
  retention_in_days = 7

  tags = {
    Name        = "${var.project_name}-${var.environment}-frontend-logs"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_cloudwatch_log_group" "backend" {
  name              = "/ecs/${var.project_name}-${var.environment}/backend"
  retention_in_days = 7

  tags = {
    Name        = "${var.project_name}-${var.environment}-backend-logs"
    Environment = var.environment
    Project     = var.project_name
  }
}

# ============================================
# Frontend Task Definition
# ============================================
resource "aws_ecs_task_definition" "frontend" {
  family                   = "${var.project_name}-${var.environment}-frontend"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.frontend_cpu
  memory                   = var.frontend_memory
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name      = "frontend"
      image     = "${var.frontend_repository_url}:latest"
      essential = true

      portMappings = [
        {
          containerPort = var.frontend_port
          protocol      = "tcp"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.frontend.name
          "awslogs-region"        = data.aws_region.current.name
          "awslogs-stream-prefix" = "ecs"
        }
      }

      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost/ || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      }
    }
  ])

  tags = {
    Name        = "${var.project_name}-${var.environment}-frontend-task"
    Environment = var.environment
    Project     = var.project_name
  }
}

# ============================================
# Backend Task Definition
# ============================================
resource "aws_ecs_task_definition" "backend" {
  family                   = "${var.project_name}-${var.environment}-backend"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.backend_cpu
  memory                   = var.backend_memory
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name      = "backend"
      image     = "${var.backend_repository_url}:latest"
      essential = true

      portMappings = [
        {
          containerPort = var.backend_port
          protocol      = "tcp"
        }
      ]

      # Environment variables
      environment = [
        {
          name  = "NODE_ENV"
          value = var.environment
        },
        {
          name  = "PORT"
          value = tostring(var.backend_port)
        }
      ]

      # Secrets from AWS Secrets Manager
      # The DATABASE_URL will be injected from Secrets Manager
      secrets = [
        {
          name      = "DATABASE_URL"
          valueFrom = "${var.db_secret_arn}:url::"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.backend.name
          "awslogs-region"        = data.aws_region.current.name
          "awslogs-stream-prefix" = "ecs"
        }
      }

      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost:${var.backend_port}/health || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      }
    }
  ])

  tags = {
    Name        = "${var.project_name}-${var.environment}-backend-task"
    Environment = var.environment
    Project     = var.project_name
  }
}

# ============================================
# Data Sources
# ============================================
data "aws_region" "current" {}
