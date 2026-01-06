-- =============================================================================
-- Campaign Lifecycle Platform - Complete ClickHouse Schema
-- =============================================================================
-- This file contains the complete ClickHouse schema for the Gold layer.
-- All tables are partitioned by org_id for tenant isolation.
-- =============================================================================

-- Create database
CREATE DATABASE IF NOT EXISTS gold;

-- =============================================================================
-- CAMPAIGN METRICS
-- =============================================================================

-- Daily campaign metrics (primary analytics table)
CREATE TABLE IF NOT EXISTS gold.campaign_metrics_daily
(
    org_id UInt32,
    date Date,
    dsp_type LowCardinality(String),  -- DV360, TTD, META, GOOGLE_ADS
    
    -- Entity hierarchy
    advertiser_id String,
    advertiser_name String,
    campaign_id String,
    campaign_name String,
    insertion_order_id Nullable(String),
    insertion_order_name Nullable(String),
    line_item_id Nullable(String),
    line_item_name Nullable(String),
    
    -- Status
    status LowCardinality(String),  -- active, paused, completed
    
    -- Performance metrics
    impressions UInt64 DEFAULT 0,
    clicks UInt64 DEFAULT 0,
    conversions UInt64 DEFAULT 0,
    video_views UInt64 DEFAULT 0,
    video_completions UInt64 DEFAULT 0,
    
    -- Cost metrics (in micros for precision)
    spend_micros Int64 DEFAULT 0,
    media_cost_micros Int64 DEFAULT 0,
    platform_fee_micros Int64 DEFAULT 0,
    
    -- Currency
    currency LowCardinality(String) DEFAULT 'USD',
    
    -- Computed metrics (denormalized for query performance)
    cpm Float64 DEFAULT 0,
    cpc Float64 DEFAULT 0,
    ctr Float64 DEFAULT 0,
    cvr Float64 DEFAULT 0,
    
    -- Budget info
    budget_micros Nullable(Int64),
    budget_type LowCardinality(Nullable(String)),  -- daily, lifetime, flight
    
    -- Pacing info
    days_elapsed UInt16 DEFAULT 0,
    days_remaining UInt16 DEFAULT 0,
    pacing_rate Float64 DEFAULT 0,
    projected_spend_micros Nullable(Int64),
    
    -- Metadata
    updated_at DateTime64(3) DEFAULT now64(3),
    ingestion_id String,  -- For deduplication
    
    -- Indexes
    INDEX idx_campaign_name campaign_name TYPE tokenbf_v1(32768, 3, 0) GRANULARITY 4,
    INDEX idx_advertiser_name advertiser_name TYPE tokenbf_v1(32768, 3, 0) GRANULARITY 4
)
ENGINE = ReplacingMergeTree(updated_at)
PARTITION BY (org_id, toYYYYMM(date))
ORDER BY (org_id, date, dsp_type, campaign_id, insertion_order_id, line_item_id)
TTL date + INTERVAL 2 YEAR
SETTINGS index_granularity = 8192;

-- =============================================================================
-- PACING & MARGIN METRICS
-- =============================================================================

-- Pacing summary (joined with booking data)
CREATE TABLE IF NOT EXISTS gold.pacing_summary
(
    org_id UInt32,
    date Date,
    
    -- Campaign reference
    dsp_type LowCardinality(String),
    campaign_id String,
    campaign_name String,
    
    -- Deal reference (from booking)
    deal_id Nullable(String),
    deal_external_id Nullable(String),
    client_name Nullable(String),
    
    -- Flight dates
    flight_start_date Date,
    flight_end_date Date,
    
    -- Budget
    booked_amount_micros Int64 DEFAULT 0,
    budget_micros Int64 DEFAULT 0,
    currency LowCardinality(String) DEFAULT 'USD',
    
    -- Delivery
    delivered_amount_micros Int64 DEFAULT 0,
    delivered_impressions UInt64 DEFAULT 0,
    
    -- Pacing calculations
    total_days UInt16 DEFAULT 0,
    days_elapsed UInt16 DEFAULT 0,
    days_remaining UInt16 DEFAULT 0,
    expected_delivery_micros Int64 DEFAULT 0,
    pacing_rate Float64 DEFAULT 0,  -- actual/expected * 100
    pacing_status LowCardinality(String) DEFAULT 'unknown',  -- on_track, under, over, critical_under, critical_over
    projected_delivery_micros Int64 DEFAULT 0,
    
    -- Variance
    variance_micros Int64 DEFAULT 0,
    variance_percent Float64 DEFAULT 0,
    
    -- Margin (if booking data available)
    margin_amount_micros Nullable(Int64),
    margin_percent Nullable(Float64),
    
    -- Metadata
    updated_at DateTime64(3) DEFAULT now64(3),
    deal_matched Boolean DEFAULT false,
    match_confidence Nullable(Float32)  -- Fuzzy match confidence
)
ENGINE = ReplacingMergeTree(updated_at)
PARTITION BY (org_id, toYYYYMM(date))
ORDER BY (org_id, date, campaign_id)
TTL date + INTERVAL 1 YEAR;

-- =============================================================================
-- AGGREGATED VIEWS (Materialized)
-- =============================================================================

-- Campaign summary by date (faster dashboard queries)
CREATE MATERIALIZED VIEW IF NOT EXISTS gold.campaign_summary_by_date_mv
ENGINE = SummingMergeTree()
PARTITION BY (org_id, toYYYYMM(date))
ORDER BY (org_id, date, dsp_type)
AS SELECT
    org_id,
    date,
    dsp_type,
    count() AS campaign_count,
    sum(impressions) AS total_impressions,
    sum(clicks) AS total_clicks,
    sum(conversions) AS total_conversions,
    sum(spend_micros) AS total_spend_micros,
    avg(ctr) AS avg_ctr,
    avg(pacing_rate) AS avg_pacing_rate
FROM gold.campaign_metrics_daily
GROUP BY org_id, date, dsp_type;

-- Advertiser performance summary
CREATE MATERIALIZED VIEW IF NOT EXISTS gold.advertiser_summary_mv
ENGINE = SummingMergeTree()
PARTITION BY (org_id, toYYYYMM(date))
ORDER BY (org_id, date, advertiser_id)
AS SELECT
    org_id,
    date,
    dsp_type,
    advertiser_id,
    any(advertiser_name) AS advertiser_name,
    count() AS campaign_count,
    sum(impressions) AS total_impressions,
    sum(clicks) AS total_clicks,
    sum(conversions) AS total_conversions,
    sum(spend_micros) AS total_spend_micros
FROM gold.campaign_metrics_daily
GROUP BY org_id, date, dsp_type, advertiser_id;

-- =============================================================================
-- RULE EVALUATIONS & ALERTS
-- =============================================================================

-- Rule evaluation history
CREATE TABLE IF NOT EXISTS gold.rule_evaluations
(
    org_id UInt32,
    timestamp DateTime64(3),
    evaluation_id String,
    
    -- Rule info
    rule_id String,
    rule_name String,
    module LowCardinality(String),
    
    -- Entity evaluated
    entity_type LowCardinality(String),
    entity_id String,
    entity_name String,
    
    -- Results
    matched UInt8,  -- 0 or 1
    condition_results Array(Tuple(
        condition String,
        field String,
        operator String,
        expected String,
        actual String,
        matched UInt8
    )),
    
    -- Actions taken
    actions_executed Array(String),
    
    -- Performance
    evaluation_time_us UInt32
)
ENGINE = MergeTree()
PARTITION BY (org_id, toYYYYMM(timestamp))
ORDER BY (org_id, timestamp, rule_id)
TTL timestamp + INTERVAL 90 DAY;

-- Alert history
CREATE TABLE IF NOT EXISTS gold.alert_history
(
    org_id UInt32,
    alert_id String,
    timestamp DateTime64(3),
    
    -- Rule info
    rule_id String,
    rule_name String,
    module LowCardinality(String),
    severity LowCardinality(String),
    
    -- Entity
    entity_type LowCardinality(String),
    entity_id String,
    entity_name String,
    
    -- Alert details
    message String,
    condition_summary String,
    data_snapshot Map(String, String),
    
    -- Notification
    channels Array(LowCardinality(String)),
    recipients Array(String),
    
    -- Resolution
    acknowledged UInt8 DEFAULT 0,
    acknowledged_by Nullable(UInt32),
    acknowledged_at Nullable(DateTime64(3)),
    resolution_notes Nullable(String)
)
ENGINE = ReplacingMergeTree(timestamp)
PARTITION BY (org_id, toYYYYMM(timestamp))
ORDER BY (org_id, timestamp, alert_id)
TTL timestamp + INTERVAL 1 YEAR;

-- =============================================================================
-- DATA QUALITY METRICS
-- =============================================================================

-- Pipeline execution metrics
CREATE TABLE IF NOT EXISTS gold.pipeline_metrics
(
    org_id UInt32,
    timestamp DateTime64(3),
    
    -- Pipeline info
    pipeline_id String,
    pipeline_name String,
    execution_id String,
    connector_type LowCardinality(String),
    
    -- Status
    status LowCardinality(String),  -- completed, failed, partial
    
    -- Records
    input_records UInt64 DEFAULT 0,
    output_records UInt64 DEFAULT 0,
    filtered_records UInt64 DEFAULT 0,
    error_records UInt64 DEFAULT 0,
    
    -- Quality
    quality_score Float32 DEFAULT 0,
    
    -- Timing
    duration_ms UInt64 DEFAULT 0,
    bronze_duration_ms UInt64 DEFAULT 0,
    silver_duration_ms UInt64 DEFAULT 0,
    gold_duration_ms UInt64 DEFAULT 0,
    
    -- Size
    input_size_bytes UInt64 DEFAULT 0,
    output_size_bytes UInt64 DEFAULT 0
)
ENGINE = MergeTree()
PARTITION BY (org_id, toYYYYMM(timestamp))
ORDER BY (org_id, timestamp, pipeline_id)
TTL timestamp + INTERVAL 90 DAY;

-- Data freshness tracking
CREATE TABLE IF NOT EXISTS gold.data_freshness
(
    org_id UInt32,
    timestamp DateTime64(3),
    
    dsp_type LowCardinality(String),
    account_id String,
    
    last_data_date Date,
    freshness_hours Float32,  -- Hours since last data
    is_stale UInt8,  -- 1 if older than threshold
    
    -- Thresholds
    expected_freshness_hours Float32 DEFAULT 24,
    
    updated_at DateTime64(3) DEFAULT now64(3)
)
ENGINE = ReplacingMergeTree(updated_at)
PARTITION BY (org_id)
ORDER BY (org_id, dsp_type, account_id);

-- =============================================================================
-- COST TRACKING
-- =============================================================================

-- Platform cost tracking
CREATE TABLE IF NOT EXISTS gold.platform_costs
(
    org_id UInt32,
    date Date,
    
    -- Usage metrics
    api_calls UInt64 DEFAULT 0,
    data_ingested_bytes UInt64 DEFAULT 0,
    storage_bytes UInt64 DEFAULT 0,
    query_count UInt64 DEFAULT 0,
    
    -- Computed costs (in micros)
    compute_cost_micros Int64 DEFAULT 0,
    storage_cost_micros Int64 DEFAULT 0,
    egress_cost_micros Int64 DEFAULT 0,
    total_cost_micros Int64 DEFAULT 0,
    
    -- Tier info
    tier LowCardinality(String) DEFAULT 'free',
    included_in_tier UInt8 DEFAULT 0,
    
    updated_at DateTime64(3) DEFAULT now64(3)
)
ENGINE = ReplacingMergeTree(updated_at)
PARTITION BY (org_id, toYYYYMM(date))
ORDER BY (org_id, date)
TTL date + INTERVAL 2 YEAR;

-- =============================================================================
-- TAXONOMY & QA
-- =============================================================================

-- Taxonomy validation results
CREATE TABLE IF NOT EXISTS gold.taxonomy_validations
(
    org_id UInt32,
    timestamp DateTime64(3),
    
    -- Entity
    entity_type LowCardinality(String),
    entity_id String,
    entity_name String,
    
    -- Validation
    pattern_id String,
    pattern_name String,
    valid UInt8,
    
    -- Results
    expected_pattern String,
    actual_value String,
    extracted_values Map(String, String),
    errors Array(String),
    
    -- Suggested fix
    suggested_value Nullable(String)
)
ENGINE = MergeTree()
PARTITION BY (org_id, toYYYYMM(timestamp))
ORDER BY (org_id, timestamp, entity_type, entity_id)
TTL timestamp + INTERVAL 90 DAY;

-- QA check results
CREATE TABLE IF NOT EXISTS gold.qa_checks
(
    org_id UInt32,
    timestamp DateTime64(3),
    check_run_id String,
    
    -- Entity
    entity_type LowCardinality(String),
    entity_id String,
    entity_name String,
    
    -- Check
    check_id String,
    check_name String,
    check_category LowCardinality(String),  -- setup, targeting, budget, creative
    severity LowCardinality(String),
    
    -- Result
    passed UInt8,
    message String,
    details Map(String, String),
    
    -- Auto-fix
    auto_fixable UInt8 DEFAULT 0,
    auto_fixed UInt8 DEFAULT 0
)
ENGINE = MergeTree()
PARTITION BY (org_id, toYYYYMM(timestamp))
ORDER BY (org_id, timestamp, check_run_id)
TTL timestamp + INTERVAL 90 DAY;

-- =============================================================================
-- USER ACTIVITY (for analytics)
-- =============================================================================

CREATE TABLE IF NOT EXISTS gold.user_activity
(
    org_id UInt32,
    timestamp DateTime64(3),
    user_id UInt32,
    
    action LowCardinality(String),
    entity_type LowCardinality(String),
    entity_id Nullable(String),
    
    -- Session
    session_id String,
    
    -- Context
    ip_country LowCardinality(Nullable(String)),
    device_type LowCardinality(Nullable(String)),
    
    -- Request
    duration_ms UInt32 DEFAULT 0
)
ENGINE = MergeTree()
PARTITION BY (org_id, toYYYYMM(timestamp))
ORDER BY (org_id, timestamp, user_id)
TTL timestamp + INTERVAL 90 DAY;

-- =============================================================================
-- DICTIONARY FOR FAST LOOKUPS
-- =============================================================================

-- Organization settings dictionary (for fast lookups in queries)
CREATE DICTIONARY IF NOT EXISTS gold.org_settings_dict
(
    org_id UInt32,
    name String,
    timezone String,
    currency String,
    is_premium UInt8
)
PRIMARY KEY org_id
SOURCE(POSTGRESQL(
    port 5432
    host 'postgres'
    user 'platform'
    password 'password'
    db 'platform'
    table 'organizations'
))
LAYOUT(HASHED())
LIFETIME(MIN 60 MAX 120);
