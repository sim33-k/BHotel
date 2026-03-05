# Updated Nginx Configuration for ALB-based Routing

## Architecture Change

**Before (Service Discovery):**
```
Browser → ALB → Frontend (nginx) → proxy to backend.bhotel.local:3000 → Backend
```

**After (ALB Routing):**
```
Browser → ALB → Frontend (nginx serves static files)
Browser → ALB (/api/*) → Backend (direct routing)
```

## Updated nginx Configuration

Replace your current nginx config with this simplified version:

```nginx
server {
    listen 80;
    server_name _;
    
    root /usr/share/nginx/html;
    index index.html;

    # Serve static files
    location / {
        try_files $uri $uri/ /index.html;
    }

    # Health check endpoint for ALB
    location /health {
        access_log off;
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }

    # Enable gzip compression
    gzip on;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;
}
```

## What Changed?

### Removed:
- ❌ `/api/` proxy_pass block - ALB now handles this routing
- ❌ All proxy headers
- ❌ Backend service discovery reference

### Added:
- ✅ `/health` endpoint for ALB health checks

## How It Works Now

1. **ALB Configuration** (already set up in Terraform):
   - Default route (`/`) → Frontend target group
   - `/api/*` route → Backend target group
   - `/health` route → Backend target group (for backend health)

2. **Frontend Container**:
   - Serves static HTML/CSS/JS files
   - No backend proxying needed

3. **Client-Side JavaScript**:
   - Makes API calls to `/api/users`, `/api/products`, etc.
   - Browser sends these to the same ALB hostname
   - ALB routes to backend based on path

## Example API Calls in Your JavaScript

```javascript
// In your React/Vue/Angular frontend code

// Get ALB URL from environment or use relative paths
const API_BASE = '/api';  // Relative to current hostname

// Make API calls
fetch(`${API_BASE}/users`)
  .then(res => res.json())
  .then(users => console.log(users));

// Or with axios
axios.get('/api/products')
  .then(res => console.log(res.data));
```

The browser will send these requests to the same ALB that served the frontend, and the ALB will route `/api/*` to your backend.

## Rebuild & Deploy Steps

### 1. Update nginx config in your frontend project
Save the simplified nginx config above to your nginx configuration file.

### 2. Rebuild frontend image
```bash
cd /path/to/your/frontend

# Login to ECR
aws ecr get-login-password --region ap-southeast-1 | \
  docker login --username AWS --password-stdin \
  541645813745.dkr.ecr.ap-southeast-1.amazonaws.com

# Rebuild
docker build -t bhotel-frontend .

# Tag
docker tag bhotel-frontend:latest \
  541645813745.dkr.ecr.ap-southeast-1.amazonaws.com/bhotel-dev-frontend:latest

# Push
docker push 541645813745.dkr.ecr.ap-southeast-1.amazonaws.com/bhotel-dev-frontend:latest
```

### 3. Apply Terraform changes
```bash
cd /home/simaak/Documents/BHotel/terraform

# Review changes
terraform plan

# Apply (removes service discovery resources)
terraform apply
```

### 4. Force new deployment
```bash
# Deploy updated frontend
aws ecs update-service \
  --cluster bhotel-dev-cluster \
  --service bhotel-dev-frontend \
  --force-new-deployment \
  --region ap-southeast-1

# Backend doesn't need redeployment, but you can restart it if needed
aws ecs update-service \
  --cluster bhotel-dev-cluster \
  --service bhotel-dev-backend \
  --force-new-deployment \
  --region ap-southeast-1
```

## Testing

### Test Frontend
```bash
curl http://bhotel-dev-alb-1744976539.ap-southeast-1.elb.amazonaws.com/
```
Should return your HTML page.

### Test Backend via ALB
```bash
curl http://bhotel-dev-alb-1744976539.ap-southeast-1.elb.amazonaws.com/api/health
# or
curl http://bhotel-dev-alb-1744976539.ap-southeast-1.elb.amazonaws.com/health
```
Should return backend health response.

### Test in Browser
1. Open: `http://bhotel-dev-alb-1744976539.ap-southeast-1.elb.amazonaws.com`
2. Open browser DevTools → Network tab
3. Make an API call from your frontend JavaScript
4. You should see request to `/api/...` going to the same hostname

## Benefits of This Approach

✅ **Simpler** - No nginx proxy configuration needed  
✅ **Fewer moving parts** - ALB handles all routing  
✅ **Better performance** - Direct ALB routing, no double hop  
✅ **Easier debugging** - Clear separation of concerns  
✅ **Standard pattern** - Common in containerized applications  

## ALB Routing Rules

Your ALB is configured with these rules (already in Terraform):

| Priority | Path Pattern | Destination | Purpose |
|----------|-------------|-------------|---------|
| 99 | `/health` | Backend | Backend health checks |
| 100 | `/api/*` | Backend | API requests |
| Default | `/*` | Frontend | Static files (HTML/CSS/JS) |

## Important Notes

### Backend API Paths
Make sure your backend routes are set up correctly:

```javascript
// In your Express backend (server.ts/server.js)

// Health check
app.get('/health', (req, res) => {
  res.send('OK');
});

// API routes - note these should include /api prefix
app.use('/api', apiRouter);

// Or define routes with /api prefix
app.get('/api/users', (req, res) => {
  // ...
});
```

### Environment Variables
If your frontend needs to know the API base URL, you can:

1. **Use relative paths** (recommended):
   ```javascript
   const API_BASE = '/api';
   ```

2. **Use environment variables**:
   ```javascript
   const API_BASE = process.env.REACT_APP_API_URL || '/api';
   ```

3. **Inject at build time**:
   ```dockerfile
   # In your Dockerfile
   ENV REACT_APP_API_URL=/api
   ```

## Monitoring

After deployment, check:

```bash
# Service status
aws ecs describe-services \
  --cluster bhotel-dev-cluster \
  --services bhotel-dev-frontend bhotel-dev-backend \
  --region ap-southeast-1 \
  --query 'services[*].[serviceName,runningCount,desiredCount]' \
  --output table

# Target health
aws elbv2 describe-target-health \
  --target-group-arn $(terraform output -raw frontend_target_group_arn) \
  --region ap-southeast-1

aws elbv2 describe-target-health \
  --target-group-arn $(terraform output -raw backend_target_group_arn) \
  --region ap-southeast-1

# Logs
aws logs tail /ecs/bhotel-dev/frontend --follow --region ap-southeast-1
aws logs tail /ecs/bhotel-dev/backend --follow --region ap-southeast-1
```

---

This is a much cleaner architecture! The ALB does what it's designed for (routing), and your containers focus on their core responsibilities.
