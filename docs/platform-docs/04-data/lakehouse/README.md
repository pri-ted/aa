# Iceberg Lakehouse Design

> Bronze/Silver/Gold data layer architecture.

---

## Lakehouse Architecture

```text
┌─────────────────────────────────────────────────────────────────────────────┐
│                         ICEBERG LAKEHOUSE                                   │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│   ┌─────────────────────────────────────────────────────────────────────┐   │
│   │                        BRONZE LAYER (RAW)                           │   │
│   │                                                                     │   │
│   │  Purpose: Store raw data exactly as received                        │   │
│   │  Schema: Schema-on-read (flexible)                                   │   │
│   │  Storage: Apache Iceberg on S3/GCS                                  │   │
│   │  Retention: 90 days                                                 │   │
│   │                                                                     │   │
│   │  Tables:                                                            │   │
│   │  • bronze.dv360_reports                                             │   │
│   │  • bronze.ttd_reports                                               │   │
│   │  • bronze.meta_reports                                              │   │
│   │  • bronze.crm_data                                                  │   │
│   └─────────────────────────────────────────────────────────────────────┘   │
│                                   │                                         │
│                                   ▼                                         │
│   ┌─────────────────────────────────────────────────────────────────────┐   │
│   │                       SILVER LAYER (CLEANED)                        │   │
│   │                                                                     │   │
│   │  Purpose: Cleaned, validated, normalized data                       │   │
│   │  Schema: Enforced schema with types                                 │   │
│   │  Storage: Apache Iceberg on S3/GCS                                  │   │
│   │  Retention: 1 year                                                  │   │
│   │                                                                     │   │
│   │  Tables:                                                            │   │
│   │  • silver.campaigns                                                 │   │
│   │  • silver.campaign_metrics                                          │   │
│   │  • silver.bookings                                                  │   │
│   └─────────────────────────────────────────────────────────────────────┘   │
│                                   │                                         │
│                                   ▼                                         │
│   ┌─────────────────────────────────────────────────────────────────────┐   │
│   │                        GOLD LAYER (BUSINESS)                        │   │
│   │                                                                     │   │
│   │  Purpose: Business-ready aggregations and metrics                   │   │
│   │  Schema: Optimized for queries                                      │   │
│   │  Storage: ClickHouse (active) + Iceberg (historical)                │   │
│   │  Retention: 2 years                                                 │   │
│   │                                                                     │   │
│   │  Views:                                                             │   │
│   │  • gold.campaign_performance                                        │   │
│   │  • gold.pacing_analysis                                             │   │
│   │  • gold.margin_summary                                              │   │
│   └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Bronze Layer Tables

### bronze.dv360_reports

```sql
CREATE TABLE bronze.dv360_reports (
    -- Metadata
    org_id INT NOT NULL,
    ingestion_time TIMESTAMP NOT NULL,
    request_id STRING NOT NULL,
    
    -- Raw data
    report_type STRING,
    report_date DATE,
    raw_json STRING,
    
    -- Quality
    file_size_bytes BIGINT,
    record_count INT
)
USING ICEBERG
PARTITIONED BY (org_id, days(report_date))
TBLPROPERTIES (
    'write.format.default' = 'parquet',
    'write.parquet.compression-codec' = 'zstd',
    'write.metadata.delete-after-commit.enabled' = 'true',
    'history.expire.max-snapshot-age-ms' = '604800000'
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

### bronze.crm_data

```sql
CREATE TABLE bronze.crm_data (
    org_id INT NOT NULL,
    ingestion_time TIMESTAMP NOT NULL,
    source_type STRING, -- 'google_sheets', 'booking_db'
    source_id STRING,
    raw_json STRING,
    record_count INT
)
USING ICEBERG
PARTITIONED BY (org_id, days(ingestion_time));
```

---

## Silver Layer Tables

### silver.campaigns

```sql
CREATE TABLE silver.campaigns (
    -- Keys
    org_id INT NOT NULL,
    dsp_type STRING NOT NULL,
    campaign_id STRING NOT NULL,
    
    -- Attributes
    campaign_name STRING,
    advertiser_id STRING,
    advertiser_name STRING,
    status STRING,
    
    -- Budget
    budget_amount DECIMAL(18, 4),
    budget_currency STRING,
    budget_type STRING, -- 'lifetime', 'daily'
    
    -- Dates
    start_date DATE,
    end_date DATE,
    
    -- Metadata
    created_at TIMESTAMP,
    updated_at TIMESTAMP,
    last_synced_at TIMESTAMP,
    
    -- Quality
    quality_score DECIMAL(5, 2),
    quality_issues ARRAY<STRING>
)
USING ICEBERG
PARTITIONED BY (org_id, dsp_type);
```

### silver.campaign_metrics

```sql
CREATE TABLE silver.campaign_metrics (
    -- Keys
    org_id INT NOT NULL,
    metric_date DATE NOT NULL,
    dsp_type STRING NOT NULL,
    campaign_id STRING NOT NULL,
    
    -- Metrics
    impressions BIGINT,
    clicks BIGINT,
    conversions BIGINT,
    video_views BIGINT,
    video_completions BIGINT,
    
    -- Spend
    spend_amount DECIMAL(18, 4),
    spend_currency STRING,
    
    -- Calculated
    cpm DECIMAL(18, 4),
    cpc DECIMAL(18, 4),
    ctr DECIMAL(10, 6),
    cvr DECIMAL(10, 6),
    vcr DECIMAL(10, 6),
    
    -- Quality
    data_quality_score DECIMAL(5, 2)
)
USING ICEBERG
PARTITIONED BY (org_id, months(metric_date), dsp_type)
ORDER BY (org_id, metric_date, campaign_id);
```

### silver.bookings

```sql
CREATE TABLE silver.bookings (
    -- Keys
    org_id INT NOT NULL,
    booking_id STRING NOT NULL,
    
    -- Attributes
    client_name STRING,
    campaign_name STRING,
    deal_id STRING,
    
    -- Financial
    booked_revenue DECIMAL(18, 4),
    currency STRING,
    
    -- Delivery
    booked_impressions BIGINT,
    booked_spend DECIMAL(18, 4),
    buy_model STRING, -- 'CPM', 'CPC', 'CPCV'
    rate DECIMAL(18, 4),
    
    -- Dates
    flight_start DATE,
    flight_end DATE,
    
    -- Mapping
    dsp_type STRING,
    dsp_campaign_id STRING,
    dsp_io_id STRING,
    dsp_line_item_id STRING,
    
    -- Metadata
    source_type STRING,
    last_updated_at TIMESTAMP
)
USING ICEBERG
PARTITIONED BY (org_id, years(flight_start));
```

---

## Gold Layer Views

### gold.campaign_performance

```sql
-- Materialized in ClickHouse for fast queries
CREATE TABLE gold.campaign_performance (
    org_id UInt32,
    date Date,
    dsp_type LowCardinality(String),
    campaign_id String,
    campaign_name String,
    
    -- From silver.campaign_metrics
    impressions UInt64,
    clicks UInt64,
    conversions UInt64,
    spend Decimal(18, 4),
    
    -- From silver.bookings (joined)
    booked_impressions UInt64,
    booked_revenue Decimal(18, 4),
    
    -- Calculated
    pacing_rate Decimal(10, 4),
    margin_amount Decimal(18, 4),
    margin_percent Decimal(10, 4)
) ENGINE = MergeTree()
PARTITION BY (org_id, toYYYYMM(date))
ORDER BY (org_id, date, campaign_id);
```

### gold.pacing_analysis

```sql
CREATE TABLE gold.pacing_analysis (
    org_id UInt32,
    snapshot_date Date,
    entity_type LowCardinality(String),
    entity_id String,
    entity_name String,
    
    -- Progress
    total_days UInt16,
    elapsed_days UInt16,
    remaining_days UInt16,
    
    -- Delivery
    booked_amount Decimal(18, 4),
    delivered_amount Decimal(18, 4),
    remaining_amount Decimal(18, 4),
    
    -- Pacing
    expected_delivery_percent Decimal(10, 4),
    actual_delivery_percent Decimal(10, 4),
    pacing_rate Decimal(10, 4),
    pacing_status LowCardinality(String), -- 'on_track', 'under', 'over'
    
    -- Projection
    projected_end_delivery Decimal(18, 4),
    projected_variance Decimal(18, 4)
) ENGINE = MergeTree()
PARTITION BY (org_id, toYYYYMM(snapshot_date))
ORDER BY (org_id, snapshot_date, entity_type, entity_id);
```

---

## Partitioning Strategy

### By Organization

All tables include `org_id` as first partition key for:

- Tenant isolation (queries never cross orgs)
- Partition pruning (fast queries)
- Data lifecycle management (per-org retention)

### By Time

Second partition key is time-based:

| Layer | Partition | Reason |
| ------- | ----------- | -------- |
| Bronze | `days(date)` | Fine-grained for recent data |
| Silver | `months(date)` | Balanced for historical queries |
| Gold | `months(date)` | Aggregated data, longer retention |

---

## Schema Evolution

### Supported Changes

- Add optional columns
- Widen column types (INT → BIGINT)
- Rename columns (with mapping)
- Add/drop partitions

### Example: Adding Column

```sql
ALTER TABLE silver.campaign_metrics
ADD COLUMN video_quartile_25 BIGINT;
```

### Backward Compatibility

- Old queries continue to work
- New column returns NULL for old data
- No data rewrite required

---

## Time Travel Queries

### Query Historical Data

```sql
-- Query data as of specific timestamp
SELECT * FROM silver.campaigns
TIMESTAMP AS OF '2024-12-01 00:00:00';

-- Query data as of specific snapshot
SELECT * FROM silver.campaigns
VERSION AS OF 1234567890;
```

### Rollback Table

```sql
-- Rollback to previous snapshot
CALL system.rollback_to_snapshot('silver.campaigns', 1234567890);
```

---

## Data Quality

### Quality Scoring

Each record gets quality score (0-100):

```text
Score Components:
- Completeness (required fields present): 40%
- Validity (values in expected ranges): 30%
- Consistency (cross-field validation): 20%
- Timeliness (data freshness): 10%
```

### Quality Thresholds

| Threshold | Action |
| ----------- | -------- |
| ≥ 90 | Include in Gold |
| 70-89 | Include with warning |
| < 70 | Quarantine for review |

---

## Navigation

- **Previous:** [API Specifications](../apis/README.md)
- **Up:** [Data Architecture](README.md)
