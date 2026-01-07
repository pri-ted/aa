-- ============================================================================
-- Campaign Lifecycle Platform - Complete PostgreSQL Schema
-- Version: 1.0.0
-- Date: 2026-01-07
-- Description: Production-ready schema with multi-tenant support
--              Supports all 12 microservices and Phase 1 business modules
-- ============================================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";  -- For text search

-- ============================================================================
-- ENUMS
-- ============================================================================

CREATE TYPE user_role AS ENUM ('admin', 'developer', 'viewer', 'analyst');
CREATE TYPE org_status AS ENUM ('active', 'suspended', 'trial', 'deleted');
CREATE TYPE dsp_type AS ENUM ('dv360', 'ttd', 'meta', 'amazon', 'google_ads');
CREATE TYPE entity_type AS ENUM ('campaign', 'insertion_order', 'line_item', 'creative', 'template', 'pipeline', 'rule', 'dsp_account');
CREATE TYPE pipeline_status AS ENUM ('active', 'paused', 'failed', 'draft');
CREATE TYPE execution_status AS ENUM ('pending', 'running', 'completed', 'failed', 'cancelled');
CREATE TYPE notification_type AS ENUM ('email', 'slack', 'webhook', 'sms', 'push', 'in_app');
CREATE TYPE rule_module AS ENUM ('alerts', 'qa', 'taxonomy', 'pacing', 'margin');

-- ============================================================================
-- TABLE 1: organizations (Tenant Root)
-- ============================================================================

CREATE TABLE organizations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    slug VARCHAR(100) UNIQUE NOT NULL,
    domain VARCHAR(255),
    status org_status NOT NULL DEFAULT 'trial',
    
    -- Settings
    settings JSONB DEFAULT '{}'::jsonb,
    
    -- Billing & Limits
    plan VARCHAR(50) DEFAULT 'free',
    monthly_budget DECIMAL(15,2),
    api_rate_limit INT DEFAULT 1000,
    
    -- Metadata
    industry VARCHAR(100),
    company_size VARCHAR(50),
    
    -- Timestamps
    trial_ends_at TIMESTAMP,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP,
    
    -- Constraints
    CONSTRAINT organizations_slug_format CHECK (slug ~ '^[a-z0-9-]+$'),
    CONSTRAINT organizations_valid_status CHECK (deleted_at IS NULL OR status = 'deleted')
);

CREATE INDEX idx_organizations_slug ON organizations(slug) WHERE deleted_at IS NULL;
CREATE INDEX idx_organizations_status ON organizations(status) WHERE deleted_at IS NULL;
CREATE INDEX idx_organizations_domain ON organizations(domain) WHERE domain IS NOT NULL;
CREATE INDEX idx_organizations_created_at ON organizations(created_at);
CREATE INDEX idx_organizations_settings ON organizations USING gin(settings);

COMMENT ON TABLE organizations IS 'Tenant organizations - root of all multi-tenant data';
COMMENT ON COLUMN organizations.slug IS 'URL-safe unique identifier for organization';
COMMENT ON COLUMN organizations.settings IS 'Organization-level configuration (timezone, locale, features)';

-- ============================================================================
-- TABLE 2: users (User Accounts)
-- ============================================================================

CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255),
    name VARCHAR(255) NOT NULL,
    
    -- Auth
    auth_provider VARCHAR(50) NOT NULL DEFAULT 'local',
    auth_provider_id VARCHAR(255),
    is_active BOOLEAN NOT NULL DEFAULT true,
    email_verified BOOLEAN NOT NULL DEFAULT false,
    mfa_enabled BOOLEAN NOT NULL DEFAULT false,
    mfa_secret VARCHAR(255),
    
    -- Activity
    last_login_at TIMESTAMP,
    last_activity_at TIMESTAMP,
    login_count INT DEFAULT 0,
    
    -- Metadata
    avatar_url TEXT,
    timezone VARCHAR(50) DEFAULT 'UTC',
    locale VARCHAR(10) DEFAULT 'en-US',
    metadata JSONB DEFAULT '{}'::jsonb,
    
    -- Timestamps
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP,
    
    -- Constraints
    CONSTRAINT users_email_format CHECK (email ~ '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'),
    CONSTRAINT users_auth_provider CHECK (
        (auth_provider = 'local' AND password_hash IS NOT NULL) OR
        (auth_provider != 'local' AND auth_provider_id IS NOT NULL)
    )
);

CREATE INDEX idx_users_email ON users(email) WHERE deleted_at IS NULL;
CREATE INDEX idx_users_active ON users(is_active) WHERE deleted_at IS NULL;
CREATE INDEX idx_users_last_login ON users(last_login_at DESC);
CREATE INDEX idx_users_auth_provider ON users(auth_provider, auth_provider_id);

COMMENT ON TABLE users IS 'User accounts - users can belong to multiple organizations';
COMMENT ON COLUMN users.auth_provider IS 'Authentication provider: local, google, github, azure';

-- ============================================================================
-- TABLE 3: org_memberships (Organization Access)
-- ============================================================================

CREATE TABLE org_memberships (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    org_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    role user_role NOT NULL,
    
    -- Permissions override (optional)
    permissions JSONB DEFAULT '{}'::jsonb,
    
    -- Status
    is_active BOOLEAN NOT NULL DEFAULT true,
    invited_by UUID REFERENCES users(id),
    
    -- Timestamps
    joined_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    -- Constraints
    UNIQUE(org_id, user_id)
);

CREATE INDEX idx_org_memberships_org ON org_memberships(org_id);
CREATE INDEX idx_org_memberships_user ON org_memberships(user_id);
CREATE INDEX idx_org_memberships_role ON org_memberships(role);
CREATE INDEX idx_org_memberships_active ON org_memberships(org_id, user_id) WHERE is_active = true;

COMMENT ON TABLE org_memberships IS 'User membership in organizations with RBAC roles';

-- ============================================================================
-- TABLE 4: auth_tokens (Sessions & API Keys)
-- ============================================================================

CREATE TABLE auth_tokens (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    org_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    
    -- Token data
    token_type VARCHAR(50) NOT NULL CHECK (token_type IN ('access', 'refresh', 'api_key')),
    token_hash VARCHAR(255) UNIQUE NOT NULL,
    token_prefix VARCHAR(20),
    
    -- Scopes & permissions
    scopes JSONB DEFAULT '[]'::jsonb,
    
    -- Metadata
    name VARCHAR(255),  -- For API keys
    user_agent TEXT,
    ip_address INET,
    
    -- Expiration
    expires_at TIMESTAMP NOT NULL,
    last_used_at TIMESTAMP,
    
    -- Status
    is_active BOOLEAN NOT NULL DEFAULT true,
    revoked_at TIMESTAMP,
    revoked_by UUID REFERENCES users(id),
    
    -- Timestamps
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    -- Constraints
    CONSTRAINT auth_tokens_expires_future CHECK (expires_at > created_at),
    CONSTRAINT auth_tokens_revoked_inactive CHECK (revoked_at IS NULL OR is_active = false)
);

CREATE INDEX idx_auth_tokens_token_hash ON auth_tokens(token_hash) WHERE is_active = true;
CREATE INDEX idx_auth_tokens_user ON auth_tokens(user_id);
CREATE INDEX idx_auth_tokens_org ON auth_tokens(org_id);
CREATE INDEX idx_auth_tokens_expires ON auth_tokens(expires_at) WHERE is_active = true;
CREATE INDEX idx_auth_tokens_type ON auth_tokens(token_type);

-- Auto-cleanup expired tokens
CREATE INDEX idx_auth_tokens_expired ON auth_tokens(expires_at) 
    WHERE expires_at < CURRENT_TIMESTAMP AND is_active = true;

COMMENT ON TABLE auth_tokens IS 'Access tokens, refresh tokens, and API keys';

-- ============================================================================
-- TABLE 5: dsp_accounts (DSP Integrations)
-- ============================================================================

CREATE TABLE dsp_accounts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    org_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    
    -- DSP Details
    dsp_type dsp_type NOT NULL,
    external_account_id VARCHAR(255) NOT NULL,
    display_name VARCHAR(255) NOT NULL,
    
    -- Credentials (encrypted)
    oauth_token_path VARCHAR(500),  -- Path in Vault
    credentials_encrypted BYTEA,
    token_expires_at TIMESTAMP,
    
    -- Rate Limiting
    rate_limit_config JSONB DEFAULT '{
        "requests_per_minute": 60,
        "requests_per_hour": 3000,
        "requests_per_day": 50000
    }'::jsonb,
    
    -- Sync Status
    is_active BOOLEAN NOT NULL DEFAULT true,
    last_sync_at TIMESTAMP,
    last_sync_status VARCHAR(50),
    sync_error TEXT,
    
    -- Metadata
    parent_account_id VARCHAR(255),
    account_timezone VARCHAR(50),
    currency VARCHAR(3) DEFAULT 'USD',
    metadata JSONB DEFAULT '{}'::jsonb,
    
    -- Timestamps
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    -- Constraints
    UNIQUE(org_id, dsp_type, external_account_id)
);

CREATE INDEX idx_dsp_accounts_org ON dsp_accounts(org_id);
CREATE INDEX idx_dsp_accounts_type ON dsp_accounts(dsp_type);
CREATE INDEX idx_dsp_accounts_external ON dsp_accounts(external_account_id);
CREATE INDEX idx_dsp_accounts_active ON dsp_accounts(org_id, is_active) WHERE is_active = true;
CREATE INDEX idx_dsp_accounts_sync ON dsp_accounts(last_sync_at DESC);

COMMENT ON TABLE dsp_accounts IS 'DSP account integrations (DV360, Meta, TTD, etc.)';
COMMENT ON COLUMN dsp_accounts.oauth_token_path IS 'Path to credentials in HashiCorp Vault';

-- ============================================================================
-- TABLE 6: templates (Pipeline & Rule Templates)
-- ============================================================================

CREATE TABLE templates (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Template Info
    name VARCHAR(255) NOT NULL,
    description TEXT,
    category VARCHAR(100) NOT NULL,
    template_type VARCHAR(50) NOT NULL CHECK (template_type IN ('pipeline', 'rule', 'workflow')),
    
    -- DSP Compatibility
    dsp_type dsp_type,
    
    -- Template Configuration
    config JSONB NOT NULL,
    default_params JSONB DEFAULT '{}'::jsonb,
    required_inputs JSONB DEFAULT '[]'::jsonb,
    optional_inputs JSONB DEFAULT '[]'::jsonb,
    
    -- Ownership
    is_public BOOLEAN NOT NULL DEFAULT false,
    created_by UUID REFERENCES users(id),
    org_id UUID REFERENCES organizations(id) ON DELETE CASCADE,
    
    -- Usage Stats
    usage_count INT NOT NULL DEFAULT 0,
    satisfaction_rating DECIMAL(3,2),
    
    -- Versioning
    version INT NOT NULL DEFAULT 1,
    parent_template_id UUID REFERENCES templates(id),
    
    -- Status
    is_active BOOLEAN NOT NULL DEFAULT true,
    
    -- Timestamps
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    -- Constraints
    CONSTRAINT templates_public_no_org CHECK (
        (is_public = true AND org_id IS NULL) OR 
        (is_public = false AND org_id IS NOT NULL)
    )
);

CREATE INDEX idx_templates_category ON templates(category);
CREATE INDEX idx_templates_type ON templates(template_type);
CREATE INDEX idx_templates_dsp ON templates(dsp_type);
CREATE INDEX idx_templates_org ON templates(org_id);
CREATE INDEX idx_templates_public ON templates(is_public) WHERE is_public = true AND is_active = true;
CREATE INDEX idx_templates_usage ON templates(usage_count DESC);

COMMENT ON TABLE templates IS 'Reusable templates for pipelines, rules, and workflows';

-- ============================================================================
-- TABLE 7: pipelines (ETL Workflows)
-- ============================================================================

CREATE TABLE pipelines (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    org_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    
    -- Pipeline Info
    name VARCHAR(255) NOT NULL,
    description TEXT,
    
    -- Configuration
    dsp_account_id UUID REFERENCES dsp_accounts(id) ON DELETE CASCADE,
    template_id UUID REFERENCES templates(id),
    connector_type VARCHAR(50) NOT NULL,
    
    -- Schedule
    schedule_type VARCHAR(50) NOT NULL CHECK (schedule_type IN ('cron', 'interval', 'manual', 'event')),
    schedule_cron VARCHAR(100),
    schedule_interval_minutes INT,
    schedule_timezone VARCHAR(50) DEFAULT 'UTC',
    
    -- Execution Config
    config JSONB NOT NULL,
    retry_config JSONB DEFAULT '{
        "max_attempts": 3,
        "initial_interval_seconds": 60,
        "max_interval_seconds": 3600,
        "backoff_coefficient": 2.0
    }'::jsonb,
    
    -- Status
    status pipeline_status NOT NULL DEFAULT 'draft',
    is_active BOOLEAN NOT NULL DEFAULT true,
    
    -- Execution Tracking
    last_execution_id UUID,
    last_run_at TIMESTAMP,
    last_run_status VARCHAR(50),
    next_run_at TIMESTAMP,
    total_executions INT DEFAULT 0,
    successful_executions INT DEFAULT 0,
    failed_executions INT DEFAULT 0,
    
    -- Ownership
    created_by UUID REFERENCES users(id),
    
    -- Timestamps
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    -- Constraints
    UNIQUE(org_id, name),
    CONSTRAINT pipelines_schedule_valid CHECK (
        (schedule_type = 'cron' AND schedule_cron IS NOT NULL) OR
        (schedule_type = 'interval' AND schedule_interval_minutes IS NOT NULL) OR
        (schedule_type IN ('manual', 'event'))
    )
);

CREATE INDEX idx_pipelines_org ON pipelines(org_id);
CREATE INDEX idx_pipelines_dsp_account ON pipelines(dsp_account_id);
CREATE INDEX idx_pipelines_status ON pipelines(status);
CREATE INDEX idx_pipelines_active ON pipelines(org_id, is_active) WHERE is_active = true;
CREATE INDEX idx_pipelines_next_run ON pipelines(next_run_at) WHERE is_active = true AND next_run_at IS NOT NULL;
CREATE INDEX idx_pipelines_last_run ON pipelines(last_run_at DESC);

COMMENT ON TABLE pipelines IS 'ETL pipeline definitions and schedules';

-- ============================================================================
-- TABLE 8: rules (Business Rules & Alerts)
-- ============================================================================

CREATE TABLE rules (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    org_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    
    -- Rule Info
    name VARCHAR(255) NOT NULL,
    description TEXT,
    module rule_module NOT NULL,
    rule_type VARCHAR(100) NOT NULL,
    
    -- Configuration
    conditions JSONB NOT NULL,
    actions JSONB NOT NULL,
    
    -- Execution
    priority INT NOT NULL DEFAULT 0,
    is_enabled BOOLEAN NOT NULL DEFAULT true,
    
    -- Scope
    pipeline_id UUID REFERENCES pipelines(id) ON DELETE CASCADE,
    entity_type entity_type,
    entity_filters JSONB,
    
    -- Execution Stats
    execution_count INT DEFAULT 0,
    match_count INT DEFAULT 0,
    last_executed_at TIMESTAMP,
    last_match_at TIMESTAMP,
    
    -- Versioning
    version INT NOT NULL DEFAULT 1,
    parent_rule_id UUID REFERENCES rules(id),
    
    -- Ownership
    created_by UUID REFERENCES users(id),
    
    -- Timestamps
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    -- Constraints
    UNIQUE(org_id, module, name, version)
);

CREATE INDEX idx_rules_org ON rules(org_id);
CREATE INDEX idx_rules_module ON rules(module);
CREATE INDEX idx_rules_enabled ON rules(org_id, is_enabled) WHERE is_enabled = true;
CREATE INDEX idx_rules_pipeline ON rules(pipeline_id);
CREATE INDEX idx_rules_priority ON rules(priority DESC);
CREATE INDEX idx_rules_entity_type ON rules(entity_type);

COMMENT ON TABLE rules IS 'Business rules for alerts, QA, taxonomy, pacing, margin';

-- ============================================================================
-- TABLE 9: campaigns (Campaign Data from DSPs)
-- ============================================================================

CREATE TABLE campaigns (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    org_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    
    -- DSP Reference
    dsp_account_id UUID REFERENCES dsp_accounts(id) ON DELETE CASCADE,
    dsp_type dsp_type NOT NULL,
    external_id VARCHAR(255) NOT NULL,
    
    -- Campaign Info
    name VARCHAR(255) NOT NULL,
    advertiser_id VARCHAR(255),
    advertiser_name VARCHAR(255),
    
    -- Hierarchy (DSP-specific)
    parent_id VARCHAR(255),  -- Insertion Order / Campaign Group
    parent_name VARCHAR(255),
    
    -- Status
    status VARCHAR(50) DEFAULT 'active',
    is_active BOOLEAN NOT NULL DEFAULT true,
    
    -- Budget & Pacing
    budget DECIMAL(15,2),
    currency VARCHAR(3) DEFAULT 'USD',
    budget_type VARCHAR(50),  -- daily, lifetime, flight
    
    -- Flight Dates
    start_date DATE,
    end_date DATE,
    
    -- Configuration (DSP-specific)
    config JSONB DEFAULT '{}'::jsonb,
    targeting JSONB DEFAULT '{}'::jsonb,
    
    -- Metadata
    labels JSONB DEFAULT '[]'::jsonb,
    metadata JSONB DEFAULT '{}'::jsonb,
    
    -- Sync Tracking
    last_synced_at TIMESTAMP,
    sync_version INT DEFAULT 1,
    
    -- Timestamps
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    -- Constraints
    UNIQUE(org_id, dsp_type, external_id),
    CONSTRAINT campaigns_dates CHECK (end_date IS NULL OR end_date >= start_date),
    CONSTRAINT campaigns_budget_positive CHECK (budget IS NULL OR budget >= 0)
);

CREATE INDEX idx_campaigns_org ON campaigns(org_id);
CREATE INDEX idx_campaigns_dsp_account ON campaigns(dsp_account_id);
CREATE INDEX idx_campaigns_external ON campaigns(dsp_type, external_id);
CREATE INDEX idx_campaigns_status ON campaigns(status);
CREATE INDEX idx_campaigns_dates ON campaigns(start_date, end_date);
CREATE INDEX idx_campaigns_advertiser ON campaigns(advertiser_id);
CREATE INDEX idx_campaigns_parent ON campaigns(parent_id);
CREATE INDEX idx_campaigns_name_trgm ON campaigns USING gin(name gin_trgm_ops);

COMMENT ON TABLE campaigns IS 'Campaign data synced from DSP platforms';

-- ============================================================================
-- TABLE 10: campaign_metrics (Daily Performance Metrics)
-- ============================================================================

CREATE TABLE campaign_metrics (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    campaign_id UUID NOT NULL REFERENCES campaigns(id) ON DELETE CASCADE,
    org_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    
    -- Date
    metric_date DATE NOT NULL,
    
    -- Performance Metrics
    impressions BIGINT DEFAULT 0 CHECK (impressions >= 0),
    clicks BIGINT DEFAULT 0 CHECK (clicks >= 0),
    conversions BIGINT DEFAULT 0 CHECK (conversions >= 0),
    views BIGINT DEFAULT 0 CHECK (views >= 0),
    
    -- Cost Metrics
    spend DECIMAL(15,2) DEFAULT 0 CHECK (spend >= 0),
    revenue DECIMAL(15,2) DEFAULT 0 CHECK (revenue >= 0),
    
    -- Calculated Metrics
    ctr DECIMAL(5,4),   -- Click-through rate
    cpc DECIMAL(10,4),  -- Cost per click
    cpm DECIMAL(10,4),  -- Cost per mille
    cpa DECIMAL(10,4),  -- Cost per acquisition
    cvr DECIMAL(5,4),   -- Conversion rate
    roas DECIMAL(10,4), -- Return on ad spend
    
    -- Custom Metrics (DSP-specific)
    custom_metrics JSONB DEFAULT '{}'::jsonb,
    
    -- Data Quality
    data_quality_score DECIMAL(3,2),
    has_data_issues BOOLEAN DEFAULT false,
    
    -- Sync Tracking
    synced_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    -- Timestamps
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    -- Constraints
    UNIQUE(campaign_id, metric_date)
);

CREATE INDEX idx_campaign_metrics_campaign ON campaign_metrics(campaign_id);
CREATE INDEX idx_campaign_metrics_org ON campaign_metrics(org_id);
CREATE INDEX idx_campaign_metrics_date ON campaign_metrics(metric_date DESC);
CREATE INDEX idx_campaign_metrics_org_date ON campaign_metrics(org_id, metric_date DESC);
CREATE INDEX idx_campaign_metrics_spend ON campaign_metrics(spend DESC);

-- Partition by month for large datasets
-- CREATE INDEX idx_campaign_metrics_month ON campaign_metrics(org_id, date_trunc('month', metric_date));

COMMENT ON TABLE campaign_metrics IS 'Daily aggregated campaign performance metrics';

-- ============================================================================
-- TABLE 11: etl_executions (ETL Job Execution Tracking)
-- ============================================================================

CREATE TABLE etl_executions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    pipeline_id UUID NOT NULL REFERENCES pipelines(id) ON DELETE CASCADE,
    org_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    
    -- Execution Info
    execution_type VARCHAR(50) NOT NULL CHECK (execution_type IN ('scheduled', 'manual', 'backfill', 'retry')),
    status execution_status NOT NULL DEFAULT 'pending',
    
    -- Layer Progress
    bronze_status VARCHAR(50),
    bronze_records BIGINT,
    bronze_size_bytes BIGINT,
    bronze_duration_ms INT,
    
    silver_status VARCHAR(50),
    silver_records BIGINT,
    silver_records_filtered BIGINT,
    silver_duration_ms INT,
    
    gold_status VARCHAR(50),
    gold_tables_updated JSONB,
    gold_duration_ms INT,
    
    -- Overall Stats
    total_records_processed BIGINT DEFAULT 0,
    total_records_failed BIGINT DEFAULT 0,
    total_duration_ms INT,
    
    -- Configuration
    config JSONB DEFAULT '{}'::jsonb,
    
    -- Error Handling
    error_message TEXT,
    error_details JSONB,
    retry_count INT DEFAULT 0,
    
    -- Temporal Workflow
    workflow_id VARCHAR(255),
    run_id VARCHAR(255),
    
    -- Timestamps
    scheduled_at TIMESTAMP,
    started_at TIMESTAMP,
    completed_at TIMESTAMP,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    -- Constraints
    CONSTRAINT etl_executions_times CHECK (
        (started_at IS NULL OR started_at >= scheduled_at) AND
        (completed_at IS NULL OR completed_at >= started_at)
    )
);

CREATE INDEX idx_etl_executions_pipeline ON etl_executions(pipeline_id);
CREATE INDEX idx_etl_executions_org ON etl_executions(org_id);
CREATE INDEX idx_etl_executions_status ON etl_executions(status);
CREATE INDEX idx_etl_executions_started ON etl_executions(started_at DESC);
CREATE INDEX idx_etl_executions_workflow ON etl_executions(workflow_id, run_id);

COMMENT ON TABLE etl_executions IS 'ETL pipeline execution tracking with layer-wise progress';

-- ============================================================================
-- TABLE 12: data_quality_metrics (Data Quality Tracking)
-- ============================================================================

CREATE TABLE data_quality_metrics (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    execution_id UUID NOT NULL REFERENCES etl_executions(id) ON DELETE CASCADE,
    pipeline_id UUID NOT NULL REFERENCES pipelines(id) ON DELETE CASCADE,
    org_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    
    -- Quality Info
    layer VARCHAR(50) NOT NULL CHECK (layer IN ('bronze', 'silver', 'gold')),
    metric_type VARCHAR(100) NOT NULL,
    metric_name VARCHAR(100) NOT NULL,
    
    -- Metrics
    check_count INT NOT NULL,
    pass_count INT NOT NULL,
    fail_count INT NOT NULL,
    
    -- Details
    severity VARCHAR(50) NOT NULL CHECK (severity IN ('info', 'warning', 'error', 'critical')),
    details JSONB DEFAULT '{}'::jsonb,
    sample_failures JSONB,
    
    -- Timestamp
    measured_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    -- Constraints
    CONSTRAINT dqm_counts CHECK (check_count = pass_count + fail_count)
);

CREATE INDEX idx_dqm_execution ON data_quality_metrics(execution_id);
CREATE INDEX idx_dqm_pipeline ON data_quality_metrics(pipeline_id);
CREATE INDEX idx_dqm_org ON data_quality_metrics(org_id);
CREATE INDEX idx_dqm_layer ON data_quality_metrics(layer);
CREATE INDEX idx_dqm_severity ON data_quality_metrics(severity) WHERE severity IN ('error', 'critical');
CREATE INDEX idx_dqm_measured ON data_quality_metrics(measured_at DESC);

COMMENT ON TABLE data_quality_metrics IS 'Data quality metrics tracked per execution layer';

-- ============================================================================
-- TABLE 13: notifications (Notification Queue)
-- ============================================================================

CREATE TABLE notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    org_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    
    -- Notification Details
    type notification_type NOT NULL,
    channel VARCHAR(50) NOT NULL,
    recipient VARCHAR(255) NOT NULL,
    
    -- Content
    subject VARCHAR(255),
    body TEXT,
    template_id VARCHAR(100),
    template_data JSONB,
    
    -- Delivery
    status VARCHAR(50) DEFAULT 'pending' CHECK (status IN ('pending', 'sent', 'failed', 'cancelled')),
    priority INT DEFAULT 5 CHECK (priority BETWEEN 1 AND 10),
    
    -- Scheduling
    scheduled_at TIMESTAMP,
    sent_at TIMESTAMP,
    
    -- Error Handling
    error_message TEXT,
    retry_count INT DEFAULT 0,
    max_retries INT DEFAULT 3,
    
    -- Metadata
    metadata JSONB DEFAULT '{}'::jsonb,
    
    -- Related Entity
    entity_type entity_type,
    entity_id UUID,
    
    -- Timestamps
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    -- Constraints
    CONSTRAINT notifications_scheduled_future CHECK (scheduled_at IS NULL OR scheduled_at >= created_at)
);

CREATE INDEX idx_notifications_org ON notifications(org_id);
CREATE INDEX idx_notifications_user ON notifications(user_id);
CREATE INDEX idx_notifications_type ON notifications(type);
CREATE INDEX idx_notifications_status ON notifications(status);
CREATE INDEX idx_notifications_scheduled ON notifications(scheduled_at) WHERE scheduled_at IS NOT NULL;
CREATE INDEX idx_notifications_pending ON notifications(status, priority, created_at) 
    WHERE status = 'pending';
CREATE INDEX idx_notifications_entity ON notifications(entity_type, entity_id);

COMMENT ON TABLE notifications IS 'Notification delivery queue for email, Slack, webhooks, etc.';

-- ============================================================================
-- TABLE 14: entity_permissions (Fine-grained Access Control)
-- ============================================================================

CREATE TABLE entity_permissions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    org_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    
    -- Target
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    role user_role,
    
    -- Entity
    entity_type entity_type NOT NULL,
    entity_id UUID NOT NULL,
    
    -- Permissions
    permissions JSONB NOT NULL DEFAULT '["view"]'::jsonb,
    
    -- Metadata
    granted_by UUID REFERENCES users(id),
    granted_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP,
    
    -- Timestamps
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    -- Constraints
    CONSTRAINT entity_permissions_target CHECK (
        (user_id IS NOT NULL AND role IS NULL) OR 
        (user_id IS NULL AND role IS NOT NULL)
    ),
    CONSTRAINT entity_permissions_not_expired CHECK (expires_at IS NULL OR expires_at > granted_at)
);

CREATE INDEX idx_entity_permissions_org ON entity_permissions(org_id);
CREATE INDEX idx_entity_permissions_user ON entity_permissions(user_id);
CREATE INDEX idx_entity_permissions_role ON entity_permissions(role);
CREATE INDEX idx_entity_permissions_entity ON entity_permissions(entity_type, entity_id);
CREATE INDEX idx_entity_permissions_expires ON entity_permissions(expires_at) WHERE expires_at IS NOT NULL;

COMMENT ON TABLE entity_permissions IS 'Entity-level permissions for fine-grained access control';

-- ============================================================================
-- TABLE 15: audit_logs (Complete Audit Trail)
-- ============================================================================

CREATE TABLE audit_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    org_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    
    -- Action Details
    action VARCHAR(100) NOT NULL,
    resource_type VARCHAR(50),
    resource_id UUID,
    
    -- Changes
    old_values JSONB,
    new_values JSONB,
    changes JSONB,
    
    -- Request Context
    ip_address INET,
    user_agent TEXT,
    request_id VARCHAR(100),
    session_id VARCHAR(255),
    
    -- Result
    success BOOLEAN NOT NULL DEFAULT true,
    error_message TEXT,
    
    -- Timestamp
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    -- Indexes will be created below
    CONSTRAINT audit_logs_changes CHECK (
        (old_values IS NULL AND new_values IS NULL) OR
        (old_values IS NOT NULL OR new_values IS NOT NULL)
    )
);

CREATE INDEX idx_audit_logs_org ON audit_logs(org_id);
CREATE INDEX idx_audit_logs_user ON audit_logs(user_id);
CREATE INDEX idx_audit_logs_action ON audit_logs(action);
CREATE INDEX idx_audit_logs_resource ON audit_logs(resource_type, resource_id);
CREATE INDEX idx_audit_logs_created ON audit_logs(created_at DESC);
CREATE INDEX idx_audit_logs_org_created ON audit_logs(org_id, created_at DESC);
CREATE INDEX idx_audit_logs_request ON audit_logs(request_id);

-- Partition by month for production at scale
-- ALTER TABLE audit_logs PARTITION BY RANGE (created_at);

COMMENT ON TABLE audit_logs IS 'Complete audit trail for all user and system actions';

-- ============================================================================
-- INSERT DEFAULT DATA
-- ============================================================================

-- Default system permissions
CREATE TABLE permissions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    resource VARCHAR(100) NOT NULL,
    action VARCHAR(50) NOT NULL,
    description TEXT,
    
    UNIQUE(resource, action)
);

INSERT INTO permissions (resource, action, description) VALUES
    ('campaigns', 'create', 'Create campaigns'),
    ('campaigns', 'read', 'View campaigns'),
    ('campaigns', 'update', 'Update campaigns'),
    ('campaigns', 'delete', 'Delete campaigns'),
    ('pipelines', 'create', 'Create pipelines'),
    ('pipelines', 'read', 'View pipelines'),
    ('pipelines', 'update', 'Update pipelines'),
    ('pipelines', 'delete', 'Delete pipelines'),
    ('pipelines', 'execute', 'Execute pipelines'),
    ('rules', 'create', 'Create rules'),
    ('rules', 'read', 'View rules'),
    ('rules', 'update', 'Update rules'),
    ('rules', 'delete', 'Delete rules'),
    ('reports', 'read', 'View reports'),
    ('reports', 'export', 'Export reports'),
    ('users', 'manage', 'Manage users'),
    ('dsp_accounts', 'manage', 'Manage DSP accounts'),
    ('settings', 'manage', 'Manage organization settings')
ON CONFLICT (resource, action) DO NOTHING;

CREATE INDEX idx_permissions_resource ON permissions(resource);

-- Role-Permission Mapping
CREATE TABLE role_permissions (
    role user_role NOT NULL,
    permission_id UUID NOT NULL REFERENCES permissions(id) ON DELETE CASCADE,
    
    PRIMARY KEY(role, permission_id)
);

-- Admin gets all permissions
INSERT INTO role_permissions (role, permission_id)
SELECT 'admin', id FROM permissions;

-- Developer gets all except user management
INSERT INTO role_permissions (role, permission_id)
SELECT 'developer', id FROM permissions 
WHERE resource != 'users';

-- Analyst gets read and execute
INSERT INTO role_permissions (role, permission_id)
SELECT 'analyst', id FROM permissions 
WHERE action IN ('read', 'execute', 'export');

-- Viewer gets read only
INSERT INTO role_permissions (role, permission_id)
SELECT 'viewer', id FROM permissions 
WHERE action = 'read';

CREATE INDEX idx_role_permissions_role ON role_permissions(role);

-- ============================================================================
-- FUNCTIONS & TRIGGERS
-- ============================================================================

-- Function: Update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply updated_at triggers to all tables with updated_at column
DO $$
DECLARE
    t TEXT;
BEGIN
    FOR t IN 
        SELECT table_name 
        FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND column_name = 'updated_at'
        AND table_name NOT IN ('permissions', 'role_permissions')
    LOOP
        EXECUTE format('
            CREATE TRIGGER update_%I_updated_at 
            BEFORE UPDATE ON %I 
            FOR EACH ROW 
            EXECUTE FUNCTION update_updated_at_column()',
            t, t
        );
    END LOOP;
END $$;

-- Function: Audit log trigger
CREATE OR REPLACE FUNCTION audit_log_trigger()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO audit_logs (
        org_id,
        user_id,
        action,
        resource_type,
        resource_id,
        old_values,
        new_values
    ) VALUES (
        COALESCE(NEW.org_id, OLD.org_id),
        current_setting('app.current_user_id', true)::UUID,
        TG_OP,
        TG_TABLE_NAME,
        COALESCE(NEW.id, OLD.id),
        CASE WHEN TG_OP = 'DELETE' THEN row_to_json(OLD) ELSE NULL END,
        CASE WHEN TG_OP IN ('INSERT', 'UPDATE') THEN row_to_json(NEW) ELSE NULL END
    );
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

-- Apply audit triggers to critical tables
DO $$
DECLARE
    t TEXT;
BEGIN
    FOR t IN 
        SELECT unnest(ARRAY[
            'organizations', 'users', 'dsp_accounts', 'pipelines', 
            'rules', 'campaigns'
        ])
    LOOP
        EXECUTE format('
            CREATE TRIGGER audit_%I 
            AFTER INSERT OR UPDATE OR DELETE ON %I 
            FOR EACH ROW 
            EXECUTE FUNCTION audit_log_trigger()',
            t, t
        );
    END LOOP;
END $$;

-- ============================================================================
-- VIEWS
-- ============================================================================

-- View: User with their organizations and roles
CREATE OR REPLACE VIEW user_org_roles AS
SELECT 
    u.id as user_id,
    u.email,
    u.name,
    o.id as org_id,
    o.name as org_name,
    o.slug as org_slug,
    om.role,
    om.is_active as membership_active
FROM users u
JOIN org_memberships om ON u.id = om.user_id
JOIN organizations o ON om.org_id = o.id
WHERE u.deleted_at IS NULL 
    AND o.deleted_at IS NULL 
    AND om.is_active = true;

-- View: Pipeline health summary
CREATE OR REPLACE VIEW pipeline_health AS
SELECT 
    p.id as pipeline_id,
    p.org_id,
    p.name,
    p.status,
    p.last_run_at,
    p.last_run_status,
    p.next_run_at,
    p.total_executions,
    p.successful_executions,
    p.failed_executions,
    CASE 
        WHEN p.total_executions = 0 THEN 100.0
        ELSE ROUND((p.successful_executions::NUMERIC / p.total_executions * 100), 2)
    END as success_rate,
    da.dsp_type,
    da.display_name as dsp_account_name
FROM pipelines p
LEFT JOIN dsp_accounts da ON p.dsp_account_id = da.id
WHERE p.is_active = true;

-- ============================================================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================================================

-- Enable RLS on all tenant tables
ALTER TABLE organizations ENABLE ROW LEVEL SECURITY;
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE org_memberships ENABLE ROW LEVEL SECURITY;
ALTER TABLE dsp_accounts ENABLE ROW LEVEL SECURITY;
ALTER TABLE pipelines ENABLE ROW LEVEL SECURITY;
ALTER TABLE rules ENABLE ROW LEVEL SECURITY;
ALTER TABLE campaigns ENABLE ROW LEVEL SECURITY;
ALTER TABLE campaign_metrics ENABLE ROW LEVEL SECURITY;

-- Example RLS policy (customize based on your needs)
CREATE POLICY org_isolation ON organizations
    FOR ALL
    USING (id = current_setting('app.current_org_id', true)::UUID);

-- ============================================================================
-- GRANTS (Adjust based on your roles)
-- ============================================================================

-- Create application roles
-- CREATE ROLE app_user;
-- CREATE ROLE app_admin;
-- CREATE ROLE readonly_user;

-- Grant permissions (example)
-- GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO app_user;
-- GRANT SELECT ON ALL TABLES IN SCHEMA public TO readonly_user;

-- ============================================================================
-- VACUUM & ANALYZE
-- ============================================================================

VACUUM ANALYZE;

-- ============================================================================
-- COMPLETION
-- ============================================================================

SELECT 'Schema created successfully!' as status,
       COUNT(*) as table_count
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_type = 'BASE TABLE';