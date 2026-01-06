CREATE TABLE IF NOT EXISTS campaign_metrics_daily (
    date Date,
    org_id String,
    campaign_id String,
    dsp_type LowCardinality(String),
    impressions UInt64,
    clicks UInt64,
    conversions UInt64,
    spend Decimal(15, 2),
    revenue Decimal(15, 2),
    ctr Float64,
    cpc Float64,
    cpa Float64,
    roas Float64
) ENGINE = SummingMergeTree()
PARTITION BY toYYYYMM(date)
ORDER BY (org_id, date, campaign_id)
TTL date + INTERVAL 365 DAY;
