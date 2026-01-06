# Disaster Recovery

> Backup, recovery, and business continuity.

---

## Recovery Objectives

| Metric | Target | Description |
| -------- | -------- | ------------- |
| **RTO** | 4 hours | Recovery Time Objective |
| **RPO** | 1 hour | Recovery Point Objective |

---

## Backup Strategy

### Database Backups

| Database | Frequency | Retention | Location |
| ---------- | ----------- | ----------- | ---------- |
| PostgreSQL | Hourly | 30 days | S3 cross-region |
| ClickHouse | Daily | 90 days | S3 cross-region |
| Redis | Hourly snapshot | 7 days | S3 |

### PostgreSQL Backup

```yaml
backup:
  schedule: "0 * * * *"  # Hourly
  type: "pg_basebackup"
  
  wal_archiving:
    enabled: true
    destination: "s3://backups/postgres/wal/"
  
  retention:
    full_backups: 7
    wal_files: 168  # 7 days hourly
  
  encryption:
    enabled: true
    key_id: "${KMS_KEY_ID}"
```

### ClickHouse Backup

```yaml
backup:
  schedule: "0 2 * * *"  # Daily at 2 AM
  type: "clickhouse-backup"
  
  tables:
    - "gold.*"
    - "silver.campaign_metrics"
  
  destination: "s3://backups/clickhouse/"
  
  retention:
    daily: 30
    weekly: 12
    monthly: 12
```

---

## Multi-Region Architecture

```text
┌─────────────────────────────────────────────────────────────────────────────┐
│                         MULTI-REGION SETUP                                  │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│   Primary Region (us-east-1)              DR Region (us-west-2)             │
│   ┌─────────────────────┐                 ┌─────────────────────┐           │
│   │  Kubernetes Cluster │                 │  Kubernetes Cluster │           │
│   │  (Active)           │                 │  (Standby)          │           │
│   └──────────┬──────────┘                 └──────────┬──────────┘           │
│              │                                       │                      │
│   ┌──────────▼──────────┐                 ┌──────────▼──────────┐           │
│   │  PostgreSQL         │ ───Streaming──▶ │  PostgreSQL         │           │
│   │  (Primary)          │    Replication  │  (Replica)          │           │
│   └─────────────────────┘                 └─────────────────────┘           │
│                                                                             │
│   ┌─────────────────────┐                 ┌─────────────────────┐           │
│   │  S3 Bucket          │ ──Replication─▶ │  S3 Bucket          │           │
│   │  (Primary)          │                 │  (Replica)          │           │
│   └─────────────────────┘                 └─────────────────────┘           │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Failover Procedures

### Automated Failover

| Component | Failover Time | Trigger |
| ----------- | --------------- | --------- |
| Load Balancer | < 30s | Health check failure |
| Kubernetes Pods | < 2m | Pod health failure |
| Database (replica) | < 5m | Primary unreachable |

### Manual Failover Procedure

#### Step 1: Assess

```bash
# Check primary region status
kubectl --context primary get nodes
pg_isready -h primary-db.internal
```

#### Step 2: Promote DR Region

```bash
# Promote PostgreSQL replica
psql -h dr-db.internal -c "SELECT pg_promote();"

# Update DNS
aws route53 change-resource-record-sets \
  --hosted-zone-id Z123 \
  --change-batch file://dns-failover.json
```

#### Step 3: Verify

```bash
# Run smoke tests
./scripts/smoke-test.sh --region us-west-2
```

---

## Recovery Procedures

### Database Recovery

```bash
# Point-in-time recovery
pg_restore \
  --target-time="2024-12-23 10:00:00" \
  --dbname=platform \
  /backups/latest/
```

### Application Recovery

```bash
# Restore from Git (GitOps)
argocd app sync --prune platform-apps

# Or manual restore
kubectl apply -f k8s/apps/ --recursive
```

---

## Testing Schedule

| Test | Frequency | Duration |
| ------ | ----------- | ---------- |
| Backup verification | Weekly | 1 hour |
| Failover drill | Quarterly | 4 hours |
| Full DR test | Annually | 1 day |

---

## Runbook Checklist

### Pre-Failover

- [ ] Confirm primary region failure
- [ ] Notify stakeholders
- [ ] Verify DR region health
- [ ] Check backup recency

### During Failover

- [ ] Promote DR database
- [ ] Update DNS records
- [ ] Scale up DR cluster
- [ ] Verify service health

### Post-Failover

- [ ] Run smoke tests
- [ ] Monitor error rates
- [ ] Notify customers
- [ ] Document incident

---

## Navigation

- **Up:** [Infrastructure](README.md)
- **Previous:** [Monitoring](monitoring.md)
