# BHotel - Next Steps After Terraform Deployment

## ✅ Completed
- [x] VPC and Network Infrastructure
- [x] Security Groups
- [x] ECR Repositories
- [x] RDS PostgreSQL Database
- [x] Application Load Balancer
- [x] ECS Cluster and Service Definitions

---

## 🚨 Critical - Must Complete Before Application Works

### 1. Create IAM Roles for ECS Tasks
**Why:** ECS tasks need permissions to pull images from ECR, write logs, and access secrets.

**Files to create:**
```
terraform/modules/iam/
├── main.tf
├── variables.tf
└── outputs.tf
```

**What to add:**
- ECS Task Execution Role (for pulling ECR images, CloudWatch logs)
- ECS Task Role (for application runtime permissions)
- Policies for ECR, CloudWatch Logs, Secrets Manager

**Resources needed:**
- `aws_iam_role.ecs_task_execution_role`
- `aws_iam_role.ecs_task_role`
- `aws_iam_role_policy_attachment` for required policies

---

### 2. Setup CloudWatch Log Groups
**Why:** Capture container logs for debugging and monitoring.

**Add to ECS module:**
- Log group for frontend: `/ecs/bhotel-dev/frontend`
- Log group for backend: `/ecs/bhotel-dev/backend`
- Configure log retention (7, 14, or 30 days)

**Update task definitions to use CloudWatch logs.**

---

### 3. Store Database Credentials in Secrets Manager
**Why:** Securely manage database password and provide to backend containers.

**Current issue:** RDS password is in terraform.tfvars (not secure for production)

**Add to RDS or separate secrets module:**
```hcl
resource "aws_secretsmanager_secret" "db_credentials" {
  name = "${var.environment}-db-credentials"
}

resource "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = aws_secretsmanager_secret.db_credentials.id
  secret_string = jsonencode({
    username = var.db_username
    password = var.db_password
    engine   = "postgres"
    host     = aws_db_instance.main.address
    port     = 5432
    dbname   = var.db_name
  })
}
```

**Update backend task definition to inject secrets as environment variables.**

---

### 4. Build Application Docker Images
**Why:** ECR repositories are empty - no containers to deploy.

**Required:**
1. Create Dockerfile for frontend
2. Create Dockerfile for backend
3. Build and push images to ECR (see ECR_PUSH_GUIDE.md)

**Frontend needs:**
- nginx configuration to proxy `/api` requests to `backend.bhotel-dev.local:3000`
- Built static assets

**Backend needs:**
- Database connection using DATABASE_URL from Secrets Manager
- Health check endpoint (e.g., `/health`)

---

### 5. Update ECS Task Definitions
**Why:** Need to reference actual container images and configure properly.

**Current state:** Task definitions likely use placeholder images or are incomplete.

**Update needed in `modules/ecs/main.tf`:**
- Set correct ECR image URIs
- Add CloudWatch log configuration
- Add IAM execution role ARN
- Add task role ARN
- Add secrets from Secrets Manager
- Configure health checks

---

### 6. Initialize Database Schema
**Why:** Empty database - need tables and initial data.

**Options:**
1. **Manual:** Connect via bastion host and run SQL migrations
2. **Automated:** Use ECS task to run migrations on startup
3. **Application:** Backend runs migrations automatically on boot

**Recommend:** Create database initialization script in backend

---

## 🔐 Important - Security & Observability

### 7. Add SSL/TLS Certificate
**Why:** Currently HTTP only - insecure for production.

**Steps:**
1. Register domain name (Route 53 or external registrar)
2. Request ACM certificate for your domain
3. Add HTTPS listener (443) to ALB
4. Redirect HTTP to HTTPS

**Add to ALB module:**
```hcl
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.main.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend.arn
  }
}

# Redirect HTTP to HTTPS
resource "aws_lb_listener" "http_redirect" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}
```

---

### 8. CloudWatch Alarms & Monitoring
**Why:** Get notified of issues before users complain.

**Create alarms for:**
- ALB unhealthy target count > 0
- ECS service CPU > 80%
- ECS service memory > 80%
- RDS CPU > 80%
- RDS free storage < 2GB
- ALB 5xx errors > 10/5min

**Add SNS topic for notifications:**
```hcl
resource "aws_sns_topic" "alerts" {
  name = "${var.environment}-alerts"
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}
```

---

### 9. Enable ECS Service Auto Scaling
**Why:** Handle traffic spikes automatically.

**Add to ECS module:**
- Target tracking scaling policy (CPU/Memory)
- Min tasks: 2
- Max tasks: 4 (or higher based on needs)

---

### 10. Backup & Disaster Recovery
**Why:** RDS has automated backups, but need recovery plan.

**Add:**
- Enable automated RDS backups (already configured)
- Create manual snapshot before major changes
- Document restore procedure
- Consider cross-region backup for critical data

---

## 📦 Nice to Have - Future Enhancements

### 11. CI/CD Pipeline
**Tools:** GitHub Actions, AWS CodePipeline, Jenkins

**Workflow:**
1. Push code to GitHub
2. Run tests
3. Build Docker images
4. Push to ECR
5. Update ECS service (trigger deployment)

---

### 12. Bastion Host or Session Manager
**Why:** Need secure way to access RDS for debugging/migrations.

**Options:**
1. EC2 bastion host in public subnet
2. AWS Systems Manager Session Manager (no bastion needed)
3. Cloud9 environment in VPC

---

### 13. WAF (Web Application Firewall)
**Why:** Protect against common web exploits.

**Add to ALB:**
- Rate limiting
- SQL injection protection
- XSS protection
- Geographic restrictions if needed

---

### 14. CloudFront CDN
**Why:** Faster content delivery, DDoS protection.

**Benefits:**
- Cache static assets closer to users
- Reduce load on ALB/ECS
- Better global performance

---

### 15. ElastiCache (Redis/Memcached)
**Why:** Reduce database load, improve performance.

**Use cases:**
- Session storage
- API response caching
- Rate limiting
- Real-time features

---

## 🎯 Recommended Implementation Order

### Week 1: Get Application Running
1. ✅ Create IAM roles module
2. ✅ Add CloudWatch log groups
3. ✅ Setup Secrets Manager for DB credentials
4. ✅ Build Docker images
5. ✅ Update task definitions with real images
6. ✅ Initialize database
7. ✅ Deploy and test

### Week 2: Security & Monitoring
8. Add SSL certificate and HTTPS
9. Setup CloudWatch alarms
10. Enable auto scaling
11. Test failover scenarios

### Week 3: Automation
12. Setup CI/CD pipeline
13. Automated testing
14. Documentation

### Future Sprints
15. WAF implementation
16. CloudFront CDN
17. ElastiCache
18. Additional optimizations

---

## 📝 Quick Start Commands

### Check Current Infrastructure
```bash
cd terraform
terraform output
```

### Verify RDS is accessible (from within VPC)
You'll need a bastion host or ECS exec to test this.

### Check ECS Services Status
```bash
aws ecs describe-services \
  --cluster bhotel-dev-cluster \
  --services bhotel-dev-frontend bhotel-dev-backend \
  --region ap-southeast-1
```

### View CloudWatch Logs (after setting up log groups)
```bash
aws logs tail /ecs/bhotel-dev/backend --follow --region ap-southeast-1
aws logs tail /ecs/bhotel-dev/frontend --follow --region ap-southeast-1
```

---

## ❓ Questions to Ask Yourself

1. **Do I have application code ready?** If not, build sample apps first.
2. **Do I have a domain name?** Required for SSL/production use.
3. **What's my monitoring strategy?** How will I know if something breaks?
4. **How will I deploy updates?** Manual or automated CI/CD?
5. **What's my backup/restore plan?** Test it before you need it.
6. **Who needs access to logs/metrics?** Setup IAM accordingly.

---

## 🔗 Related Documentation

- [ECR_PUSH_GUIDE.md](./ECR_PUSH_GUIDE.md) - How to push Docker images
- [TERRAFORM_ROADMAP.md](./TERRAFORM_ROADMAP.md) - Original implementation plan
- [Architecture.md](./Architecture.md) - System architecture details
- [Future_Ideas.md](./Future_Ideas.md) - Scaling and enhancement ideas

---

## Need Help?

**Common Issues:**
- **Task won't start:** Check IAM roles, security groups, ECR image exists
- **Can't access ALB:** Check security groups, target health
- **Container crashes:** Check CloudWatch logs, environment variables
- **Database connection fails:** Check security groups, credentials, RDS endpoint

**Next Step:** Start with creating the IAM module and CloudWatch log groups!
