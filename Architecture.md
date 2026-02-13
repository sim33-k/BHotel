# BHotel - 3-Tier Application Architecture

## Architecture Overview
This document outlines the architectural requirements for a 3-tier containerized application deployed on AWS.

**Application Stack:**
- **Frontend:** Containerized web application using nginx (port 80), stored in Amazon ECR
- **Backend:** Node.js Express API (port 3000), containerized and stored in Amazon ECR
- **Database:** Amazon RDS PostgreSQL/MySQL

## Region Selection
**Primary Region:** `ap-southeast-1` (Singapore)

**Rationale:**
- Low latency for Southeast Asian users
- Full AWS service availability
- Strong infrastructure and connectivity

---

## Network Architecture

#### VPC Configuration
- **VPC CIDR:** `10.0.0.0/16`
  - Total available IPs: 65,536
  - Allows for future growth and segmentation

#### Availability Zones
- **Primary AZ:** `ap-southeast-1a`
- **Secondary AZ:** `ap-southeast-1b`
- **Rationale:** 2 AZs provide high availability without over-engineering

#### Subnet Design

##### Public Subnets (Presentation Tier)
| Subnet Name | CIDR | AZ | Purpose | Available IPs |
|-------------|------|----|---------|--------------
| public-subnet-1a | 10.0.1.0/24 | ap-southeast-1a | Web/Load Balancer | 251 |
| public-subnet-1b | 10.0.2.0/24 | ap-southeast-1b | Web/Load Balancer | 251 |

##### Private Subnets - Application Tier
| Subnet Name | CIDR | AZ | Purpose | Available IPs |
|-------------|------|----|---------|--------------
| app-subnet-1a | 10.0.11.0/24 | ap-southeast-1a | Application Servers | 251 |
| app-subnet-1b | 10.0.12.0/24 | ap-southeast-1b | Application Servers | 251 |

##### Private Subnets - Data Tier
| Subnet Name | CIDR | AZ | Purpose | Available IPs |
|-------------|------|----|---------|--------------
| db-subnet-1a | 10.0.21.0/24 | ap-southeast-1a | Database Instances | 251 |
| db-subnet-1b | 10.0.22.0/24 | ap-southeast-1b | Database Instances | 251 |

### 2. Three-Tier Architecture Components

#### Tier 1: Presentation Layer (Public Subnets)
- **Load Balancer:** Application Load Balancer (ALB)
  - Type: Application Load Balancer
  - Scheme: **Internet-facing** (public access only)
  - Cross-zone load balancing: Enabled
  - Listener: Port 80 (HTTP)
  - Target: Frontend ECS Service
  - **Note:** Only ONE ALB needed for internet traffic
  
- **Frontend Containers (ECS Fargate):**
  - **Container Image:** Stored in Amazon ECR
  - **Web Server:** nginx serving on port 80
  - **ECS Service:**
    - Desired count: 2 tasks (1 per AZ)
    - Task CPU: 256 (.25 vCPU)
    - Task Memory: 512 MB
    - Launch Type: Fargate
  - **Purpose:** Serve frontend application, proxy requests to backend API

#### Tier 2: Application Layer (Private App Subnets)
- **Backend Containers (ECS Fargate):**
  - **Container Image:** Node.js Express app stored in Amazon ECR
  - **Application Port:** 3000
  - **ECS Service:**
    - Desired count: 2 tasks (1 per AZ)
    - Task CPU: 512 (.5 vCPU)
    - Task Memory: 1024 MB (1 GB)
    - Launch Type: Fargate
  - **Service Discovery:** AWS Cloud Map
    - **Private DNS Namespace:** `bhotel.local`
    - **Service DNS Name:** `backend.bhotel.local`
    - **How it works:**
      1. When backend tasks start, they auto-register their IPs with Cloud Map
      2. Cloud Map creates/updates DNS A records pointing to healthy task IPs
      3. Frontend simply calls `http://backend.bhotel.local:3000/api/...`
      4. DNS automatically resolves to current backend task IPs (round-robin)
      5. If tasks restart/change IPs, Cloud Map auto-updates DNS records
    - **Health Checks:** Only healthy backend tasks are included in DNS responses
    - **TTL:** 10 seconds (fast failover if tasks become unhealthy)
  - **Purpose:** Business logic, REST API endpoints, database communication
  - **Note:** No second ALB needed - DNS-based service discovery handles load distribution

#### Tier 3: Data Layer (Private DB Subnets)
- **Database:**
  - Service: Amazon RDS
  - Engine: PostgreSQL (or MySQL)
  - Instance Class: `db.t3.micro`
  - Storage: 20 GB GP3
  - Automated Backups: 7-day retention
  - Single AZ deployment (can enable Multi-AZ if needed)

### 3. Network Connectivity

#### Internet Gateway
- **Purpose:** Allow public subnets to communicate with the internet
- **Attached to:** VPC

#### NAT Gateway
- **Count:** 1 (in public-subnet-1a)
- **Purpose:** Allow private subnets (ECS tasks and RDS) to access internet for ECR image pulls and external services
- **Elastic IP:** 1 attached

#### Route Tables

**Public Route Table:**
- Associated with: public-subnet-1a, public-subnet-1b
- Routes:
  - `10.0.0.0/16` → Local
  - `0.0.0.0/0` → Internet Gateway

**Private Route Table (App & DB Subnets):**
- Associated with: app-subnet-1a, app-subnet-1b, db-subnet-1a, db-subnet-1b
- Routes:
  - `10.0.0.0/16` → Local
  - `0.0.0.0/0` → NAT Gateway

### 4. Security Groups

#### ALB Security Group
- **Inbound:**
  - HTTP (80) from 0.0.0.0/0
  - HTTPS (443) from 0.0.0.0/0
- **Outbound:**
  - Port 80 to Frontend ECS Security Group

#### Frontend ECS Security Group
- **Inbound:**
  - Port 80 from ALB Security Group
- **Outbound:**
  - Port 3000 to Backend ECS Security Group
  - Port 443 to 0.0.0.0/0 (for ECR pulls)

#### Backend ECS Security Group
- **Inbound:**
  - Port 3000 from Frontend ECS Security Group
- **Outbound:**
  - Port 5432 (PostgreSQL) or 3306 (MySQL) to RDS Security Group
  - Port 443 to 0.0.0.0/0 (for ECR pulls and external APIs)

#### Database Tier Security Group
- **Inbound:**
  - PostgreSQL (5432) or MySQL (3306) from Backend ECS Security Group
- **Outbound:**
  - None required

### 5. Resource Summary

| Component | Quantity | Type/Size |
|-----------|----------|-----------|
| VPC | 1 | /16 CIDR |
| Subnets | 6 | 2 public, 4 private |
| ECS Cluster | 1 | Fargate |
| Frontend Tasks | 2 | 256 CPU / 512 MB |
| Backend Tasks | 2 | 512 CPU / 1024 MB |
| RDS Instance | 1 | db.t3.micro |
| Load Balancer (ALB) | 1 | Internet-facing only |
| NAT Gateway | 1 | Single AZ |
| Internet Gateway | 1 | - |
| ECR Repositories | 2 | Frontend & Backend |
| Cloud Map Namespace | 1 | Service Discovery |

### 6. Service Discovery - How Frontend Finds Backend

**Problem:** Backend container IPs are dynamic and change when tasks restart or scale.

**Solution:** AWS Cloud Map provides DNS-based service discovery.

#### How It Works:

1. **Backend Task Starts:**
   - ECS Task starts with IP `10.0.11.45`
   - ECS automatically registers this IP with Cloud Map under `backend.bhotel.local`

2. **Cloud Map Updates DNS:**
   - Cloud Map creates/updates DNS A record: `backend.bhotel.local → 10.0.11.45`
   - If you have 2 tasks, DNS returns both IPs in round-robin fashion

3. **Frontend Configuration:**
   - Frontend nginx config or environment variable: `BACKEND_URL=http://backend.bhotel.local:3000`
   - Frontend makes API call: `fetch('http://backend.bhotel.local:3000/api/users')`

4. **DNS Resolution:**
   - Container's DNS resolver queries VPC DNS
   - Gets current backend task IP(s) from Cloud Map
   - Connection made to actual backend container

5. **Task Restarts/IP Changes:**
   - Old task with IP `10.0.11.45` stops → Cloud Map removes it from DNS
   - New task with IP `10.0.11.78` starts → Cloud Map adds new IP to DNS
   - Frontend keeps using same DNS name - no code changes needed!

#### Service Discovery Configuration:

```
AWS Cloud Map Namespace: bhotel.local (private to VPC)
  ├─ Service: backend
  │   └─ DNS Name: backend.bhotel.local
  │   └─ Records: A (IPv4 addresses)
  │   └─ Health Checks: ECS task health
  │   └─ TTL: 10 seconds
  └─ Auto-registration: Enabled (ECS manages it)
```

**In Frontend Container:**
- No special discovery logic needed
- Just use DNS name like any other HTTP endpoint
- Standard DNS resolution handles everything

**Benefits:**
- ✅ No hardcoded IPs
- ✅ Automatic updates when tasks change
- ✅ Built-in round-robin load balancing via DNS
- ✅ Only healthy tasks returned
- ✅ No additional ALB cost (~$22/month saved)

### 7. Container Infrastructure

#### Amazon ECR (Elastic Container Registry)
- **Repositories:**
  - `bhotel-frontend` - nginx-based frontend container
  - `bhotel-backend` - Node.js Express API container
- **Image Scanning:** Enabled for vulnerability detection
- **Lifecycle Policy:** Keep last 10 images, remove untagged images after 14 days

#### ECS Cluster Configuration
- **Cluster Name:** `bhotel-cluster`
- **Launch Type:** Fargate (serverless, no EC2 management)
- **Services:** 2 (frontend-service, backend-service)
- **Task Definitions:**
  - Frontend: nginx container exposing port 80
  - Backend: Node Express container exposing port 3000

---

## Cost Optimization

### Estimated Monthly Cost
- **ECS Fargate Tasks:** ~$30-40 (2 frontend + 2 backend tasks)
- **RDS db.t3.micro:** ~$15 (single AZ)
- **ALB:** ~$22
- **NAT Gateway:** ~$32
- **ECR Storage:** ~$1-5
- **Data Transfer:** ~$5-10
- **Total Estimated:** ~$105-125/month

### Cost-Saving Strategies
1. Use Fargate Spot for non-critical environments (70% savings)
2. Single AZ RDS for development/staging
3. Scale down ECS tasks during off-peak hours
4. Implement ALB request-based pricing awareness
5. Use ECR lifecycle policies to remove old images

---

## Security Best Practices

1. **Network Segmentation:** Frontend in public subnets, backend and database in private subnets
2. **Principle of Least Privilege:** Security groups allow only necessary traffic between tiers
3. **No Direct Internet Access:** Backend and database have no public IPs
4. **Container Security:**
   - Scan ECR images for vulnerabilities
   - Use minimal base images
   - Run containers as non-root users
5. **Encryption:**
   - RDS encryption at rest
   - SSL/TLS for ALB HTTPS listeners
   - Encrypted environment variables in ECS task definitions
6. **Secrets Management:** Use AWS Secrets Manager or SSM Parameter Store for database credentials
7. **IAM Roles:** ECS task roles with minimal permissions for ECR pull and AWS service access

---

## High Availability

- ✅ Multi-AZ deployment for frontend and backend ECS tasks
- ✅ Application Load Balancer with health checks
- ✅ ECS service auto-recovery on task failures
- ✅ Database backups with 7-day retention
- ✅ Redundant resources across 2 availability zones

---

## Deployment Flow

1. **Build & Push Images:**
   ```bash
   docker build -t bhotel-frontend ./frontend
   docker tag bhotel-frontend:latest <account-id>.dkr.ecr.ap-southeast-1.amazonaws.com/bhotel-frontend:latest
   docker push <account-id>.dkr.ecr.ap-southeast-1.amazonaws.com/bhotel-frontend:latest
   ```

2. **Configure Frontend to Use Service Discovery:**
   - Set environment variable in ECS task definition:
     ```json
     "environment": [
       {
         "name": "BACKEND_API_URL",
         "value": "http://backend.bhotel.local:3000"
       }
     ]
     ```
   - Frontend code uses: `const API_URL = process.env.BACKEND_API_URL;`
   - nginx can proxy: `proxy_pass http://backend.bhotel.local:3000;`

3. **ECS Task Deployment:**
   - ECS pulls latest images from ECR
   - Creates new tasks with updated containers
   - Tasks auto-register with Cloud Map on startup
   - Drains old tasks after health checks pass
   - Cloud Map removes old task IPs from DNS

4. **Traffic Flow:**
   ```
   User Browser → ALB (port 80) → Frontend ECS Task (nginx:80)
                                   │
                                   │ DNS Query: "backend.bhotel.local"
                                   │ Cloud Map returns: 10.0.11.x, 10.0.12.y
                                   ↓
                                   Backend ECS Tasks (Express:3000)
                                   │ 10.0.11.45 (ap-southeast-1a)
                                   │ 10.0.12.67 (ap-southeast-1b)
                                   ↓
                                   RDS (PostgreSQL/MySQL)
   ```
   
   **Note:** Only ONE ALB is used (internet-facing). Frontend-to-backend uses 
   DNS resolution via Cloud Map - no second ALB needed!

---

## Next Steps

1. ✅ Review architecture requirements
2. Finalize RDS engine choice (PostgreSQL vs MySQL)
3. Define ECS task IAM roles and policies
4. Create ECR repositories and push initial images
5. Set up CloudWatch log groups for containers
6. Develop Terraform infrastructure code
7. Plan deployment and testing strategy
