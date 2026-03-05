# ECR Push Guide

## Prerequisites
1. AWS CLI installed and configured
2. Docker installed and running
3. Your application code with Dockerfile

## Step 1: Authenticate Docker to ECR

```bash
# Get your AWS account ID and region from terraform outputs
AWS_ACCOUNT_ID="541645813745"
AWS_REGION="ap-southeast-1"

# Login to ECR
aws ecr get-login-password --region ${AWS_REGION} | \
  docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com
```

## Step 2: Build & Push Frontend Image

```bash
# Navigate to your frontend directory
cd /path/to/your/frontend

# Build the Docker image
docker build -t bhotel-frontend .

# Tag the image for ECR
docker tag bhotel-frontend:latest \
  541645813745.dkr.ecr.ap-southeast-1.amazonaws.com/bhotel-dev-frontend:latest

# Push to ECR
docker push 541645813745.dkr.ecr.ap-southeast-1.amazonaws.com/bhotel-dev-frontend:latest
```

## Step 3: Build & Push Backend Image

```bash
# Navigate to your backend directory
cd /path/to/your/backend

# Build the Docker image  
docker build -t bhotel-backend .

# Tag the image for ECR
docker tag bhotel-backend:latest \
  541645813745.dkr.ecr.ap-southeast-1.amazonaws.com/bhotel-dev-backend:latest

# Push to ECR
docker push 541645813745.dkr.ecr.ap-southeast-1.amazonaws.com/bhotel-dev-backend:latest
```

## Example Dockerfiles

### Frontend Dockerfile (nginx-based)
```dockerfile
# Build stage
FROM node:18-alpine AS build
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

# Production stage
FROM nginx:alpine
COPY --from=build /app/dist /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

### Backend Dockerfile (Node.js)
```dockerfile
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
EXPOSE 3000
CMD ["node", "server.js"]
```

## Verification

```bash
# List images in frontend repository
aws ecr list-images \
  --repository-name bhotel-dev-frontend \
  --region ap-southeast-1

# List images in backend repository
aws ecr list-images \
  --repository-name bhotel-dev-backend \
  --region ap-southeast-1
```

## Quick Push Script

```bash
#!/bin/bash
set -e

# Configuration
AWS_ACCOUNT_ID="541645813745"
AWS_REGION="ap-southeast-1"
FRONTEND_REPO="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/bhotel-dev-frontend"
BACKEND_REPO="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/bhotel-dev-backend"

# Login to ECR
echo "Logging in to ECR..."
aws ecr get-login-password --region ${AWS_REGION} | \
  docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com

# Build and push frontend
echo "Building frontend..."
cd frontend
docker build -t bhotel-frontend .
docker tag bhotel-frontend:latest ${FRONTEND_REPO}:latest
echo "Pushing frontend..."
docker push ${FRONTEND_REPO}:latest

# Build and push backend
echo "Building backend..."
cd ../backend
docker build -t bhotel-backend .
docker tag bhotel-backend:latest ${BACKEND_REPO}:latest
echo "Pushing backend..."
docker push ${BACKEND_REPO}:latest

echo "Done! Images pushed successfully."
```

## After Pushing Images

Once images are in ECR, update your ECS services to trigger new deployments:

```bash
cd terraform

# Force new deployment (this will pull latest images)
aws ecs update-service \
  --cluster bhotel-dev-cluster \
  --service bhotel-dev-frontend \
  --force-new-deployment \
  --region ap-southeast-1

aws ecs update-service \
  --cluster bhotel-dev-cluster \
  --service bhotel-dev-backend \
  --force-new-deployment \
  --region ap-southeast-1
```
