# ALB Module - Application Load Balancer
# Creates the internet-facing load balancer and target groups

# ============================================
# Application Load Balancer
# ============================================
resource "aws_lb" "main" {
  name               = "${var.project_name}-${var.environment}-alb"
  internal           = false # Internet-facing
  load_balancer_type = "application"
  security_groups    = [var.alb_security_group_id]
  subnets            = var.public_subnet_ids

  enable_deletion_protection       = false # Set to true for production
  enable_http2                     = true
  enable_cross_zone_load_balancing = true

  tags = {
    Name        = "${var.project_name}-${var.environment}-alb"
    Environment = var.environment
    Project     = var.project_name
  }
}

# ============================================
# Target Groups
# ============================================

# Frontend Target Group
resource "aws_lb_target_group" "frontend" {
  name        = "${var.project_name}-${var.environment}-frontend-tg"
  port        = var.frontend_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip" # For Fargate tasks

  health_check {
    enabled             = true
    healthy_threshold   = var.health_check_healthy_threshold
    unhealthy_threshold = var.health_check_unhealthy_threshold
    timeout             = var.health_check_timeout
    interval            = var.health_check_interval
    path                = var.health_check_path
    protocol            = "HTTP"
    matcher             = "200-299"
  }

  deregistration_delay = 30 # Time to wait before deregistering targets

  tags = {
    Name        = "${var.project_name}-${var.environment}-frontend-tg"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Backend Target Group
resource "aws_lb_target_group" "backend" {
  name        = "${var.project_name}-${var.environment}-backend-tg"
  port        = var.backend_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip" # For Fargate tasks

  health_check {
    enabled             = true
    healthy_threshold   = var.health_check_healthy_threshold
    unhealthy_threshold = var.health_check_unhealthy_threshold
    timeout             = var.health_check_timeout
    interval            = var.health_check_interval
    path                = "/health" # Backend health endpoint
    protocol            = "HTTP"
    matcher             = "200-299"
  }

  deregistration_delay = 30

  tags = {
    Name        = "${var.project_name}-${var.environment}-backend-tg"
    Environment = var.environment
    Project     = var.project_name
  }
}

# ============================================
# Listeners and Routing Rules
# ============================================

# HTTP Listener (Port 80)
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  # Default action - forward to frontend
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend.arn
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-http-listener"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Listener Rule - Route /api/* to backend
resource "aws_lb_listener_rule" "backend_api" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend.arn
  }

  condition {
    path_pattern {
      values = ["/api/*"]
    }
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-backend-rule"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Optional: Listener Rule - Route /health to backend health endpoint
resource "aws_lb_listener_rule" "backend_health" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 99

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend.arn
  }

  condition {
    path_pattern {
      values = ["/health"]
    }
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-health-rule"
    Environment = var.environment
    Project     = var.project_name
  }
}
