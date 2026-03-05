## Phase 2: Incremental Scaling (Future Planning)

### Scaling Triggers
- **CPU Utilization > 70%** for 5 minutes → Scale out
- **Traffic increase beyond current capacity**
- **Database performance degradation**

### Horizontal Scaling Options

#### Presentation Tier
- Increase Auto Scaling Max from 4 to 8
- Upgrade to `t3.small` or `t3.medium`

#### Application Tier
- Increase Auto Scaling Max from 4 to 8
- Upgrade to `t3.medium` or `c5.large` for compute-intensive workloads

#### Data Tier
- Upgrade RDS instance class: `db.t3.small` → `db.t3.medium` → `db.r5.large`
- Add Read Replicas in same or different AZs
- Increase storage from 20 GB to 100 GB or more

### Additional Components for Growth
- **CloudFront CDN:** For static content distribution
- **ElastiCache (Redis/Memcached):** Application-level caching
- **S3 Buckets:** Static assets, user uploads, backups
- **Additional NAT Gateway:** Deploy in ap-southeast-1b for redundancy
- **Route 53:** DNS management and health checks
- **CloudWatch:** Enhanced monitoring and alerting
- **AWS WAF:** Web application firewall for ALB

### Network Expansion
- Reserve additional CIDR blocks for future tiers:
  - `10.0.31.0/24`, `10.0.32.0/24` - Cache tier
  - `10.0.41.0/24`, `10.0.42.0/24` - Management/Bastion
  - `10.0.51.0/24`, `10.0.52.0/24` - Reserved for future services

---

## Cost Optimization Considerations

### Current Phase 1 Estimated Monthly Cost
- **EC2 Instances (t3.micro x2, t3.small x2):** ~$50
- **RDS db.t3.micro Multi-AZ:** ~$30
- **ALB:** ~$22
- **NAT Gateway:** ~$32
- **Data Transfer & Storage:** ~$10-20
- **Total Estimated:** ~$150-160/month

### Optimization Strategies
1. Use Reserved Instances for predictable workloads (up to 72% savings)
2. Enable Auto Scaling to match demand
3. Right-size instances based on monitoring data
4. Use S3 lifecycle policies for old backups
5. Consider Savings Plans for long-term commitments

---

## Security Best Practices

1. **Network Segmentation:** Clear tier separation via subnets
2. **Principle of Least Privilege:** Security groups allow only necessary traffic
3. **No Direct Internet Access:** App and DB tiers isolated in private subnets
4. **Encryption:**
   - RDS encryption at rest
   - SSL/TLS for data in transit
   - ALB with HTTPS listeners
5. **Monitoring:** CloudWatch logs and metrics enabled
6. **Backup Strategy:** Automated RDS backups with 7-day retention
7. **Future:** Implement AWS Secrets Manager for credentials

---

## High Availability Features

- ✅ Multi-AZ deployment for all tiers
- ✅ Auto Scaling for web and app tiers
- ✅ RDS Multi-AZ for automatic failover
- ✅ Application Load Balancer health checks
- ✅ Redundant resources across 2 availability zones

---

## Next Steps

1. **Review and Validate:** Confirm requirements with stakeholders
2. **Finalize Configuration:** Decide on specific instance types and sizes based on application needs
3. **Security Planning:** Define IAM roles, KMS keys, and access policies
4. **Monitoring Strategy:** Plan CloudWatch dashboards and alarms
5. **Terraform Development:** Convert architecture to Infrastructure as Code
6. **Testing Plan:** Define deployment and rollback procedures

---