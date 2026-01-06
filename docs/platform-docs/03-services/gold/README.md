# Gold Service

> Business aggregations and metrics calculation.

---

## Service Overview

| Property | Value |
| ---------- | ------- |
| **Language** | Rust |
| **Framework** | Actix-web + DataFusion |
| **Storage** | ClickHouse |
| **Port** | 8007 |
| **gRPC Port** | 9007 |
| **Replicas** | 5 (scales with query load) |
| **Owner** | Data Team |

---

## Responsibilities

1. **Aggregations** - Daily, weekly, monthly rollups
2. **Joins** - Campaign + Booking + CRM data
3. **Calculated Metrics** - Pacing, margin, variance
4. **Materialized Views** - Pre-computed dashboards
5. **ClickHouse Write** - Optimized inserts

---

## Data Flow

```text
Kafka (silver.data.processed)
         │
         ▼
┌─────────────────────────────────────────┐
│            GOLD SERVICE                 │
├─────────────────────────────────────────┤
│  1. Read from Silver Iceberg            │
│  2. Join with booking data              │
│  3. Join with CRM data                  │
│  4. Calculate business metrics          │
│  5. Create aggregations                 │
│  6. Write to ClickHouse                 │
│  7. Refresh materialized views          │
│  8. Publish completion event            │
└─────────────────────────────────────────┘
         │
         ▼
ClickHouse (gold.campaign_metrics_daily)
         │
         ▼
Kafka (gold.data.ready)
```

---

## Calculated Metrics

### Pacing Rate

```sql
pacing_rate = (delivered / booked) * (total_days / elapsed_days) * 100

-- Example
delivered_impressions = 50,000
booked_impressions = 100,000
total_days = 30
elapsed_days = 15
pacing_rate = (50000 / 100000) * (30 / 15) * 100 = 100%
```

### Margin Percent

```sql
margin_percent = ((booking_revenue - actual_spend) / booking_revenue) * 100

-- Example
booking_revenue = $10,000
actual_spend = $7,500
margin_percent = ((10000 - 7500) / 10000) * 100 = 25%
```

### Projected Spend

```sql
projected_spend = (current_spend / elapsed_days) * total_days
```

---

## ClickHouse Tables

### campaign_metrics_daily

```sql
CREATE TABLE gold.campaign_metrics_daily (
    org_id UInt32,
    date Date,
    dsp_type LowCardinality(String),
    campaign_id String,
    campaign_name String,
    advertiser_id String,
    impressions UInt64,
    clicks UInt64,
    conversions UInt64,
    spend Decimal(18, 4),
    cpm Decimal(18, 4),
    ctr Decimal(10, 6),
    cvr Decimal(10, 6)
) ENGINE = MergeTree()
PARTITION BY (org_id, toYYYYMM(date))
ORDER BY (org_id, date, campaign_id)
TTL date + INTERVAL 2 YEAR;
```

### pacing_snapshots

```sql
CREATE TABLE gold.pacing_snapshots (
    org_id UInt32,
    snapshot_time DateTime,
    entity_type LowCardinality(String),
    entity_id String,
    booked_amount Decimal(18, 4),
    delivered_amount Decimal(18, 4),
    pacing_rate Decimal(10, 4),
    days_elapsed UInt16,
    days_remaining UInt16,
    projected_spend Decimal(18, 4),
    margin_percent Decimal(10, 4)
) ENGINE = MergeTree()
PARTITION BY (org_id, toYYYYMM(snapshot_time))
ORDER BY (org_id, snapshot_time, entity_type, entity_id);
```

---

## Materialized Views

### Daily Campaign Summary

```sql
CREATE MATERIALIZED VIEW gold.mv_daily_summary
ENGINE = SummingMergeTree()
PARTITION BY (org_id, toYYYYMM(date))
ORDER BY (org_id, date, dsp_type)
AS SELECT
    org_id,
    date,
    dsp_type,
    count(DISTINCT campaign_id) as campaign_count,
    sum(impressions) as total_impressions,
    sum(clicks) as total_clicks,
    sum(spend) as total_spend
FROM gold.campaign_metrics_daily
GROUP BY org_id, date, dsp_type;
```

---

## Configuration

```yaml
gold:
  clickhouse:
    host: "clickhouse-cluster"
    database: "gold"
    batch_size: 10000
    flush_interval: 5s
  aggregations:
    - daily
    - weekly
    - monthly
  retention:
    raw_days: 730
    aggregated_days: 1825
```

---

## Events Consumed

| Topic | Event |
| ------- | ------- |
| `silver.data.processed` | Data from Silver |

## Events Published

| Topic | Event |
| ------- | ------- |
| `gold.data.ready` | Data ready for consumption |

---

## Navigation

- **Up:** [Service Catalog](../README.md)
- **Previous:** [Silver Service](../silver/README.md)
- **Next:** [Calculation Service](../calculation/README.md)
