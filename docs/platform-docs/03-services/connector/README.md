# Connector Service

> DSP/CRM adapters, OAuth management, and rate limiting.

---

## Service Overview

| Property | Value |
| ---------- | ------- |
| **Language** | Go 1.21+ |
| **Framework** | Gin |
| **Database** | PostgreSQL + Redis |
| **Port** | 8003 |
| **gRPC Port** | 9003 |
| **Replicas** | 5 (scaling based on queue) |
| **Owner** | Data Team |

---

## Responsibilities

1. **DSP Adapters** - DV360, TTD, Meta, Google Ads connectors
2. **OAuth Management** - Token refresh, credential storage
3. **Rate Limiting** - Per-DSP rate limit enforcement
4. **Request Batching** - Combine similar requests
5. **Circuit Breaker** - Handle DSP failures gracefully
6. **Request Queue** - Priority-based request processing

---

## Supported Connectors

| DSP | Auth | Read | Write | Rate Limit |
| ----- | ------ | ------ | ------- | ------------ |
| DV360 | OAuth 2.0 | ✓ | Phase 2 | 50/min |
| TTD | API Key | ✓ | Phase 2 | 100/min |
| Meta | OAuth 2.0 | ✓ | Phase 2 | 200/hour |
| Google Ads | OAuth 2.0 | ✓ | Phase 2 | 15,000/day |
| CRM (Sheets) | OAuth 2.0 | ✓ | ✓ | 100/min |

---

## API Endpoints

### GET /api/v1/connectors

List connectors for organization.

**Response (200):**

```json
{
  "connectors": [
    {
      "id": "conn_123",
      "type": "DV360",
      "account_id": "dsp_acc_456",
      "status": "connected",
      "health": {
        "status": "healthy",
        "last_check": "2024-12-23T10:00:00Z",
        "latency_ms": 245,
        "error_rate": 0.02
      },
      "rate_limit": {
        "limit": 100,
        "remaining": 78,
        "reset_at": "2024-12-23T11:00:00Z"
      }
    }
  ]
}
```

---

### POST /api/v1/connectors/oauth/initiate

Initiate OAuth flow for DSP connection.

**Request:**

```json
{
  "connector_type": "DV360",
  "callback_url": "https://app.example.com/oauth/callback"
}
```

**Response (200):**

```json
{
  "authorization_url": "https://accounts.google.com/o/oauth2/v2/auth?...",
  "state": "random_state_token"
}
```

---

### POST /api/v1/connectors/oauth/callback

Complete OAuth flow with authorization code.

**Request:**

```json
{
  "code": "oauth_code",
  "state": "random_state_token"
}
```

**Response (200):**

```json
{
  "connector_id": "conn_123",
  "status": "connected",
  "accounts": [
    {
      "id": "dsp_acc_456",
      "name": "Acme Corp DV360"
    }
  ]
}
```

---

### POST /api/v1/connectors/fetch

Request data fetch from DSP.

**Request:**

```json
{
  "connector_id": "conn_123",
  "report_type": "campaign_performance",
  "date_range": {
    "start": "2024-12-16",
    "end": "2024-12-23"
  },
  "fields": ["impressions", "clicks", "conversions"],
  "priority": "normal"
}
```

**Response (200):**

```json
{
  "request_id": "req_789",
  "status": "queued",
  "queue_position": 3,
  "estimated_wait_seconds": 45,
  "batched_with": ["req_788"],
  "rate_limit_status": {
    "current": 98,
    "limit": 100,
    "reset_at": "2024-12-23T11:00:00Z"
  }
}
```

---

### GET /api/v1/connectors/requests/{request_id}

Get request status.

**Response (200):**

```json
{
  "request_id": "req_789",
  "status": "completed",
  "progress": 100,
  "result": {
    "records_fetched": 1250,
    "size_bytes": 524288,
    "storage_location": "s3://bucket/path/to/data.parquet"
  },
  "execution_time_ms": 1245,
  "cost": 0.05
}
```

---

### GET /api/v1/connectors/queue

Get current queue status.

**Response (200):**

```json
{
  "queue_status": {
    "total_queued": 12,
    "your_requests": 2,
    "positions": [3, 7],
    "estimated_wait_seconds": 65
  },
  "rate_limits": {
    "DV360": {
      "limit": 100,
      "remaining": 12,
      "reset_at": "2024-12-23T11:00:00Z"
    }
  }
}
```

---

## Database Schemas

### connectors

```sql
CREATE TABLE connectors (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    org_id INT REFERENCES organizations(id) ON DELETE CASCADE,
    type VARCHAR(50) NOT NULL,
    account_id VARCHAR(255),
    credentials JSONB,
    status VARCHAR(50) DEFAULT 'pending',
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    last_sync_at TIMESTAMP
);

CREATE INDEX idx_connectors_org ON connectors(org_id);
CREATE INDEX idx_connectors_type ON connectors(type);
```

### connector_requests

```sql
CREATE TABLE connector_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    connector_id UUID REFERENCES connectors(id),
    org_id INT REFERENCES organizations(id),
    request_type VARCHAR(100) NOT NULL,
    params JSONB NOT NULL,
    status VARCHAR(50) DEFAULT 'queued',
    priority INT DEFAULT 50,
    queue_position INT,
    batched_with UUID[],
    result JSONB,
    error TEXT,
    execution_time_ms INT,
    cost DECIMAL(10,4),
    created_at TIMESTAMP DEFAULT NOW(),
    started_at TIMESTAMP,
    completed_at TIMESTAMP
);

CREATE INDEX idx_requests_status ON connector_requests(status);
```

### rate_limits

```sql
CREATE TABLE rate_limits (
    id SERIAL PRIMARY KEY,
    connector_type VARCHAR(50) NOT NULL,
    org_id INT REFERENCES organizations(id),
    endpoint VARCHAR(255),
    limit_value INT NOT NULL,
    current_count INT DEFAULT 0,
    window_start TIMESTAMP NOT NULL,
    window_end TIMESTAMP NOT NULL,
    UNIQUE(connector_type, org_id, endpoint, window_start)
);
```

---

## Priority Queue

| Priority | Description | Use Case |
| ---------- | ------------- | ---------- |
| 1 (Highest) | Premium manual trigger | User clicks refresh |
| 2 | Standard manual trigger | User request |
| 3 | Scheduled job | Cron-based pipelines |
| 4 | Retry queue | Failed requests |
| 5 (Lowest) | Backfill | Historical data |

---

## Circuit Breaker

```go
type CircuitBreaker struct {
    FailureThreshold int           // 5
    RecoveryTimeout  time.Duration // 30s
    SuccessThreshold int           // 2
}

// States: CLOSED -> OPEN -> HALF_OPEN -> CLOSED
```

When circuit opens:

1. Return cached data if available
2. Show "Data may be stale" to user
3. Retry after recovery timeout

---

## Request Batching

Similar requests within 5-minute window are merged:

```go
func ShouldBatch(req1, req2 Request) bool {
    return req1.ConnectorID == req2.ConnectorID &&
           req1.ReportType == req2.ReportType &&
           req1.DateRange.Overlaps(req2.DateRange) &&
           time.Since(req1.CreatedAt) < 5*time.Minute
}
```

---

## Configuration

```yaml
connector:
  queue:
    max_concurrent: 10
    batch_window: 5m
  rate_limit:
    dv360:
      requests_per_minute: 50
      daily_limit: 10000
    ttd:
      requests_per_minute: 100
  circuit_breaker:
    failure_threshold: 5
    recovery_timeout: 30s
```

---

## Events Published

| Topic | Event |
| ------- | ------- |
| `connector.events` | `data_fetched`, `fetch_failed` |
| `connector.events` | `oauth_connected`, `oauth_revoked` |
| `connector.events` | `rate_limit_hit`, `circuit_opened` |

---

## Navigation

- **Up:** [Service Catalog](../README.md)
- **Previous:** [Config Service](../config/README.md)
- **Next:** [ETL Service](../etl/README.md)
