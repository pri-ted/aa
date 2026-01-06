# Analytics Service

> Health monitoring, cost tracking, and recommendations.

---

## Service Overview

| Property | Value |
| ---------- | ------- |
| **Language** | Go 1.21+ |
| **Framework** | Gin |
| **Database** | PostgreSQL + ClickHouse |
| **Port** | 8011 |
| **gRPC Port** | 9011 |
| **Replicas** | 3 |
| **Owner** | Platform Team |

---

## Responsibilities

1. **Pipeline Health** - Monitor execution success/failure
2. **Cost Tracking** - Track platform usage costs
3. **Budget Alerts** - Notify on budget thresholds
4. **Recommendations** - Suggest optimizations
5. **Usage Analytics** - Track feature adoption

---

## API Endpoints

### GET /api/v1/analytics/health

Get pipeline health summary.

**Response (200):**

```json
{
  "pipelines": [
    {
      "id": "pipe_456",
      "name": "DV360 Daily",
      "status": "healthy",
      "uptime_7d": 99.8,
      "success_rate_7d": 98.5,
      "avg_duration_ms": 10900,
      "last_run": {
        "timestamp": "2024-12-23T06:00:00Z",
        "status": "success",
        "records": 125000
      },
      "recommendations": [
        {
          "type": "optimization",
          "title": "Merge with similar pipeline",
          "savings_per_month": 45.50
        }
      ]
    }
  ],
  "overall_health": {
    "score": 95.2,
    "total_pipelines": 12,
    "healthy": 11,
    "degraded": 1,
    "failing": 0
  }
}
```

---

### GET /api/v1/analytics/costs

Get cost tracking data.

**Response (200):**

```json
{
  "current_month": {
    "total_spent": 847.50,
    "budget": 2000.00,
    "percent_used": 42.38,
    "forecast": 1650.00,
    "breakdown": {
      "api_calls": 450.20,
      "compute": 245.80,
      "storage": 151.50
    }
  },
  "by_pipeline": [
    {
      "pipeline_id": "pipe_456",
      "pipeline_name": "DV360 Daily",
      "cost": 125.50,
      "percent_of_total": 14.8
    }
  ],
  "recommendations": [
    {
      "type": "cost_optimization",
      "title": "Pause low-priority pipeline",
      "potential_savings": 120.00
    }
  ]
}
```

---

### GET /api/v1/analytics/usage

Get usage analytics.

**Response (200):**

```json
{
  "current_period": {
    "api_calls": 12450,
    "data_processed_gb": 145.6,
    "queries_executed": 8900,
    "active_users": 12
  },
  "by_module": [
    {
      "module": "pacing",
      "api_calls": 5600,
      "data_processed_gb": 67.3
    }
  ]
}
```

---

## Database Schemas

### cost_tracking

```sql
CREATE TABLE cost_tracking (
    id BIGSERIAL PRIMARY KEY,
    org_id INT REFERENCES organizations(id),
    operation_type VARCHAR(100) NOT NULL,
    resource_id UUID,
    cost DECIMAL(10,4) NOT NULL,
    details JSONB,
    timestamp TIMESTAMP DEFAULT NOW()
);
```

### budgets

```sql
CREATE TABLE budgets (
    id SERIAL PRIMARY KEY,
    org_id INT REFERENCES organizations(id) UNIQUE,
    monthly_limit DECIMAL(10,2) NOT NULL,
    alert_thresholds DECIMAL[] DEFAULT '{0.75, 0.90, 1.0}',
    current_spend DECIMAL(10,2) DEFAULT 0,
    period_start DATE NOT NULL,
    period_end DATE NOT NULL
);
```

### health_metrics

```sql
CREATE TABLE health_metrics (
    id BIGSERIAL PRIMARY KEY,
    pipeline_id UUID REFERENCES pipelines(id),
    org_id INT REFERENCES organizations(id),
    metric_type VARCHAR(100),
    value DECIMAL(10,4),
    timestamp TIMESTAMP DEFAULT NOW()
);
```

---

## Health Scoring

| Score | Status | Criteria |
| ------- | -------- | ---------- |
| 90-100 | Healthy | >98% success, <5min avg |
| 70-89 | Degraded | >90% success, <15min avg |
| <70 | Failing | <90% success or errors |

---

## Configuration

```yaml
analytics:
  health:
    check_interval: 5m
    degraded_threshold: 90
    failing_threshold: 70
  cost:
    budget_alert_thresholds: [0.75, 0.90, 1.0]
  recommendations:
    similarity_threshold: 0.85
    min_savings: 10.00
```

---

## Navigation

- **Up:** [Service Catalog](../README.md)
- **Previous:** [Rule Engine](../rule-engine/README.md)
- **Next:** [Notification Service](../notification/README.md)
