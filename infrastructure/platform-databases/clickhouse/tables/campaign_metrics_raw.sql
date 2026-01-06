CREATE TABLE IF NOT EXISTS campaign_metrics_raw (
    timestamp DateTime,
    org_id String,
    campaign_id String,
    dsp_type LowCardinality(String),
    impressions UInt64,
    clicks UInt64,
    conversions UInt64,
    spend Decimal(15, 2),
    revenue Decimal(15, 2),
    metadata String
) ENGINE = MergeTree()
PARTITION BY toYYYYMM(timestamp)
ORDER BY (org_id, campaign_id, timestamp)
TTL timestamp + INTERVAL 90 DAY;
