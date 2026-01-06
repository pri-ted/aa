# Bronze Service

> Raw data ingestion and schema-on-read storage.

---

## Service Overview

| Property | Value |
| ---------- | ------- |
| **Language** | Rust |
| **Framework** | Actix-web + Tokio |
| **Storage** | Apache Iceberg on S3 |
| **Port** | 8005 |
| **gRPC Port** | 9005 |
| **Replicas** | 5 (scales with data volume) |
| **Owner** | Data Team |

---

## Responsibilities

1. **Raw Data Ingestion** - Store data exactly as received
2. **Schema-on-Read** - Flexible schema handling
3. **Request Deduplication** - Prevent duplicate ingests
4. **Partitioning** - By org_id and date
5. **Data Lineage** - Track source and transformations

---

## Data Flow

```text
Kafka (connector.data.raw)
         │
         ▼
┌─────────────────────────────────────────┐
│           BRONZE SERVICE                │
├─────────────────────────────────────────┤
│  1. Parse raw JSON                      │
│  2. Validate request_id (dedupe)        │
│  3. Apply schema-on-read                │
│  4. Write to Iceberg                    │
│  5. Publish to Kafka                    │
└─────────────────────────────────────────┘
         │
         ▼
Kafka (bronze.data.cleaned)
         │
         ▼
Iceberg Table (bronze.{dsp}_reports)
```

---

## Iceberg Tables

### bronze.dv360_reports

```sql
CREATE TABLE bronze.dv360_reports (
    org_id INT NOT NULL,
    ingestion_time TIMESTAMP NOT NULL,
    request_id STRING NOT NULL,
    report_type STRING,
    report_date DATE,
    raw_json STRING,
    file_size_bytes BIGINT,
    record_count INT
)
USING ICEBERG
PARTITIONED BY (org_id, days(report_date))
TBLPROPERTIES (
    'write.format.default' = 'parquet',
    'write.parquet.compression-codec' = 'zstd'
);
```

### bronze.ttd_reports

```sql
CREATE TABLE bronze.ttd_reports (
    org_id INT NOT NULL,
    ingestion_time TIMESTAMP NOT NULL,
    request_id STRING NOT NULL,
    template_id STRING,
    report_date DATE,
    raw_json STRING,
    record_count INT
)
USING ICEBERG
PARTITIONED BY (org_id, days(report_date));
```

---

## Deduplication

```rust
async fn should_process(request_id: &str) -> bool {
    // Check Redis for recent request IDs
    let key = format!("bronze:dedupe:{}", request_id);
    let exists = redis.exists(&key).await?;
    
    if exists {
        return false; // Already processed
    }
    
    // Mark as processing with 24h TTL
    redis.set_ex(&key, "1", 86400).await?;
    true
}
```

---

## Configuration

```yaml
bronze:
  iceberg:
    catalog: "glue"
    warehouse: "s3://data-lake/bronze"
  partitioning:
    strategy: "org_id,date"
  retention:
    days: 90
  deduplication:
    window: 24h
    redis_ttl: 86400
```

---

## Events Consumed

| Topic | Event |
| ------- | ------- |
| `connector.data.raw` | Raw data from connectors |

## Events Published

| Topic | Event |
| ------- | ------- |
| `bronze.data.cleaned` | Data ready for Silver |

---

## Navigation

- **Up:** [Service Catalog](../README.md)
- **Previous:** [ETL Service](../etl/README.md)
- **Next:** [Silver Service](../silver/README.md)
  