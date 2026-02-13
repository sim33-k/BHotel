# RDS Module - PostgreSQL Database
# Creates managed PostgreSQL database in private subnets

# ============================================
# DB Subnet Group
# ============================================
# Groups private DB subnets for RDS deployment

resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-${var.environment}-db-subnet-group"
  subnet_ids = var.private_db_subnet_ids

  tags = {
    Name = "${var.project_name}-${var.environment}-db-subnet-group"
  }
}

# ============================================
# RDS PostgreSQL Instance
# ============================================
resource "aws_db_instance" "postgres" {
  identifier = "${var.project_name}-${var.environment}-db"

  # Engine configuration
  engine               = "postgres"
  engine_version       = "15"  
  instance_class       = "db.t3.micro"
  allocated_storage    = 20
  storage_type         = "gp3"
  storage_encrypted    = true

  # Database configuration
  db_name  = var.db_name
  username = var.db_username
  password = var.db_password
  port     = 5432

  # Network configuration
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [var.db_security_group_id]
  publicly_accessible    = false  # Private only

  # Backup configuration - Disabled for cost/free tier
  backup_retention_period = 0  # No automated backups
  skip_final_snapshot     = true

  # Performance and monitoring
  enabled_cloudwatch_logs_exports = ["postgresql"]

  # High availability (disabled for cost optimization)
  multi_az = false  # Enable for production

  # Upgrade and maintenance
  auto_minor_version_upgrade = true
  apply_immediately         = false  # Apply changes during maintenance window

  # Deletion protection
  deletion_protection = false  # Set to true for production

  tags = {
    Name = "${var.project_name}-${var.environment}-postgres"
  }
}

# ============================================
# Secrets Manager - Database Connection String
# ============================================
# Stores DATABASE_URL for ECS to inject into backend containers

resource "aws_secretsmanager_secret" "db_url" {
  name        = "${var.project_name}-${var.environment}-database-url"
  description = "PostgreSQL connection string for ${var.project_name} ${var.environment}"

  tags = {
    Name = "${var.project_name}-${var.environment}-database-url"
  }
}

resource "aws_secretsmanager_secret_version" "db_url" {
  secret_id = aws_secretsmanager_secret.db_url.id
  secret_string = jsonencode({
    url      = "postgresql://${var.db_username}:${var.db_password}@${aws_db_instance.postgres.endpoint}/${var.db_name}"
    host     = aws_db_instance.postgres.address
    port     = aws_db_instance.postgres.port
    database = var.db_name
    username = var.db_username
    password = var.db_password
  })
}
