# Silver Service

> Data cleaning, validation, and normalization.

---

## Service Overview

| Property | Value |
| ---------- | ------- |
| **Language** | Rust |
| **Framework** | Actix-web + DataFusion |
| **Storage** | Apache Iceberg on S3 |
| **Port** | 8006 |
| **gRPC Port** | 9006 |
| **Replicas** | 5 (scales with data volume) |
| **Owner** | Data Team |

---

## Responsibilities

1. **Type Casting** - Convert to strong types
2. **Null Handling** - Apply default values
3. **Entity Deduplication** - Remove duplicate entities
4. **Quality Scoring** - Calculate data quality metrics
5. **Normalization** - Standardize across DSPs

---

## Data Flow

```text
Kafka (bronze.data.cleaned)
         │
         ▼
┌─────────────────────────────────────────┐
│           SILVER SERVICE                │
├─────────────────────────────────────────┤
│  1. Read from Bronze Iceberg            │
│  2. Apply type casting                  │
│  3. Handle nulls (defaults)             │
│  4. Deduplicate by entity_id + date     │
│  5. Calculate quality score             │
│  6. Write to Silver Iceberg             │
│  7. Publish to Kafka                    │
└─────────────────────────────────────────┘
         │
         ▼
Kafka (silver.data.processed)
         │
         ▼
Iceberg Table (silver.campaigns, silver.metrics)
```

---

## Transformations

| Field | Transformation |
| ------- | --------------- |
| impressions | Cast to BIGINT, default 0 |
| spend | Cast to DECIMAL(15,2), round 2 decimals |
| date | Parse to DATE, validate range |
| campaign_id | Normalize to string, trim whitespace |
| status | Map to enum (active/paused/completed) |

---

## Iceberg Tables

### silver.campaigns

```sql
CREATE TABLE silver.campaigns (
    org_id INT NOT NULL,
    dsp_type STRING NOT NULL,
    campaign_id STRING NOT NULL,
    campaign_name STRING,
    advertiser_id STRING,
    advertiser_name STRING,
    status STRING,
    budget_amount DECIMAL(18, 4),
    budget_currency STRING,
    start_date DATE,
    end_date DATE,
    created_at TIMESTAMP,
    updated_at TIMESTAMP,
    last_synced_at TIMESTAMP,
    quality_score DECIMAL(5, 2),
    quality_issues ARRAY<STRING>
)
USING ICEBERG
PARTITIONED BY (org_id, dsp_type);
```

### silver.campaign_metrics

```sql
CREATE TABLE silver.campaign_metrics (
    org_id INT NOT NULL,
    metric_date DATE NOT NULL,
    dsp_type STRING NOT NULL,
    campaign_id STRING NOT NULL,
    impressions BIGINT,
    clicks BIGINT,
    conversions BIGINT,
    spend_amount DECIMAL(18, 4),
    cpm DECIMAL(18, 4),
    ctr DECIMAL(10, 6),
    cvr DECIMAL(10, 6),
    data_quality_score DECIMAL(5, 2)
)
USING ICEBERG
PARTITIONED BY (org_id, months(metric_date), dsp_type)
ORDER BY (org_id, metric_date, campaign_id);
```

---

## Quality Scoring

```rust
fn calculate_quality_score(record: &Record) -> f64 {
    let mut score = 100.0;
    
    // Completeness (40%)
    let required_fields = ["campaign_id", "impressions", "spend"];
    let missing = required_fields.iter()
        .filter(|f| record.get(*f).is_none())
        .count();
    score -= (missing as f64 / required_fields.len() as f64) * 40.0;
    
    // Validity (30%)
    if record.get("impressions").map(|v| v < 0).unwrap_or(false) {
        score -= 15.0;
    }
    if record.get("spend").map(|v| v < 0).unwrap_or(false) {
        score -= 15.0;
    }
    
    // Consistency (20%)
    if record.get("ctr").map(|v| v > 1.0).unwrap_or(false) {
        score -= 20.0;
    }
    
    // Timeliness (10%)
    if record.age_hours() > 24 {
        score -= 10.0;
    }
    
    score.max(0.0)
}
```

---

## Quality Thresholds

| Score | Action |
| ------- | -------- |
| ≥ 90 | Include in Gold |
| 70-89 | Include with warning flag |
| < 70 | Quarantine for review |

---

## Configuration

```yaml
silver:
  iceberg:
    catalog: "glue"
    warehouse: "s3://data-lake/silver"
  quality:
    min_score: 70
    quarantine_threshold: 50
  deduplication:
    key_fields: ["org_id", "dsp_type", "entity_id", "date"]
  retention:
    days: 365
```

---

## Events Consumed

| Topic | Event |
| ------- | ------- |
| `bronze.data.cleaned` | Data from Bronze |

## Events Published

| Topic | Event |
| ------- | ------- |
| `silver.data.processed` | Data ready for Gold |
| `silver.quality.issues` | Quality issues detected |

---

## Navigation

- **Up:** [Service Catalog](../README.md)
- **Previous:** [Bronze Service](../bronze/README.md)
- **Next:** [Gold Service](../gold/README.md)
