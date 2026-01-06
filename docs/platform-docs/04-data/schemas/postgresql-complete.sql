-- =============================================================================
-- Campaign Lifecycle Platform - Complete PostgreSQL Schema
-- =============================================================================
-- This file contains the complete database schema for the platform.
-- Use migrations for production deployments; this file is for reference.
-- =============================================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- =============================================================================
-- USERS & AUTHENTICATION
-- =============================================================================

CREATE TABLE users (
    id BIGSERIAL PRIMARY KEY,
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    full_name VARCHAR(255) NOT NULL,
    email_verified BOOLEAN NOT NULL DEFAULT FALSE,
    email_verified_at TIMESTAMPTZ,
    last_login_at TIMESTAMPTZ,
    failed_login_attempts INT NOT NULL DEFAULT 0,
    locked_until TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ
);

CREATE INDEX idx_users_email ON users(email) WHERE deleted_at IS NULL;
CREATE INDEX idx_users_created_at ON users(created_at);

-- Email verification tokens
CREATE TABLE email_verification_tokens (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token VARCHAR(255) NOT NULL UNIQUE,
    expires_at TIMESTAMPTZ NOT NULL,
    used_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_email_tokens_user ON email_verification_tokens(user_id);
CREATE INDEX idx_email_tokens_token ON email_verification_tokens(token) WHERE used_at IS NULL;

-- Password reset tokens
CREATE TABLE password_reset_tokens (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token VARCHAR(255) NOT NULL UNIQUE,
    expires_at TIMESTAMPTZ NOT NULL,
    used_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_password_tokens_token ON password_reset_tokens(token) WHERE used_at IS NULL;

-- API Keys for programmatic access
CREATE TABLE api_keys (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    org_id BIGINT NOT NULL,  -- FK added after organizations table
    name VARCHAR(255) NOT NULL,
    key_hash VARCHAR(255) NOT NULL UNIQUE,
    key_prefix VARCHAR(10) NOT NULL,  -- First 10 chars for identification
    permissions TEXT[] NOT NULL DEFAULT '{}',
    expires_at TIMESTAMPTZ,
    last_used_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    revoked_at TIMESTAMPTZ
);

CREATE INDEX idx_api_keys_user ON api_keys(user_id) WHERE revoked_at IS NULL;
CREATE INDEX idx_api_keys_hash ON api_keys(key_hash) WHERE revoked_at IS NULL;

-- =============================================================================
-- ORGANIZATIONS
-- =============================================================================

CREATE TABLE organizations (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    slug VARCHAR(100) NOT NULL UNIQUE,
    is_premium BOOLEAN NOT NULL DEFAULT FALSE,
    timezone VARCHAR(50) NOT NULL DEFAULT 'UTC',
    currency VARCHAR(3) NOT NULL DEFAULT 'USD',
    enabled_modules TEXT[] NOT NULL DEFAULT '{}',
    settings JSONB NOT NULL DEFAULT '{}',
    billing_email VARCHAR(255),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ
);

CREATE INDEX idx_orgs_slug ON organizations(slug) WHERE deleted_at IS NULL;
CREATE INDEX idx_orgs_name ON organizations(name) WHERE deleted_at IS NULL;

-- Add FK for api_keys
ALTER TABLE api_keys ADD CONSTRAINT fk_api_keys_org 
    FOREIGN KEY (org_id) REFERENCES organizations(id) ON DELETE CASCADE;

-- Organization memberships (user <-> org relationship)
CREATE TABLE org_memberships (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    org_id BIGINT NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    role VARCHAR(50) NOT NULL DEFAULT 'member',  -- owner, admin, member, viewer
    is_default BOOLEAN NOT NULL DEFAULT FALSE,
    joined_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    invited_by BIGINT REFERENCES users(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    CONSTRAINT uq_org_membership UNIQUE (user_id, org_id),
    CONSTRAINT chk_role CHECK (role IN ('owner', 'admin', 'member', 'viewer'))
);

CREATE INDEX idx_memberships_user ON org_memberships(user_id);
CREATE INDEX idx_memberships_org ON org_memberships(org_id);
CREATE INDEX idx_memberships_org_role ON org_memberships(org_id, role);

-- Organization invitations
CREATE TABLE org_invitations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    org_id BIGINT NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    email VARCHAR(255) NOT NULL,
    role VARCHAR(50) NOT NULL DEFAULT 'member',
    token VARCHAR(255) NOT NULL UNIQUE,
    invited_by BIGINT NOT NULL REFERENCES users(id),
    expires_at TIMESTAMPTZ NOT NULL,
    accepted_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    CONSTRAINT chk_invite_role CHECK (role IN ('admin', 'member', 'viewer'))
);

CREATE INDEX idx_invitations_org ON org_invitations(org_id) WHERE accepted_at IS NULL;
CREATE INDEX idx_invitations_email ON org_invitations(email) WHERE accepted_at IS NULL;
CREATE INDEX idx_invitations_token ON org_invitations(token) WHERE accepted_at IS NULL;

-- =============================================================================
-- DSP ACCOUNTS & CONNECTORS
-- =============================================================================

CREATE TABLE dsp_accounts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    org_id BIGINT NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    connector_type VARCHAR(50) NOT NULL,  -- DV360, TTD, META, GOOGLE_ADS
    external_id VARCHAR(255) NOT NULL,
    name VARCHAR(255) NOT NULL,
    status VARCHAR(50) NOT NULL DEFAULT 'connected',
    account_type VARCHAR(50),  -- partner, advertiser, etc.
    currency VARCHAR(3),
    oauth_token_encrypted BYTEA,
    oauth_refresh_token_encrypted BYTEA,
    oauth_expires_at TIMESTAMPTZ,
    api_key_encrypted BYTEA,  -- For TTD
    last_sync_at TIMESTAMPTZ,
    health_status VARCHAR(50) DEFAULT 'unknown',
    health_checked_at TIMESTAMPTZ,
    metadata JSONB NOT NULL DEFAULT '{}',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    disconnected_at TIMESTAMPTZ,
    
    CONSTRAINT uq_dsp_account UNIQUE (org_id, connector_type, external_id),
    CONSTRAINT chk_connector_type CHECK (connector_type IN ('DV360', 'TTD', 'META', 'GOOGLE_ADS', 'GOOGLE_SHEETS', 'SALESFORCE'))
);

CREATE INDEX idx_dsp_accounts_org ON dsp_accounts(org_id) WHERE disconnected_at IS NULL;
CREATE INDEX idx_dsp_accounts_org_type ON dsp_accounts(org_id, connector_type) WHERE disconnected_at IS NULL;
CREATE INDEX idx_dsp_accounts_sync ON dsp_accounts(last_sync_at) WHERE disconnected_at IS NULL;

-- =============================================================================
-- PIPELINES
-- =============================================================================

CREATE TABLE pipelines (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    org_id BIGINT NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    connector_type VARCHAR(50) NOT NULL,
    status VARCHAR(50) NOT NULL DEFAULT 'active',
    schedule_type VARCHAR(50) NOT NULL DEFAULT 'cron',
    schedule_expression VARCHAR(255),  -- Cron expression
    schedule_timezone VARCHAR(50) NOT NULL DEFAULT 'UTC',
    config JSONB NOT NULL DEFAULT '{}',
    template_id UUID,
    created_by BIGINT NOT NULL REFERENCES users(id),
    last_run_at TIMESTAMPTZ,
    next_run_at TIMESTAMPTZ,
    last_execution_id UUID,
    last_execution_status VARCHAR(50),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ,
    
    CONSTRAINT chk_pipeline_status CHECK (status IN ('active', 'paused', 'failed', 'disabled')),
    CONSTRAINT chk_schedule_type CHECK (schedule_type IN ('cron', 'interval', 'manual'))
);

CREATE INDEX idx_pipelines_org ON pipelines(org_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_pipelines_org_status ON pipelines(org_id, status) WHERE deleted_at IS NULL;
CREATE INDEX idx_pipelines_next_run ON pipelines(next_run_at) WHERE status = 'active' AND deleted_at IS NULL;

-- Pipeline templates
CREATE TABLE pipeline_templates (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    org_id BIGINT REFERENCES organizations(id) ON DELETE CASCADE,  -- NULL for public templates
    name VARCHAR(255) NOT NULL,
    description TEXT,
    connector_type VARCHAR(50) NOT NULL,
    default_config JSONB NOT NULL DEFAULT '{}',
    required_inputs JSONB NOT NULL DEFAULT '[]',
    optional_inputs JSONB NOT NULL DEFAULT '[]',
    is_public BOOLEAN NOT NULL DEFAULT FALSE,
    usage_count INT NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_templates_public ON pipeline_templates(connector_type) WHERE is_public = TRUE;
CREATE INDEX idx_templates_org ON pipeline_templates(org_id) WHERE org_id IS NOT NULL;

-- Pipeline executions
CREATE TABLE pipeline_executions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    pipeline_id UUID NOT NULL REFERENCES pipelines(id) ON DELETE CASCADE,
    org_id BIGINT NOT NULL REFERENCES organizations(id),
    status VARCHAR(50) NOT NULL DEFAULT 'pending',
    trigger_type VARCHAR(50) NOT NULL DEFAULT 'scheduled',
    triggered_by BIGINT REFERENCES users(id),
    parameters JSONB NOT NULL DEFAULT '{}',
    started_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    error_message TEXT,
    metrics JSONB NOT NULL DEFAULT '{}',  -- records_processed, duration_ms, etc.
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    CONSTRAINT chk_exec_status CHECK (status IN ('pending', 'running', 'completed', 'failed', 'cancelled', 'timeout')),
    CONSTRAINT chk_trigger_type CHECK (trigger_type IN ('scheduled', 'manual', 'retry', 'backfill', 'dependency'))
);

CREATE INDEX idx_executions_pipeline ON pipeline_executions(pipeline_id);
CREATE INDEX idx_executions_org_status ON pipeline_executions(org_id, status);
CREATE INDEX idx_executions_created ON pipeline_executions(created_at);

-- =============================================================================
-- RULES
-- =============================================================================

CREATE TABLE rules (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    org_id BIGINT NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    module VARCHAR(50) NOT NULL,  -- pacing, margin, alerts, qa, taxonomy
    enabled BOOLEAN NOT NULL DEFAULT TRUE,
    conditions JSONB NOT NULL,
    actions JSONB NOT NULL,
    schedule_type VARCHAR(50),
    schedule_expression VARCHAR(255),
    version INT NOT NULL DEFAULT 1,
    created_by BIGINT NOT NULL REFERENCES users(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ,
    
    CONSTRAINT chk_rule_module CHECK (module IN ('pacing', 'margin', 'alerts', 'qa', 'taxonomy'))
);

CREATE INDEX idx_rules_org ON rules(org_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_rules_org_module ON rules(org_id, module) WHERE enabled = TRUE AND deleted_at IS NULL;

-- Rule versions for audit
CREATE TABLE rule_versions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    rule_id UUID NOT NULL REFERENCES rules(id) ON DELETE CASCADE,
    version INT NOT NULL,
    conditions JSONB NOT NULL,
    actions JSONB NOT NULL,
    changed_by BIGINT NOT NULL REFERENCES users(id),
    change_reason TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    CONSTRAINT uq_rule_version UNIQUE (rule_id, version)
);

CREATE INDEX idx_rule_versions_rule ON rule_versions(rule_id);

-- Rule matches (when rules trigger)
CREATE TABLE rule_matches (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    rule_id UUID NOT NULL REFERENCES rules(id) ON DELETE CASCADE,
    org_id BIGINT NOT NULL REFERENCES organizations(id),
    entity_type VARCHAR(50) NOT NULL,
    entity_id VARCHAR(255) NOT NULL,
    entity_name VARCHAR(255),
    severity VARCHAR(50) NOT NULL DEFAULT 'info',
    matched_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    condition_results JSONB NOT NULL,
    data_snapshot JSONB NOT NULL DEFAULT '{}',
    actions_executed JSONB NOT NULL DEFAULT '[]',
    acknowledged_by BIGINT REFERENCES users(id),
    acknowledged_at TIMESTAMPTZ,
    
    CONSTRAINT chk_match_severity CHECK (severity IN ('info', 'warning', 'critical'))
);

CREATE INDEX idx_matches_org ON rule_matches(org_id);
CREATE INDEX idx_matches_rule ON rule_matches(rule_id);
CREATE INDEX idx_matches_entity ON rule_matches(org_id, entity_type, entity_id);
CREATE INDEX idx_matches_time ON rule_matches(matched_at);
CREATE INDEX idx_matches_unack ON rule_matches(org_id, acknowledged_at) WHERE acknowledged_at IS NULL;

-- =============================================================================
-- ENTITY PERMISSIONS
-- =============================================================================

CREATE TABLE entity_permissions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    org_id BIGINT NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    entity_type VARCHAR(50) NOT NULL,
    entity_id VARCHAR(255) NOT NULL,
    permissions TEXT[] NOT NULL,  -- ['read', 'write', 'execute', 'delete']
    granted_by BIGINT NOT NULL REFERENCES users(id),
    expires_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    revoked_at TIMESTAMPTZ,
    
    CONSTRAINT uq_entity_permission UNIQUE (user_id, entity_type, entity_id) 
);

CREATE INDEX idx_permissions_user ON entity_permissions(user_id) WHERE revoked_at IS NULL;
CREATE INDEX idx_permissions_entity ON entity_permissions(org_id, entity_type, entity_id) WHERE revoked_at IS NULL;

-- =============================================================================
-- AUDIT LOGS
-- =============================================================================

CREATE TABLE audit_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    org_id BIGINT NOT NULL REFERENCES organizations(id),
    user_id BIGINT REFERENCES users(id),
    action VARCHAR(50) NOT NULL,
    entity_type VARCHAR(50) NOT NULL,
    entity_id VARCHAR(255),
    entity_name VARCHAR(255),
    old_values JSONB,
    new_values JSONB,
    ip_address INET,
    user_agent TEXT,
    request_id VARCHAR(255),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Partitioned by month for performance
CREATE INDEX idx_audit_org_time ON audit_logs(org_id, created_at);
CREATE INDEX idx_audit_user_time ON audit_logs(user_id, created_at);
CREATE INDEX idx_audit_entity ON audit_logs(org_id, entity_type, entity_id);
CREATE INDEX idx_audit_action ON audit_logs(org_id, action, created_at);

-- =============================================================================
-- NOTIFICATIONS
-- =============================================================================

CREATE TABLE notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    org_id BIGINT NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    type VARCHAR(50) NOT NULL,  -- alert, digest, system, transactional
    severity VARCHAR(50) NOT NULL DEFAULT 'info',
    template_id VARCHAR(100) NOT NULL,
    subject VARCHAR(500),
    body TEXT,
    data JSONB NOT NULL DEFAULT '{}',
    entity_type VARCHAR(50),
    entity_id VARCHAR(255),
    rule_id UUID REFERENCES rules(id),
    channels TEXT[] NOT NULL,  -- ['email', 'slack', 'webhook']
    status VARCHAR(50) NOT NULL DEFAULT 'queued',
    idempotency_key VARCHAR(255),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    sent_at TIMESTAMPTZ,
    
    CONSTRAINT chk_notif_type CHECK (type IN ('alert', 'digest', 'system', 'transactional')),
    CONSTRAINT chk_notif_status CHECK (status IN ('queued', 'sending', 'sent', 'failed', 'skipped'))
);

CREATE INDEX idx_notifications_org ON notifications(org_id);
CREATE INDEX idx_notifications_status ON notifications(status) WHERE status IN ('queued', 'sending');
CREATE INDEX idx_notifications_created ON notifications(created_at);
CREATE UNIQUE INDEX idx_notifications_idempotency ON notifications(idempotency_key) WHERE idempotency_key IS NOT NULL;

-- Notification deliveries (per recipient)
CREATE TABLE notification_deliveries (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    notification_id UUID NOT NULL REFERENCES notifications(id) ON DELETE CASCADE,
    channel VARCHAR(50) NOT NULL,
    recipient VARCHAR(255) NOT NULL,  -- email, slack channel, webhook URL
    status VARCHAR(50) NOT NULL DEFAULT 'pending',
    attempts INT NOT NULL DEFAULT 0,
    last_attempt_at TIMESTAMPTZ,
    delivered_at TIMESTAMPTZ,
    error_message TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_deliveries_notification ON notification_deliveries(notification_id);
CREATE INDEX idx_deliveries_status ON notification_deliveries(status) WHERE status IN ('pending', 'retrying');

-- User notification preferences
CREATE TABLE notification_preferences (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    org_id BIGINT NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    channels_enabled JSONB NOT NULL DEFAULT '{"email": true, "slack": true}',
    frequency_by_severity JSONB NOT NULL DEFAULT '{"critical": "immediate", "warning": "hourly_digest", "info": "daily_digest"}',
    quiet_hours JSONB NOT NULL DEFAULT '{"enabled": false}',
    modules_enabled JSONB NOT NULL DEFAULT '{}',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    CONSTRAINT uq_notif_prefs UNIQUE (user_id, org_id)
);

-- =============================================================================
-- DEALS & BOOKINGS
-- =============================================================================

CREATE TABLE deals (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    org_id BIGINT NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    external_id VARCHAR(255),  -- ID from booking system
    client_name VARCHAR(255) NOT NULL,
    campaign_name VARCHAR(255) NOT NULL,
    dsp VARCHAR(50),
    dsp_campaign_id VARCHAR(255),  -- Linked campaign in DSP
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    booked_amount DECIMAL(18, 4) NOT NULL,
    currency VARCHAR(3) NOT NULL DEFAULT 'USD',
    buy_model VARCHAR(50) NOT NULL,  -- CPM, CPC, CPA, CPV, Fixed
    rate DECIMAL(18, 6),
    booked_quantity BIGINT,
    trader VARCHAR(255),
    status VARCHAR(50) NOT NULL DEFAULT 'active',
    source VARCHAR(50) NOT NULL,  -- google_sheets, salesforce, booking_db
    source_sync_at TIMESTAMPTZ,
    metadata JSONB NOT NULL DEFAULT '{}',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    CONSTRAINT chk_deal_status CHECK (status IN ('active', 'completed', 'cancelled')),
    CONSTRAINT chk_deal_buy_model CHECK (buy_model IN ('CPM', 'CPC', 'CPA', 'CPV', 'FIXED'))
);

CREATE INDEX idx_deals_org ON deals(org_id);
CREATE INDEX idx_deals_org_status ON deals(org_id, status) WHERE status = 'active';
CREATE INDEX idx_deals_external ON deals(org_id, external_id) WHERE external_id IS NOT NULL;
CREATE INDEX idx_deals_campaign ON deals(org_id, dsp_campaign_id) WHERE dsp_campaign_id IS NOT NULL;
CREATE INDEX idx_deals_dates ON deals(org_id, start_date, end_date);

-- =============================================================================
-- WEBHOOKS
-- =============================================================================

CREATE TABLE webhooks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    org_id BIGINT NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    url VARCHAR(2048) NOT NULL,
    secret VARCHAR(255) NOT NULL,  -- For HMAC signing
    events TEXT[] NOT NULL,  -- ['alert.triggered', 'pipeline.completed', ...]
    enabled BOOLEAN NOT NULL DEFAULT TRUE,
    created_by BIGINT NOT NULL REFERENCES users(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ
);

CREATE INDEX idx_webhooks_org ON webhooks(org_id) WHERE deleted_at IS NULL AND enabled = TRUE;

-- Webhook deliveries
CREATE TABLE webhook_deliveries (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    webhook_id UUID NOT NULL REFERENCES webhooks(id) ON DELETE CASCADE,
    event_type VARCHAR(100) NOT NULL,
    payload JSONB NOT NULL,
    status VARCHAR(50) NOT NULL DEFAULT 'pending',
    attempts INT NOT NULL DEFAULT 0,
    last_attempt_at TIMESTAMPTZ,
    response_status INT,
    response_body TEXT,
    next_retry_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    delivered_at TIMESTAMPTZ
);

CREATE INDEX idx_webhook_deliveries_status ON webhook_deliveries(status, next_retry_at) 
    WHERE status IN ('pending', 'retrying');

-- =============================================================================
-- FUNCTIONS & TRIGGERS
-- =============================================================================

-- Updated timestamp trigger
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply updated_at trigger to all relevant tables
CREATE TRIGGER tr_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER tr_organizations_updated_at BEFORE UPDATE ON organizations
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER tr_org_memberships_updated_at BEFORE UPDATE ON org_memberships
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER tr_dsp_accounts_updated_at BEFORE UPDATE ON dsp_accounts
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER tr_pipelines_updated_at BEFORE UPDATE ON pipelines
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER tr_rules_updated_at BEFORE UPDATE ON rules
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER tr_deals_updated_at BEFORE UPDATE ON deals
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- =============================================================================
-- COMMENTS
-- =============================================================================

COMMENT ON TABLE users IS 'Platform users with authentication credentials';
COMMENT ON TABLE organizations IS 'Multi-tenant organizations';
COMMENT ON TABLE org_memberships IS 'User membership in organizations with roles';
COMMENT ON TABLE dsp_accounts IS 'Connected DSP advertising accounts';
COMMENT ON TABLE pipelines IS 'Data ingestion pipeline configurations';
COMMENT ON TABLE rules IS 'Alert and automation rules';
COMMENT ON TABLE entity_permissions IS 'Fine-grained entity-level permissions';
COMMENT ON TABLE audit_logs IS 'Immutable audit trail of all actions';
COMMENT ON TABLE deals IS 'Booking/deal data for margin calculations';
