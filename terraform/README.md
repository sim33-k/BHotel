# BHotel Terraform Infrastructure

This directory contains the Infrastructure as Code (IaC) for the BHotel 3-tier application.

## Directory Structure

```
terraform/
├── provider.tf              # AWS provider configuration
├── variables.tf             # Input variable definitions
├── outputs.tf               # Output value definitions
├── main.tf                  # Root module orchestration
├── terraform.tfvars.example # Example variable values
├── .gitignore              # Git ignore rules
└── modules/                # Reusable module components
    ├── network/            # VPC, subnets, routing
    ├── security/           # Security groups
    ├── ecr/                # Container registries
    ├── rds/                # PostgreSQL database
    ├── alb/                # Application Load Balancer
    └── ecs/                # ECS cluster and services
```

## Prerequisites

1. **Terraform installed** - Version >= 1.0
2. **AWS CLI configured** - With appropriate credentials
3. **AWS Account** - With permissions to create resources

## Getting Started

### 1. Configure Variables

Copy the example variables file and update with your values:

```bash
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your actual values
```

**Important:** Never commit `terraform.tfvars` to git - it's gitignored for security.

### 2. Initialize Terraform

```bash
cd terraform
terraform init
```

This downloads the AWS provider and prepares the working directory.

### 3. Review the Plan

```bash
terraform plan
```

This shows what resources will be created without actually creating them.

### 4. Apply the Infrastructure

```bash
terraform apply
```

Type `yes` when prompted to create the resources.

## Key Files Explained

### provider.tf
- Configures AWS as the cloud provider
- Sets the region (Singapore: ap-southeast-1)
- Applies default tags to all resources

### variables.tf
- Defines all input parameters
- Sets default values where appropriate
- Marks sensitive values (like passwords)

### outputs.tf
- Defines what information to display after deployment
- Useful for getting ALB URLs, database endpoints, etc.

### main.tf
- Orchestrates all modules
- Passes variables between modules
- Root configuration file

## What We'll Build

Following the Architecture.md, this Terraform code will create:

- **Network:** VPC, 6 subnets across 2 AZs, NAT Gateway, Internet Gateway
- **Security:** 4 security groups with proper ingress/egress rules
- **Storage:** 2 ECR repositories for containers
- **Database:** RDS PostgreSQL instance
- **Load Balancer:** Application Load Balancer for frontend
- **Compute:** ECS Fargate cluster with frontend and backend services
- **Discovery:** AWS Cloud Map for service discovery

## Current Status

✅ Project structure created  
✅ Provider configuration completed  
✅ Variables defined  
⏳ Modules to be implemented step by step

## Next Steps

We'll build each module incrementally, testing as we go.
