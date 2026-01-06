# Data Flow

> How data moves through the platform from source to dashboard.

---

## End-to-End Data Flow

```text
┌─────────────────────────────────────────────────────────────────────────────┐
│                         COMPLETE DATA FLOW                                  │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│   SOURCES                                                                   │
│   ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐                           │
│   │ DV360   │ │   TTD   │ │  Meta   │ │  CRM    │                           │
│   │   API   │ │   API   │ │   API   │ │ Sheets  │                           │
│   └────┬────┘ └────┬────┘ └────┬────┘ └────┬────┘                           │
│        │           │           │           │                                │
│        └───────────┴───────────┴───────────┘                                │
│                         │                                                   │
│                         ▼                                                   │
│   ┌─────────────────────────────────────────────────────────────────────┐   │
│   │                    CONNECTOR ORCHESTRATOR                           │   │
│   │  • OAuth token management    • Rate limit handling                  │   │
│   │  • Request queuing           • Circuit breakers                     │   │
│   └────────────────────────────────┬────────────────────────────────────┘   │
│                                    │                                        │
│                                    ▼                                        │
│   ┌─────────────────────────────────────────────────────────────────────┐   │
│   │                         KAFKA                                       │   │
│   │                   Topic: connector.data.raw                         │   │
│   └────────────────────────────────┬────────────────────────────────────┘   │
│                                    │                                        │
│                                    ▼                                        │
│   ┌─────────────────────────────────────────────────────────────────────┐   │
│   │                      BRONZE LAYER (RAW)                             │   │
│   │  Storage: Apache Iceberg on S3                                      │   │
│   │  Operations:                                                        │   │
│   │  • Schema-on-read                                                   │   │
│   │  • Deduplication (request-level)                                    │   │
│   │  • Partitioning by org_id, date                                     │   │
│   │  Retention: 90 days                                                 │   │
│   └────────────────────────────────┬────────────────────────────────────┘   │
│                                    │                                        │
│                                    ▼                                        │
│   ┌─────────────────────────────────────────────────────────────────────┐   │
│   │                      SILVER LAYER (CLEANED)                         │   │
│   │  Storage: Apache Iceberg on S3                                      │   │
│   │  Operations:                                                        │   │
│   │  • Type validation & casting                                        │   │
│   │  • Null handling                                                    │   │
│   │  • Deduplication (entity-level)                                     │   │
│   │  • Quality scoring                                                  │   │
│   │  Retention: 1 year                                                  │   │
│   └────────────────────────────────┬────────────────────────────────────┘   │
│                                    │                                        │
│                                    ▼                                        │
│   ┌─────────────────────────────────────────────────────────────────────┐   │
│   │                       GOLD LAYER (BUSINESS)                         │   │
│   │  Storage: ClickHouse                                                │   │
│   │  Operations:                                                        │   │
│   │  • Aggregations (daily, weekly, monthly)                            │   │
│   │  • Joins (campaign + booking + CRM)                                 │   │
│   │  • Calculated metrics (pacing, margin)                              │   │
│   │  • Materialized views                                               │   │
│   │  Retention: 2 years                                                 │   │
│   └────────────────────────────────┬────────────────────────────────────┘   │
│                                    │                                        │
│                    ┌───────────────┼───────────────┐                        │
│                    │               │               │                        │
│                    ▼               ▼               ▼                        │
│   ┌────────────────────┐ ┌────────────────┐ ┌────────────────────┐          │
│   │  CALCULATION       │ │  RULE ENGINE   │ │  ANALYTICS         │          │
│   │  ENGINE            │ │                │ │  SERVICE           │          │
│   │  • Formula eval    │ │  • Conditions  │ │  • Health metrics  │          │
│   │  • JIT compile     │ │  • Actions     │ │  • Cost tracking   │          │
│   └────────┬───────────┘ └────────┬───────┘ └────────┬───────────┘          │
│            │                      │                  │                      │
│            └──────────────────────┼──────────────────┘                      │
│                                   │                                         │
│                                   ▼                                         │
│   ┌─────────────────────────────────────────────────────────────────────┐   │
│   │                      GRAPHQL GATEWAY                                │   │
│   │  • Query federation    • Response caching                           │   │
│   │  • Subscriptions       • Rate limiting                              │   │
│   └────────────────────────────────┬────────────────────────────────────┘   │
│                                    │                                        │
│                                    ▼                                        │
│   ┌─────────────────────────────────────────────────────────────────────┐   │
│   │                         FRONTEND                                    │   │
│   │  • Dashboards    • Reports    • Alerts    • Configuration           │   │
│   └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Data Pipeline Stages

### Stage 1: Ingestion

**Trigger:** Scheduled (cron) or on-demand

**Process:**

1. Connector Orchestrator checks rate limits
2. Fetches data from DSP API
3. Publishes raw JSON to Kafka topic
4. Updates pipeline status

**Latency:** 1-30 minutes (depends on DSP report generation)

**Error Handling:**

- Retry with exponential backoff (3 attempts)
- Circuit breaker opens after 5 consecutive failures
- Dead-letter queue for failed messages

---

### Stage 2: Bronze Processing

**Trigger:** Kafka message on `connector.data.raw`

**Process:**

1. Parse raw JSON
2. Apply schema-on-read validation
3. Deduplicate by request_id
4. Write to Iceberg partitioned by (org_id, date)
5. Publish event to `bronze.data.cleaned`

**Latency:** < 5 minutes

**Data Quality:**

- Schema validation (structure present)
- Completeness check (required fields)
- Freshness check (timestamp within expected range)

---

### Stage 3: Silver Processing

**Trigger:** Kafka message on `bronze.data.cleaned`

**Process:**

1. Read from Bronze Iceberg table
2. Apply type casting and validation
3. Handle nulls (default values, exclusion rules)
4. Deduplicate by entity_id + date
5. Calculate quality scores
6. Write to Silver Iceberg table
7. Publish event to `silver.data.processed`

**Latency:** < 10 minutes

**Transformations:**

| Field | Transformation |
| ------- | --------------- |
| impressions | Cast to BIGINT, default 0 |
| spend | Cast to DECIMAL(15,2), round |
| date | Parse to DATE, validate range |
| campaign_id | Normalize to string, trim |

---

### Stage 4: Gold Processing

**Trigger:** Kafka message on `silver.data.processed`

**Process:**

1. Read from Silver Iceberg table
2. Join with booking data (if available)
3. Join with CRM data (if available)
4. Apply business calculations (pacing, margin)
5. Create aggregations (daily, weekly, monthly)
6. Write to ClickHouse tables
7. Refresh materialized views
8. Publish event to `gold.data.ready`

**Latency:** < 15 minutes

**Calculations:**

```sql
-- Pacing Rate
pacing_rate = (delivered_impressions / booked_impressions) 
            × (total_days / elapsed_days) 
            × 100

-- Margin
margin_percent = ((booking_revenue - actual_spend) / booking_revenue) 
               × 100

-- Variance
variance = booked_quantity - delivered_quantity
```

---

## Event Flow

### Happy Path

```text
1. Connector fetches DV360 report
   └─▶ Kafka: connector.data.raw
       └─▶ Bronze processes, writes Iceberg
           └─▶ Kafka: bronze.data.cleaned
               └─▶ Silver processes, writes Iceberg
                   └─▶ Kafka: silver.data.processed
                       └─▶ Gold processes, writes ClickHouse
                           └─▶ Kafka: gold.data.ready
                               ├─▶ Rule Engine evaluates
                               │   └─▶ Kafka: rules.alerts
                               │       └─▶ Notification Service
                               └─▶ Dashboard reflects new data
```

### Error Path

```text
1. Connector fails to fetch (rate limit)
   └─▶ Retry with backoff (1s, 2s, 4s)
       └─▶ Still failing after 3 attempts
           └─▶ Circuit breaker OPENS
               └─▶ Alert to ops team
                   └─▶ Serve stale data (last good fetch)
                       └─▶ UI shows "Data may be stale" banner
```

---

## Data Latency Budget

| Stage | Target | Max |
| ------- | -------- | ----- |
| DSP API to Bronze | 5 min | 15 min |
| Bronze to Silver | 5 min | 10 min |
| Silver to Gold | 5 min | 15 min |
| Gold to Dashboard | 1 min | 5 min |
| **End-to-End** | **16 min** | **45 min** |

---

## Backpressure Handling

When downstream can't keep up:

```text
┌─────────────────────────────────────────────────────────────────────────────┐
│                       BACKPRESSURE STRATEGY                                 │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  Producer (Connector)                                                       │
│       │                                                                     │
│       ▼                                                                     │
│  ┌─────────────────┐                                                        │
│  │  Kafka Topic    │  Consumer lag > threshold?                             │
│  │  (buffered)     │───────────────────────────┐                            │
│  └─────────────────┘                           │                            │
│       │                                        │                            │
│       │ Yes                                    │ No                         │
│       ▼                                        ▼                            │
│  ┌─────────────────┐                    ┌─────────────────┐                 │
│  │ Slow down       │                    │ Normal          │                 │
│  │ producers       │                    │ processing      │                 │
│  │ (rate limit)    │                    └─────────────────┘                 │
│  └─────────────────┘                                                        │
│       │                                                                     │
│       ▼                                                                     │
│  Still backed up?                                                           │
│       │                                                                     │
│       ▼                                                                     │
│  ┌─────────────────┐                                                        │
│  │ Scale consumers │                                                        │
│  │ horizontally    │                                                        │
│  └─────────────────┘                                                        │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Navigation

- **Previous:** [System Boundaries](system-boundaries.md)
- **Next:** [Technology Stack](tech-stack.md)
  