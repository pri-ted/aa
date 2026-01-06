-- Campaign Lifecycle Platform - Initial Schema
-- Version: 1.0.0
-- Date: 2026-01-06
-- Description: Creates all 12 core tables with multi-tenant support

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ============================================================================
-- TABLE 1: organizations (Tenant Organizations)
-- ============================================================================

CREATE TABLE IF NOT EXISTS organizations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    slug VARCHAR(100) UNIQUE NOT NULL,
    status VARCHAR(50) DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'suspended')),
    settings JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT organizations_slug_format CHECK (slug ~ '^[a-z0-9-]+$')
);

CREATE INDEX idx_organizations_slug ON organizations(slug);
CREATE INDEX idx_organizations_status ON organizations(status);
CREATE INDEX idx_organizations_created_at ON organizations(created_at);

COMMENT ON TABLE organizations IS 'Tenant organizations in the platform';
COMMENT ON COLUMN organizations.slug IS 'URL-safe unique identifier';
COMMENT ON COLUMN organizations.settings IS 'Organization-level configuration';

-- ============================================================================
-- TABLE 2: users (User Accounts)
-- ============================================================================

CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    org_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    email VARCHAR(255) NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    name VARCHAR(255) NOT NULL,
    status VARCHAR(50) DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'suspended')),
    last_login_at TIMESTAMP,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE(org_id, email),
    CONSTRAINT users_email_format CHECK (email ~ '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$')
);

CREATE INDEX idx_users_org_id ON users(org_id);
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_status ON users(status);
CREATE INDEX idx_users_last_login_at ON users(last_login_at);

COMMENT ON TABLE users IS 'User accounts with multi-tenant support';
COMMENT ON COLUMN users.org_id IS 'Tenant identifier for data isolation';

-- ============================================================================
-- TABLE 3: user_roles (RBAC Role Assignments)
-- ============================================================================

CREATE TABLE IF NOT EXISTS user_roles (
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    org_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    role VARCHAR(50) NOT NULL CHECK (role IN ('admin', 'user', 'viewer', 'developer')),
    granted_by UUID REFERENCES users(id),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    PRIMARY KEY(user_id, org_id, role)
);

CREATE INDEX idx_user_roles_user_id ON user_roles(user_id);
CREATE INDEX idx_user_roles_org_id ON user_roles(org_id);
CREATE INDEX idx_user_roles_role ON user_roles(role);

COMMENT ON TABLE user_roles IS 'User role assignments for RBAC';

-- ============================================================================
-- TABLE 4: permissions (Permission Definitions)
-- ============================================================================

CREATE TABLE IF NOT EXISTS permissions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    resource VARCHAR(100) NOT NULL,
    action VARCHAR(50) NOT NULL,
    description TEXT,
    
    UNIQUE(resource, action)
);

CREATE INDEX idx_permissions_resource ON permissions(resource);

COMMENT ON TABLE permissions IS 'Available permissions in the system';

-- ============================================================================
-- TABLE 5: role_permissions (Role to Permission Mapping)
-- ============================================================================

CREATE TABLE IF NOT EXISTS role_permissions (
    role VARCHAR(50) NOT NULL,
    permission_id UUID NOT NULL REFERENCES permissions(id) ON DELETE CASCADE,
    
    PRIMARY KEY(role, permission_id)
);

CREATE INDEX idx_role_permissions_role ON role_permissions(role);

COMMENT ON TABLE role_permissions IS 'Maps roles to permissions';

-- ============================================================================
-- TABLE 6: auth_tokens (Access & Refresh Tokens)
-- ============================================================================

CREATE TABLE IF NOT EXISTS auth_tokens (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    org_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    access_token VARCHAR(255) UNIQUE NOT NULL,
    refresh_token VARCHAR(255) UNIQUE NOT NULL,
    token_type VARCHAR(50) DEFAULT 'Bearer',
    expires_at TIMESTAMP NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    last_used_at TIMESTAMP,
    
    CONSTRAINT auth_tokens_expires_future CHECK (expires_at > created_at)
);

CREATE INDEX idx_auth_tokens_access_token ON auth_tokens(access_token);
CREATE INDEX idx_auth_tokens_refresh_token ON auth_tokens(refresh_token);
CREATE INDEX idx_auth_tokens_user_id ON auth_tokens(user_id);
CREATE INDEX idx_auth_tokens_org_id ON auth_tokens(org_id);
CREATE INDEX idx_auth_tokens_expires_at ON auth_tokens(expires_at);

-- Automatically delete expired tokens
CREATE INDEX idx_auth_tokens_expired ON auth_tokens(expires_at) WHERE expires_at < CURRENT_TIMESTAMP;

COMMENT ON TABLE auth_tokens IS 'JWT access and refresh tokens';

-- ============================================================================
-- TABLE 7: dsp_connectors (DSP Integrations)
-- ============================================================================

CREATE TABLE IF NOT EXISTS dsp_connectors (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    org_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    dsp_type VARCHAR(50) NOT NULL CHECK (dsp_type IN ('dv360', 'meta', 'ttd', 'amazon', 'google_ads')),
    name VARCHAR(255) NOT NULL,
    credentials JSONB NOT NULL,
    config JSONB DEFAULT '{}'::jsonb,
    status VARCHAR(50) DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'error')),
    last_sync_at TIMESTAMP,
    sync_status VARCHAR(50),
    error_message TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE(org_id, dsp_type, name)
);

CREATE INDEX idx_dsp_connectors_org_id ON dsp_connectors(org_id);
CREATE INDEX idx_dsp_connectors_dsp_type ON dsp_connectors(dsp_type);
CREATE INDEX idx_dsp_connectors_status ON dsp_connectors(status);
CREATE INDEX idx_dsp_connectors_last_sync_at ON dsp_connectors(last_sync_at);

COMMENT ON TABLE dsp_connectors IS 'DSP API integrations (DV360, Meta, TTD, etc.)';
COMMENT ON COLUMN dsp_connectors.credentials IS 'Encrypted API credentials (OAuth tokens, API keys)';

-- ============================================================================
-- TABLE 8: campaigns (Marketing Campaigns)
-- ============================================================================

CREATE TABLE IF NOT EXISTS campaigns (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    org_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    dsp_connector_id UUID REFERENCES dsp_connectors(id) ON DELETE SET NULL,
    external_id VARCHAR(255),
    name VARCHAR(255) NOT NULL,
    status VARCHAR(50) DEFAULT 'draft' CHECK (status IN ('draft', 'active', 'paused', 'completed', 'archived')),
    budget DECIMAL(15,2) CHECK (budget >= 0),
    currency VARCHAR(3) DEFAULT 'USD',
    start_date DATE,
    end_date DATE,
    config JSONB DEFAULT '{}'::jsonb,
    metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE(org_id, dsp_connector_id, external_id),
    CONSTRAINT campaigns_dates CHECK (end_date IS NULL OR end_date >= start_date)
);

CREATE INDEX idx_campaigns_org_id ON campaigns(org_id);
CREATE INDEX idx_campaigns_dsp_connector_id ON campaigns(dsp_connector_id);
CREATE INDEX idx_campaigns_external_id ON campaigns(external_id);
CREATE INDEX idx_campaigns_status ON campaigns(status);
CREATE INDEX idx_campaigns_dates ON campaigns(start_date, end_date);
CREATE INDEX idx_campaigns_created_at ON campaigns(created_at);

COMMENT ON TABLE campaigns IS 'Marketing campaigns from various DSPs';
COMMENT ON COLUMN campaigns.external_id IS 'Campaign ID in external DSP';

-- ============================================================================
-- TABLE 9: campaign_metrics (Daily Aggregated Metrics)
-- ============================================================================

CREATE TABLE IF NOT EXISTS campaign_metrics (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    campaign_id UUID NOT NULL REFERENCES campaigns(id) ON DELETE CASCADE,
    org_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    impressions BIGINT DEFAULT 0 CHECK (impressions >= 0),
    clicks BIGINT DEFAULT 0 CHECK (clicks >= 0),
    conversions BIGINT DEFAULT 0 CHECK (conversions >= 0),
    spend DECIMAL(15,2) DEFAULT 0 CHECK (spend >= 0),
    revenue DECIMAL(15,2) DEFAULT 0 CHECK (revenue >= 0),
    ctr DECIMAL(5,4),  -- Click-through rate
    cpc DECIMAL(10,4), -- Cost per click
    cpa DECIMAL(10,4), -- Cost per acquisition
    roas DECIMAL(10,4), -- Return on ad spend
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE(campaign_id, date)
);

CREATE INDEX idx_campaign_metrics_campaign_id ON campaign_metrics(campaign_id);
CREATE INDEX idx_campaign_metrics_org_id ON campaign_metrics(org_id);
CREATE INDEX idx_campaign_metrics_date ON campaign_metrics(date);
CREATE INDEX idx_campaign_metrics_org_date ON campaign_metrics(org_id, date);

COMMENT ON TABLE campaign_metrics IS 'Daily aggregated campaign performance metrics';

-- ============================================================================
-- TABLE 10: etl_jobs (ETL Job Tracking)
-- ============================================================================

CREATE TABLE IF NOT EXISTS etl_jobs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    org_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    job_type VARCHAR(50) NOT NULL CHECK (job_type IN ('extract', 'transform', 'load', 'sync')),
    source VARCHAR(100),
    destination VARCHAR(100),
    status VARCHAR(50) DEFAULT 'pending' CHECK (status IN ('pending', 'running', 'completed', 'failed', 'cancelled')),
    records_processed BIGINT DEFAULT 0,
    records_failed BIGINT DEFAULT 0,
    started_at TIMESTAMP,
    completed_at TIMESTAMP,
    error_message TEXT,
    metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT etl_jobs_times CHECK (completed_at IS NULL OR completed_at >= started_at)
);

CREATE INDEX idx_etl_jobs_org_id ON etl_jobs(org_id);
CREATE INDEX idx_etl_jobs_status ON etl_jobs(status);
CREATE INDEX idx_etl_jobs_job_type ON etl_jobs(job_type);
CREATE INDEX idx_etl_jobs_created_at ON etl_jobs(created_at);
CREATE INDEX idx_etl_jobs_started_at ON etl_jobs(started_at);

COMMENT ON TABLE etl_jobs IS 'ETL job execution tracking';

-- ============================================================================
-- TABLE 11: notifications (Notification Queue)
-- ============================================================================

CREATE TABLE IF NOT EXISTS notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    org_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    type VARCHAR(50) NOT NULL CHECK (type IN ('email', 'slack', 'webhook', 'sms', 'push')),
    recipient VARCHAR(255) NOT NULL,
    subject VARCHAR(255),
    body TEXT,
    template_id VARCHAR(100),
    template_data JSONB,
    status VARCHAR(50) DEFAULT 'pending' CHECK (status IN ('pending', 'sent', 'failed', 'cancelled')),
    priority INTEGER DEFAULT 5 CHECK (priority BETWEEN 1 AND 10),
    scheduled_at TIMESTAMP,
    sent_at TIMESTAMP,
    error_message TEXT,
    retry_count INTEGER DEFAULT 0,
    metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT notifications_scheduled_future CHECK (scheduled_at IS NULL OR scheduled_at >= created_at)
);

CREATE INDEX idx_notifications_org_id ON notifications(org_id);
CREATE INDEX idx_notifications_user_id ON notifications(user_id);
CREATE INDEX idx_notifications_type ON notifications(type);
CREATE INDEX idx_notifications_status ON notifications(status);
CREATE INDEX idx_notifications_created_at ON notifications(created_at);
CREATE INDEX idx_notifications_scheduled_at ON notifications(scheduled_at) WHERE scheduled_at IS NOT NULL;
CREATE INDEX idx_notifications_pending ON notifications(status, priority, created_at) WHERE status = 'pending';

COMMENT ON TABLE notifications IS 'Notification delivery queue';

-- ============================================================================
-- TABLE 12: audit_logs (Audit Trail)
-- ============================================================================

CREATE TABLE IF NOT EXISTS audit_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    org_id UUID NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    action VARCHAR(100) NOT NULL,
    resource_type VARCHAR(50),
    resource_id UUID,
    old_values JSONB,
    new_values JSONB,
    ip_address INET,
    user_agent TEXT,
    request_id VARCHAR(100),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_audit_logs_org_id ON audit_logs(org_id);
CREATE INDEX idx_audit_logs_user_id ON audit_logs(user_id);
CREATE INDEX idx_audit_logs_action ON audit_logs(action);
CREATE INDEX idx_audit_logs_resource ON audit_logs(resource_type, resource_id);
CREATE INDEX idx_audit_logs_created_at ON audit_logs(created_at);

-- Partition by month for large scale
-- CREATE INDEX idx_audit_logs_org_month ON audit_logs(org_id, date_trunc('month', created_at));

COMMENT ON TABLE audit_logs IS 'Complete audit trail for all actions';

-- ============================================================================
-- INSERT DEFAULT DATA
-- ============================================================================

-- Insert default permissions
INSERT INTO permissions (id, resource, action, description) VALUES
    ('11111111-1111-1111-1111-111111111101', 'campaigns', 'create', 'Create campaigns'),
    ('11111111-1111-1111-1111-111111111102', 'campaigns', 'read', 'View campaigns'),
    ('11111111-1111-1111-1111-111111111103', 'campaigns', 'update', 'Update campaigns'),
    ('11111111-1111-1111-1111-111111111104', 'campaigns', 'delete', 'Delete campaigns'),
    ('11111111-1111-1111-1111-111111111105', 'reports', 'read', 'View reports'),
    ('11111111-1111-1111-1111-111111111106', 'reports', 'export', 'Export reports'),
    ('11111111-1111-1111-1111-111111111107', 'users', 'manage', 'Manage users'),
    ('11111111-1111-1111-1111-111111111108', 'connectors', 'manage', 'Manage DSP connectors'),
    ('11111111-1111-1111-1111-111111111109', 'settings', 'manage', 'Manage organization settings')
ON CONFLICT (resource, action) DO NOTHING;

-- Insert default role permissions
INSERT INTO role_permissions (role, permission_id)
SELECT 'admin', id FROM permissions
ON CONFLICT DO NOTHING;

INSERT INTO role_permissions (role, permission_id)
SELECT 'user', id FROM permissions WHERE action = 'read'
ON CONFLICT DO NOTHING;

INSERT INTO role_permissions (role, permission_id)
SELECT 'viewer', id FROM permissions WHERE resource IN ('campaigns', 'reports') AND action = 'read'
ON CONFLICT DO NOTHING;

-- ============================================================================
-- CREATE FUNCTIONS & TRIGGERS
-- ============================================================================

-- Function: Update updated_at column
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Add updated_at triggers
CREATE TRIGGER update_organizations_updated_at BEFORE UPDATE ON organizations
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_dsp_connectors_updated_at BEFORE UPDATE ON dsp_connectors
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_campaigns_updated_at BEFORE UPDATE ON campaigns
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_campaign_metrics_updated_at BEFORE UPDATE ON campaign_metrics
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- GRANT PERMISSIONS (Adjust as needed)
-- ============================================================================

-- Grant read-only access to analytics role
-- GRANT SELECT ON ALL TABLES IN SCHEMA public TO analytics_role;

-- Grant read-write access to application role
-- GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO app_role;

-- ============================================================================
-- VACUUM ANALYZE
-- ============================================================================

VACUUM ANALYZE;

-- Done!
SELECT 'Initial schema created successfully!' AS status;
