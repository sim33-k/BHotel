# BHotel - AWS 3-Tier Infrastructure

A production-ready, highly available 3-tier web application infrastructure on AWS, provisioned and managed using Terraform. This project demonstrates modern cloud architecture patterns with Infrastructure as Code (IaC), containerization, and AWS best practices.

## Overview

This project implements a complete cloud infrastructure for a containerized web application following the 3-tier architecture pattern:

- **Presentation Tier**: NGINX frontend containers running on Amazon ECS Fargate
- **Application Tier**: Node.js Express API backend on ECS Fargate with service discovery
- **Data Tier**: Amazon RDS PostgreSQL with multi-AZ deployment

The infrastructure is deployed across multiple Availability Zones in AWS Singapore (ap-southeast-1) to ensure high availability and fault tolerance.

## Architecture Highlights

### Key Features

- **High Availability**: Multi-AZ deployment across 2 Availability Zones
- **Security**: Private subnets for application and database tiers, security groups with least privilege
- **Scalability**: Container-based architecture with ECS Fargate for automatic scaling
- **Service Discovery**: AWS Cloud Map for dynamic backend service discovery
- **Load Balancing**: Application Load Balancer for traffic distribution
- **Infrastructure as Code**: Complete Terraform automation with modular design
- **Multi-Environment Support**: Separate configurations for dev, QA, and UAT environments

### Technology Stack

**Cloud Provider**: AWS  
**IaC Tool**: Terraform  
**Compute**: Amazon ECS Fargate  
**Container Registry**: Amazon ECR  
**Database**: Amazon RDS (PostgreSQL 15)  
**Networking**: VPC, ALB, NAT Gateway  
**Service Discovery**: AWS Cloud Map  

### Network Design

- **VPC CIDR**: 10.0.0.0/16
- **Public Subnets**: Load balancer tier (10.0.1.0/24, 10.0.2.0/24)
- **Private App Subnets**: Application tier (10.0.11.0/24, 10.0.12.0/24)
- **Private DB Subnets**: Database tier (10.0.21.0/24, 10.0.22.0/24)

## Repository Structure

```
.
├── terraform/                  # Terraform infrastructure code
│   ├── modules/               # Reusable Terraform modules
│   │   ├── network/          # VPC, subnets, and routing
│   │   ├── security/         # Security groups and rules
│   │   ├── ecr/              # Container registry
│   │   ├── alb/              # Application Load Balancer
│   │   ├── ecs/              # ECS cluster and services
│   │   └── rds/              # RDS PostgreSQL database
│   ├── bootstrap/            # Remote state backend setup
│   ├── scripts/              # Utility scripts
│   ├── main.tf               # Root module
│   ├── variables.tf          # Variable definitions
│   ├── outputs.tf            # Output values
│   └── *.tfvars              # Environment-specific variables
└── docs/                      # Project documentation
    ├── Architecture.md        # Detailed architecture documentation
    ├── ECR_PUSH_GUIDE.md     # Container image deployment guide
    ├── NGINX_ALB_ROUTING.md  # Load balancer routing configuration
    ├── TERRAFORM_ROADMAP.md  # Infrastructure development roadmap
    ├── NEXT_STEPS.md         # Implementation next steps
    └── Future_Ideas.md       # Future enhancements
```

## Quick Start

### Prerequisites

- Terraform >= 1.0
- AWS CLI configured with appropriate credentials
- AWS account with permissions to create VPC, ECS, RDS, ECR, and related resources

### Deployment

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd BHotel
   ```

2. **Initialize Terraform backend** (first-time setup)
   ```bash
   cd terraform/bootstrap
   terraform init
   terraform apply
   cd ..
   ```

3. **Configure environment variables**
   ```bash
   cd terraform
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your configuration
   ```

4. **Deploy infrastructure**
   ```bash
   # Select environment workspace
   terraform workspace select dev  # or qa, uat
   
   # Initialize and apply
   terraform init
   terraform plan
   terraform apply
   ```

### Environment Management

The infrastructure supports multiple environments using Terraform workspaces:

- **dev**: Development environment (`terraform.dev.tfvars`)
- **qa**: Quality assurance environment (`terraform.qa.tfvars`)
- **uat**: User acceptance testing environment (`terraform.uat.tfvars`)

Switch between environments using:
```bash
terraform workspace select <environment>
terraform apply -var-file=terraform.<environment>.tfvars
```

## Documentation

Comprehensive documentation is available in the [docs/](docs/) directory:

- **[Architecture Overview](docs/Architecture.md)**: Detailed 3-tier architecture design and rationale
- **[ECR Push Guide](docs/ECR_PUSH_GUIDE.md)**: Instructions for building and pushing container images
- **[NGINX & ALB Routing](docs/NGINX_ALB_ROUTING.md)**: Load balancer and reverse proxy configuration
- **[Terraform Roadmap](docs/TERRAFORM_ROADMAP.md)**: Infrastructure implementation plan and progress
- **[Next Steps](docs/NEXT_STEPS.md)**: Current development tasks and priorities

## Infrastructure Components

### Network Module
- VPC with public and private subnets across 2 AZs
- Internet Gateway for public internet access
- NAT Gateway for private subnet internet access
- Route tables and associations

### Security Module
- Security groups for ALB, ECS tasks, and RDS
- Least privilege access rules
- Port-based traffic control

### ECR Module
- Container registries for frontend and backend images
- Image lifecycle policies
- Repository scanning configuration

### ALB Module
- Internet-facing Application Load Balancer
- Target groups for ECS services
- Health check configuration
- HTTP listener rules

### ECS Module
- ECS cluster with Fargate launch type
- Frontend and backend service definitions
- Task definitions with container configurations
- AWS Cloud Map service discovery
- Auto-scaling policies

### RDS Module
- PostgreSQL 15 database
- Multi-AZ deployment for high availability
- Automated backups and snapshots
- DB subnet group configuration
- Parameter and option groups

## Security Considerations

- All application and database resources deployed in private subnets
- Security groups implement defense in depth with minimal required ports
- Database credentials managed through AWS Secrets Manager (future roadmap)
- RDS encryption at rest and in transit
- VPC flow logs for network monitoring (configurable)

## Cost Optimization

- Fargate Spot for non-production workloads (configurable)
- Single NAT Gateway per environment (can be upgraded to HA)
- RDS instance sizing based on environment (dev uses smaller instances)
- Lifecycle policies for ECR to remove old images

## Contributing

This is a portfolio project demonstrating cloud infrastructure expertise. For questions or suggestions, please open an issue.

## License

This project is for educational and portfolio purposes.

---

**Author**: Simaak  
**Last Updated**: March 2026
