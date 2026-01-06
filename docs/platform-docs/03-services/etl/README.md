# ETL Orchestrator

> Workflow orchestration for data pipelines using Temporal.

---

## Service Overview

| Property | Value |
| ---------- | ------- |
| **Language** | Go 1.21+ |
| **Framework** | Temporal SDK |
| **Database** | PostgreSQL |
| **Port** | 8004 |
| **gRPC Port** | 9004 |
| **Replicas** | 3 (workers scale separately) |
| **Owner** | Data Team |

---

## Responsibilities

1. **Workflow Orchestration** - Coordinate Bronze → Silver → Gold flow
2. **Scheduling** - Cron-based pipeline execution
3. **Retry Management** - Automatic retries with backoff
4. **Progress Tracking** - Real-time execution visibility
5. **Data Quality Monitoring** - Track quality metrics per layer

---

## Workflow Types

| Workflow | Purpose | Duration |
| ---------- | --------- | ---------- |
| DataIngestionWorkflow | Fetch from DSP | 1-30 min |
| ETLWorkflow | Bronze → Silver → Gold | 5-15 min |
| BackfillWorkflow | Historical data load | 1-24 hours |
| OnboardingWorkflow | New org setup | 5-10 min |

---

## API Endpoints

### GET /api/v1/etl/executions

List pipeline executions.

**Query Params:**

- `pipeline_id`: UUID (optional)
- `status`: enum (running, completed, failed)
- `date_from`: date
- `date_to`: date

**Response (200):**

```json
{
  "executions": [
    {
      "id": "exec_123",
      "pipeline_id": "pipe_456",
      "pipeline_name": "DV360 Daily",
      "status": "completed",
      "layers": {
        "bronze": {
          "status": "completed",
          "records": 125000,
          "size_mb": 45.3,
          "duration_ms": 3200
        },
        "silver": {
          "status": "completed",
          "records": 124850,
          "records_filtered": 150,
          "duration_ms": 5600
        },
        "gold": {
          "status": "completed",
          "tables_updated": ["campaign_daily", "pacing_metrics"],
          "duration_ms": 2100
        }
      },
      "total_duration_ms": 10900,
      "started_at": "2024-12-23T06:00:00Z",
      "completed_at": "2024-12-23T06:00:11Z"
    }
  ]
}
```

---

### POST /api/v1/etl/trigger

Manually trigger pipeline execution.

**Request:**

```json
{
  "pipeline_id": "pipe_456",
  "parameters": {
    "date_range": {
      "start": "2024-12-20",
      "end": "2024-12-23"
    },
    "force": false
  }
}
```

**Response (200):**

```json
{
  "execution_id": "exec_789",
  "status": "scheduled",
  "estimated_start": "2024-12-23T10:05:00Z"
}
```

---

### GET /api/v1/etl/executions/{execution_id}/logs

Get execution logs.

**Response (200):**

```json
{
  "logs": [
    {
      "timestamp": "2024-12-23T06:00:01Z",
      "level": "info",
      "layer": "bronze",
      "message": "Started data ingestion from DV360"
    },
    {
      "timestamp": "2024-12-23T06:00:04Z",
      "level": "info",
      "layer": "bronze",
      "message": "Fetched 125000 records"
    },
    {
      "timestamp": "2024-12-23T06:00:05Z",
      "level": "warning",
      "layer": "silver",
      "message": "150 records filtered due to data quality issues"
    }
  ]
}
```

---

### GET /api/v1/etl/data-quality

Get data quality metrics.

**Response (200):**

```json
{
  "quality_metrics": {
    "last_24h": {
      "total_records": 125000,
      "valid_records": 124850,
      "quality_score": 99.88,
      "issues": {
        "missing_fields": 100,
        "invalid_types": 50,
        "duplicates": 0
      }
    }
  },
  "by_pipeline": [
    {
      "pipeline_id": "pipe_456",
      "pipeline_name": "DV360 Daily",
      "quality_score": 99.95,
      "issues": 62
    }
  ]
}
```

---

## Temporal Workflows

### ETLWorkflow

```go
func ETLWorkflow(ctx workflow.Context, params ETLParams) error {
    // Step 1: Bronze Layer
    bronzeResult, err := workflow.ExecuteActivity(ctx, 
        BronzeActivity, params).Get(ctx, &bronzeResult)
    if err != nil {
        return err
    }
    
    // Step 2: Silver Layer
    silverResult, err := workflow.ExecuteActivity(ctx,
        SilverActivity, bronzeResult).Get(ctx, &silverResult)
    if err != nil {
        return err
    }
    
    // Step 3: Gold Layer
    goldResult, err := workflow.ExecuteActivity(ctx,
        GoldActivity, silverResult).Get(ctx, &goldResult)
    if err != nil {
        return err
    }
    
    // Step 4: Notify completion
    workflow.ExecuteActivity(ctx, NotifyActivity, goldResult)
    
    return nil
}
```

---

## Database Schemas

### etl_executions

```sql
CREATE TABLE etl_executions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    pipeline_id UUID REFERENCES pipelines(id),
    org_id INT REFERENCES organizations(id),
    status VARCHAR(50) DEFAULT 'running',
    layer VARCHAR(50),
    config JSONB,
    result JSONB,
    error TEXT,
    records_processed BIGINT,
    records_failed BIGINT,
    size_bytes BIGINT,
    duration_ms INT,
    started_at TIMESTAMP DEFAULT NOW(),
    completed_at TIMESTAMP
);

CREATE INDEX idx_executions_pipeline ON etl_executions(pipeline_id);
CREATE INDEX idx_executions_started ON etl_executions(started_at);
```

### data_quality_metrics

```sql
CREATE TABLE data_quality_metrics (
    id BIGSERIAL PRIMARY KEY,
    pipeline_id UUID REFERENCES pipelines(id),
    org_id INT REFERENCES organizations(id),
    execution_id UUID REFERENCES etl_executions(id),
    layer VARCHAR(50),
    metric_type VARCHAR(100),
    count INT,
    severity VARCHAR(50),
    details JSONB,
    timestamp TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_quality_pipeline ON data_quality_metrics(pipeline_id);
```

---

## Retry Strategy

| Failure Type | Max Retries | Backoff |
| -------------- | ------------- | --------- |
| Network error | 5 | Exponential (1s, 2s, 4s, 8s, 16s) |
| Rate limit | 3 | Fixed (wait until reset) |
| Data error | 1 | None (fail fast) |
| Timeout | 3 | Exponential |

---

## Configuration

```yaml
etl:
  temporal:
    namespace: "platform-etl"
    task_queue: "etl-workers"
  workers:
    max_concurrent_activities: 10
    activity_timeout: 30m
  retry:
    max_attempts: 5
    initial_interval: 1s
    max_interval: 1m
    backoff_coefficient: 2
```

---

## Events Published

| Topic | Event |
| ------- | ------- |
| `etl.events` | `execution.started`, `execution.completed`, `execution.failed` |
| `etl.events` | `layer.completed` (bronze, silver, gold) |
| `etl.events` | `quality.issue_detected` |

---

## Navigation

- **Up:** [Service Catalog](../README.md)
- **Previous:** [Connector Service](../connector/README.md)
- **Next:** [Bronze Service](../bronze/README.md)