-- ============================================================================
-- Campaign Lifecycle Platform - Development Seed Data
-- Version: 1.0.0
-- Date: 2026-01-07
-- Description: Comprehensive seed data for local development and testing
-- ============================================================================

-- NOTE: All passwords are 'password123' (bcrypt hash below)
-- Generated with: bcrypt.hashpw('password123', bcrypt.gensalt(12))

-- ============================================================================
-- ORGANIZATIONS (3 test orgs representing different sizes)
-- ============================================================================

INSERT INTO organizations (id, name, slug, domain, status, plan, monthly_budget, industry, company_size, settings, created_at) VALUES
(
    '11111111-1111-1111-1111-111111111111',
    'Acme Corporation',
    'acme-corp',
    'acme.com',
    'active',
    'enterprise',
    50000.00,
    'E-commerce',
    '1000-5000',
    '{"timezone": "America/New_York", "locale": "en-US", "features": ["pacing", "margin", "qa", "alerts"]}'::jsonb,
    '2024-01-15 10:00:00'
),
(
    '22222222-2222-2222-2222-222222222222',
    'Globex Industries',
    'globex-ind',
    'globex.com',
    'active',
    'professional',
    25000.00,
    'Technology',
    '500-1000',
    '{"timezone": "America/Los_Angeles", "locale": "en-US", "features": ["pacing", "alerts"]}'::jsonb,
    '2024-02-01 14:30:00'
),
(
    '33333333-3333-3333-3333-333333333333',
    'Initech Solutions',
    'initech',
    'initech.com',
    'trial',
    'free',
    5000.00,
    'Consulting',
    '50-100',
    '{"timezone": "America/Chicago", "locale": "en-US", "features": ["pacing"]}'::jsonb,
    '2024-11-20 09:15:00'
)
ON CONFLICT (id) DO NOTHING;

-- ============================================================================
-- USERS (9 users across different roles)
-- ============================================================================

-- Password: password123
-- Hash: $2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5NU7667KqzWbe

INSERT INTO users (id, email, password_hash, name, auth_provider, is_active, email_verified, timezone, locale, created_at) VALUES
-- Acme users
(
    'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
    'admin@acme.com',
    '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5NU7667KqzWbe',
    'Alice Admin',
    'local',
    true,
    true,
    'America/New_York',
    'en-US',
    '2024-01-15 10:05:00'
),
(
    'aaaaaaaa-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
    'dev@acme.com',
    '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5NU7667KqzWbe',
    'Bob Developer',
    'local',
    true,
    true,
    'America/New_York',
    'en-US',
    '2024-01-15 11:00:00'
),
(
    'aaaaaaaa-cccc-cccc-cccc-cccccccccccc',
    'analyst@acme.com',
    '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5NU7667KqzWbe',
    'Carol Analyst',
    'local',
    true,
    true,
    'America/New_York',
    'en-US',
    '2024-01-20 09:00:00'
),
-- Globex users
(
    'bbbbbbbb-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
    'admin@globex.com',
    '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5NU7667KqzWbe',
    'David Manager',
    'local',
    true,
    true,
    'America/Los_Angeles',
    'en-US',
    '2024-02-01 14:35:00'
),
(
    'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
    'dev@globex.com',
    '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5NU7667KqzWbe',
    'Eve Engineer',
    'google',
    true,
    true,
    'America/Los_Angeles',
    'en-US',
    '2024-02-02 10:00:00'
),
(
    'bbbbbbbb-cccc-cccc-cccc-cccccccccccc',
    'viewer@globex.com',
    '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5NU7667KqzWbe',
    'Frank Viewer',
    'local',
    true,
    true,
    'America/Los_Angeles',
    'en-US',
    '2024-02-10 15:30:00'
),
-- Initech users
(
    'cccccccc-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
    'owner@initech.com',
    '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5NU7667KqzWbe',
    'Grace Owner',
    'local',
    true,
    true,
    'America/Chicago',
    'en-US',
    '2024-11-20 09:20:00'
),
(
    'cccccccc-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
    'analyst@initech.com',
    '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5NU7667KqzWbe',
    'Henry Analyst',
    'local',
    true,
    true,
    'America/Chicago',
    'en-US',
    '2024-11-25 10:00:00'
),
-- Inactive user for testing
(
    'dddddddd-dddd-dddd-dddd-dddddddddddd',
    'inactive@example.com',
    '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5NU7667KqzWbe',
    'Inactive User',
    'local',
    false,
    false,
    'UTC',
    'en-US',
    '2024-06-01 12:00:00'
)
ON CONFLICT (id) DO NOTHING;

-- ============================================================================
-- ORG MEMBERSHIPS (User-Organization relationships)
-- ============================================================================

INSERT INTO org_memberships (id, org_id, user_id, role, is_active, joined_at) VALUES
-- Acme memberships
(uuid_generate_v4(), '11111111-1111-1111-1111-111111111111', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'admin', true, '2024-01-15 10:05:00'),
(uuid_generate_v4(), '11111111-1111-1111-1111-111111111111', 'aaaaaaaa-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'developer', true, '2024-01-15 11:00:00'),
(uuid_generate_v4(), '11111111-1111-1111-1111-111111111111', 'aaaaaaaa-cccc-cccc-cccc-cccccccccccc', 'analyst', true, '2024-01-20 09:00:00'),

-- Globex memberships
(uuid_generate_v4(), '22222222-2222-2222-2222-222222222222', 'bbbbbbbb-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'admin', true, '2024-02-01 14:35:00'),
(uuid_generate_v4(), '22222222-2222-2222-2222-222222222222', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'developer', true, '2024-02-02 10:00:00'),
(uuid_generate_v4(), '22222222-2222-2222-2222-222222222222', 'bbbbbbbb-cccc-cccc-cccc-cccccccccccc', 'viewer', true, '2024-02-10 15:30:00'),

-- Initech memberships
(uuid_generate_v4(), '33333333-3333-3333-3333-333333333333', 'cccccccc-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'admin', true, '2024-11-20 09:20:00'),
(uuid_generate_v4(), '33333333-3333-3333-3333-333333333333', 'cccccccc-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'analyst', true, '2024-11-25 10:00:00')
ON CONFLICT (org_id, user_id) DO NOTHING;

-- ============================================================================
-- AUTH TOKENS (Active sessions and API keys)
-- ============================================================================

INSERT INTO auth_tokens (id, user_id, org_id, token_type, token_hash, token_prefix, scopes, expires_at, last_used_at) VALUES
-- Access tokens (valid for 1 hour)
(
    uuid_generate_v4(),
    'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
    '11111111-1111-1111-1111-111111111111',
    'access',
    encode(digest('access_token_alice_' || NOW()::text, 'sha256'), 'hex'),
    'at_alice',
    '["read", "write"]'::jsonb,
    NOW() + INTERVAL '1 hour',
    NOW() - INTERVAL '5 minutes'
),
(
    uuid_generate_v4(),
    'bbbbbbbb-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
    '22222222-2222-2222-2222-222222222222',
    'access',
    encode(digest('access_token_david_' || NOW()::text, 'sha256'), 'hex'),
    'at_david',
    '["read", "write"]'::jsonb,
    NOW() + INTERVAL '1 hour',
    NOW() - INTERVAL '10 minutes'
),

-- API keys (valid for 1 year)
(
    uuid_generate_v4(),
    'aaaaaaaa-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
    '11111111-1111-1111-1111-111111111111',
    'api_key',
    encode(digest('api_key_bob_dev', 'sha256'), 'hex'),
    'pk_live_acme',
    '["pipelines:execute", "campaigns:read", "metrics:read"]'::jsonb,
    NOW() + INTERVAL '1 year',
    NOW() - INTERVAL '2 days'
),
(
    uuid_generate_v4(),
    'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
    '22222222-2222-2222-2222-222222222222',
    'api_key',
    encode(digest('api_key_eve_dev', 'sha256'), 'hex'),
    'pk_test_globex',
    '["pipelines:execute"]'::jsonb,
    NOW() + INTERVAL '1 year',
    NULL
)
ON CONFLICT (token_hash) DO NOTHING;

-- ============================================================================
-- DSP ACCOUNTS (DSP Integrations)
-- ============================================================================

INSERT INTO dsp_accounts (id, org_id, dsp_type, external_account_id, display_name, oauth_token_path, rate_limit_config, is_active, last_sync_at, currency, account_timezone) VALUES
-- Acme DSP accounts
(
    '10000000-0000-0000-0000-000000000001',
    '11111111-1111-1111-1111-111111111111',
    'dv360',
    '12345678',
    'Acme DV360 Main',
    'secret/data/dsp/dv360/acme-main',
    '{"requests_per_minute": 60, "requests_per_hour": 3000, "requests_per_day": 50000}'::jsonb,
    true,
    NOW() - INTERVAL '2 hours',
    'USD',
    'America/New_York'
),
(
    '10000000-0000-0000-0000-000000000002',
    '11111111-1111-1111-1111-111111111111',
    'meta',
    'act_1234567890',
    'Acme Meta Ads',
    'secret/data/dsp/meta/acme',
    '{"requests_per_minute": 200, "requests_per_hour": 10000}'::jsonb,
    true,
    NOW() - INTERVAL '1 hour',
    'USD',
    'America/New_York'
),
(
    '10000000-0000-0000-0000-000000000003',
    '11111111-1111-1111-1111-111111111111',
    'ttd',
    'acme-ttd-advertiser',
    'Acme TTD',
    'secret/data/dsp/ttd/acme',
    '{"requests_per_minute": 100, "requests_per_hour": 5000}'::jsonb,
    true,
    NOW() - INTERVAL '30 minutes',
    'USD',
    'America/New_York'
),

-- Globex DSP accounts
(
    '20000000-0000-0000-0000-000000000001',
    '22222222-2222-2222-2222-222222222222',
    'dv360',
    '87654321',
    'Globex DV360',
    'secret/data/dsp/dv360/globex',
    '{"requests_per_minute": 60, "requests_per_hour": 3000, "requests_per_day": 50000}'::jsonb,
    true,
    NOW() - INTERVAL '3 hours',
    'USD',
    'America/Los_Angeles'
),
(
    '20000000-0000-0000-0000-000000000002',
    '22222222-2222-2222-2222-222222222222',
    'google_ads',
    '9876543210',
    'Globex Google Ads',
    'secret/data/dsp/google-ads/globex',
    '{"requests_per_minute": 100, "requests_per_hour": 10000}'::jsonb,
    true,
    NOW() - INTERVAL '1 hour',
    'USD',
    'America/Los_Angeles'
),

-- Initech DSP account
(
    '30000000-0000-0000-0000-000000000001',
    '33333333-3333-3333-3333-333333333333',
    'meta',
    'act_9876543210',
    'Initech Meta',
    'secret/data/dsp/meta/initech',
    '{"requests_per_minute": 200, "requests_per_hour": 10000}'::jsonb,
    true,
    NOW() - INTERVAL '6 hours',
    'USD',
    'America/Chicago'
)
ON CONFLICT (org_id, dsp_type, external_account_id) DO NOTHING;

-- ============================================================================
-- TEMPLATES (Public and Private Templates)
-- ============================================================================

INSERT INTO templates (id, name, description, category, template_type, dsp_type, config, default_params, required_inputs, optional_inputs, is_public, usage_count, satisfaction_rating, version) VALUES
-- Public DV360 templates
(
    '40000000-0000-0000-0000-000000000001',
    'DV360 Daily Performance',
    'Standard daily campaign performance report with key metrics',
    'reporting',
    'pipeline',
    'dv360',
    '{"report_type": "campaign_performance", "metrics": ["impressions", "clicks", "conversions", "spend", "ctr", "cpa"], "dimensions": ["date", "campaign_id"]}'::jsonb,
    '{"schedule": "0 6 * * *", "timezone": "America/New_York"}'::jsonb,
    '["account_id", "date_range"]'::jsonb,
    '["additional_metrics", "filters"]'::jsonb,
    true,
    156,
    4.7,
    1
),
(
    '40000000-0000-0000-0000-000000000002',
    'DV360 Pacing Check',
    'Daily pacing validation against flight schedule',
    'qa',
    'rule',
    'dv360',
    '{"conditions": {"logic": "AND", "rules": [{"field": "pacing_rate", "operator": ">", "value": 120}]}, "actions": [{"type": "alert", "severity": "high"}]}'::jsonb,
    '{"threshold": 120}'::jsonb,
    '["campaigns"]'::jsonb,
    '["notification_channels"]'::jsonb,
    true,
    89,
    4.5,
    1
),

-- Public Meta templates
(
    '40000000-0000-0000-0000-000000000003',
    'Meta Campaign Insights',
    'Comprehensive Meta campaign performance metrics',
    'reporting',
    'pipeline',
    'meta',
    '{"report_type": "campaign_insights", "metrics": ["impressions", "clicks", "conversions", "spend", "cpc", "cpm", "roas"], "level": "campaign"}'::jsonb,
    '{"schedule": "0 7 * * *", "timezone": "UTC"}'::jsonb,
    '["account_id"]'::jsonb,
    '["breakdown", "time_increment"]'::jsonb,
    true,
    203,
    4.8,
    1
),

-- Acme private template
(
    '40000000-1111-0000-0000-000000000001',
    'Acme Custom QA Rules',
    'Custom quality assurance rules for Acme campaigns',
    'qa',
    'rule',
    NULL,
    '{"conditions": {"logic": "AND", "rules": [{"field": "ctr", "operator": "<", "value": 0.5}, {"field": "spend", "operator": ">", "value": 1000}]}, "actions": [{"type": "alert", "severity": "medium"}, {"type": "slack", "channel": "#campaign-alerts"}]}'::jsonb,
    '{}'::jsonb,
    '[]'::jsonb,
    '[]'::jsonb,
    false,
    12,
    NULL,
    1
),
(
    '40000000-1111-0000-0000-000000000002',
    'Acme Margin Calculator',
    'Calculate margin with Acme-specific formula',
    'calculation',
    'pipeline',
    NULL,
    '{"formula": "revenue - cost - agency_fee", "agency_fee_pct": 15}'::jsonb,
    '{"agency_fee_pct": 15}'::jsonb,
    '["campaigns"]'::jsonb,
    '[]'::jsonb,
    false,
    8,
    NULL,
    1
)
ON CONFLICT (id) DO NOTHING;

-- ============================================================================
-- PIPELINES (ETL Workflow Instances)
-- ============================================================================

INSERT INTO pipelines (id, org_id, name, description, dsp_account_id, template_id, connector_type, schedule_type, schedule_cron, schedule_timezone, config, status, is_active, created_by, last_run_at, last_run_status, next_run_at, total_executions, successful_executions, failed_executions) VALUES
-- Acme pipelines
(
    '50000000-1111-0000-0000-000000000001',
    '11111111-1111-1111-1111-111111111111',
    'DV360 Daily Sync',
    'Daily sync of DV360 campaign performance',
    '10000000-0000-0000-0000-000000000001',
    '40000000-0000-0000-0000-000000000001',
    'dv360',
    'cron',
    '0 6 * * *',
    'America/New_York',
    '{"metrics": ["impressions", "clicks", "conversions", "spend"], "date_range": "yesterday", "lookback_days": 1}'::jsonb,
    'active',
    true,
    'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
    NOW() - INTERVAL '18 hours',
    'completed',
    NOW() + INTERVAL '6 hours',
    45,
    44,
    1
),
(
    '50000000-1111-0000-0000-000000000002',
    '11111111-1111-1111-1111-111111111111',
    'Meta Hourly Refresh',
    'Hourly refresh of Meta campaign data',
    '10000000-0000-0000-0000-000000000002',
    '40000000-0000-0000-0000-000000000003',
    'meta',
    'cron',
    '0 * * * *',
    'America/New_York',
    '{"metrics": ["impressions", "clicks", "spend", "roas"], "time_increment": 1}'::jsonb,
    'active',
    true,
    'aaaaaaaa-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
    NOW() - INTERVAL '1 hour',
    'completed',
    NOW() + INTERVAL '55 minutes',
    156,
    154,
    2
),
(
    '50000000-1111-0000-0000-000000000003',
    '11111111-1111-1111-1111-111111111111',
    'TTD Weekly Report',
    'Weekly performance summary for TTD campaigns',
    '10000000-0000-0000-0000-000000000003',
    NULL,
    'ttd',
    'cron',
    '0 9 * * 1',
    'America/New_York',
    '{"metrics": ["impressions", "clicks", "conversions", "spend", "ctr"], "date_range": "last_7_days"}'::jsonb,
    'active',
    true,
    'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
    NOW() - INTERVAL '4 days',
    'completed',
    NOW() + INTERVAL '3 days',
    12,
    12,
    0
),

-- Globex pipelines
(
    '50000000-2222-0000-0000-000000000001',
    '22222222-2222-2222-2222-222222222222',
    'DV360 Daily Reports',
    'Daily campaign reporting for Globex',
    '20000000-0000-0000-0000-000000000001',
    '40000000-0000-0000-0000-000000000001',
    'dv360',
    'cron',
    '0 7 * * *',
    'America/Los_Angeles',
    '{"metrics": ["impressions", "clicks", "conversions", "spend"], "date_range": "yesterday"}'::jsonb,
    'active',
    true,
    'bbbbbbbb-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
    NOW() - INTERVAL '17 hours',
    'completed',
    NOW() + INTERVAL '7 hours',
    28,
    28,
    0
),

-- Initech pipeline (recently created)
(
    '50000000-3333-0000-0000-000000000001',
    '33333333-3333-3333-3333-333333333333',
    'Meta Daily Sync',
    'Daily Meta campaign performance sync',
    '30000000-0000-0000-0000-000000000001',
    '40000000-0000-0000-0000-000000000003',
    'meta',
    'cron',
    '0 8 * * *',
    'America/Chicago',
    '{"metrics": ["impressions", "clicks", "spend"]}'::jsonb,
    'active',
    true,
    'cccccccc-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
    NOW() - INTERVAL '16 hours',
    'completed',
    NOW() + INTERVAL '8 hours',
    5,
    5,
    0
)
ON CONFLICT (org_id, name) DO NOTHING;

-- ============================================================================
-- RULES (Business Rules for Alerts, QA, etc.)
-- ============================================================================

INSERT INTO rules (id, org_id, name, description, module, rule_type, conditions, actions, priority, is_enabled, pipeline_id, execution_count, match_count, created_by) VALUES
-- Acme rules
(
    '60000000-1111-0000-0000-000000000001',
    '11111111-1111-1111-1111-111111111111',
    'High Pacing Alert',
    'Alert when campaign is pacing above 120%',
    'pacing',
    'threshold_check',
    '{"logic": "AND", "conditions": [{"field": "pacing_rate", "operator": ">", "value": 120}, {"field": "days_remaining", "operator": ">", "value": 3}]}'::jsonb,
    '[{"type": "email", "recipients": ["admin@acme.com"], "severity": "high"}, {"type": "slack", "channel": "#alerts"}]'::jsonb,
    1,
    true,
    '50000000-1111-0000-0000-000000000001',
    145,
    12,
    'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'
),
(
    '60000000-1111-0000-0000-000000000002',
    '11111111-1111-1111-1111-111111111111',
    'Low CTR Warning',
    'Warn when CTR drops below 0.5%',
    'qa',
    'performance_check',
    '{"logic": "AND", "conditions": [{"field": "ctr", "operator": "<", "value": 0.5}, {"field": "impressions", "operator": ">", "value": 10000}]}'::jsonb,
    '[{"type": "email", "recipients": ["analyst@acme.com"], "severity": "medium"}]'::jsonb,
    2,
    true,
    '50000000-1111-0000-0000-000000000001',
    145,
    8,
    'aaaaaaaa-cccc-cccc-cccc-cccccccccccc'
),
(
    '60000000-1111-0000-0000-000000000003',
    '11111111-1111-1111-1111-111111111111',
    'Naming Convention Check',
    'Validate campaign naming follows Acme standards',
    'taxonomy',
    'naming_validation',
    '{"logic": "OR", "conditions": [{"field": "campaign_name", "operator": "not_matches", "value": "^ACME_[A-Z0-9]+_.*"}, {"field": "campaign_name", "operator": "contains", "value": "test", "ignore_case": true}]}'::jsonb,
    '[{"type": "slack", "channel": "#qa-alerts", "severity": "low"}]'::jsonb,
    3,
    true,
    NULL,
    89,
    15,
    'aaaaaaaa-bbbb-bbbb-bbbb-bbbbbbbbbbbb'
),

-- Globex rules
(
    '60000000-2222-0000-0000-000000000001',
    '22222222-2222-2222-2222-222222222222',
    'Budget Overspend Alert',
    'Alert when spend exceeds budget by 10%',
    'alerts',
    'budget_check',
    '{"logic": "AND", "conditions": [{"field": "spend_pct", "operator": ">", "value": 110}, {"field": "status", "operator": "=", "value": "active"}]}'::jsonb,
    '[{"type": "email", "recipients": ["admin@globex.com"], "severity": "critical"}]'::jsonb,
    1,
    true,
    '50000000-2222-0000-0000-000000000001',
    28,
    2,
    'bbbbbbbb-aaaa-aaaa-aaaa-aaaaaaaaaaaa'
),

-- Initech rule
(
    '60000000-3333-0000-0000-000000000001',
    '33333333-3333-3333-3333-333333333333',
    'Daily Spend Limit',
    'Alert when daily spend exceeds $500',
    'alerts',
    'spend_check',
    '{"logic": "AND", "conditions": [{"field": "daily_spend", "operator": ">", "value": 500}]}'::jsonb,
    '[{"type": "email", "recipients": ["owner@initech.com"], "severity": "high"}]'::jsonb,
    1,
    true,
    '50000000-3333-0000-0000-000000000001',
    5,
    0,
    'cccccccc-aaaa-aaaa-aaaa-aaaaaaaaaaaa'
)
ON CONFLICT (org_id, module, name, version) DO NOTHING;

-- ============================================================================
-- CAMPAIGNS (Sample campaign data from DSPs)
-- ============================================================================

INSERT INTO campaigns (id, org_id, dsp_account_id, dsp_type, external_id, name, advertiser_id, advertiser_name, status, budget, currency, budget_type, start_date, end_date, config, labels) VALUES
-- Acme DV360 campaigns
(
    '70000000-1111-0001-0000-000000000001',
    '11111111-1111-1111-1111-111111111111',
    '10000000-0000-0000-0000-000000000001',
    'dv360',
    'dv360-camp-12345',
    'ACME_Q1_ECOM_Prospecting',
    'adv-11111',
    'Acme E-commerce',
    'active',
    50000.00,
    'USD',
    'flight',
    '2025-01-01',
    '2025-03-31',
    '{"targeting": {"geo": ["US"], "age": "25-54", "interests": ["shopping"]}, "bidding_strategy": "maximize_conversions"}'::jsonb,
    '["Q1", "prospecting", "ecommerce"]'::jsonb
),
(
    '70000000-1111-0001-0000-000000000002',
    '11111111-1111-1111-1111-111111111111',
    '10000000-0000-0000-0000-000000000001',
    'dv360',
    'dv360-camp-12346',
    'ACME_Q1_ECOM_Retargeting',
    'adv-11111',
    'Acme E-commerce',
    'active',
    30000.00,
    'USD',
    'flight',
    '2025-01-01',
    '2025-03-31',
    '{"targeting": {"geo": ["US"], "audience": "remarketing_list"}, "bidding_strategy": "target_cpa", "target_cpa": 25.00}'::jsonb,
    '["Q1", "retargeting", "ecommerce"]'::jsonb
),

-- Acme Meta campaigns
(
    '70000000-1111-0002-0000-000000000001',
    '11111111-1111-1111-1111-111111111111',
    '10000000-0000-0000-0000-000000000002',
    'meta',
    'meta-camp-98765',
    'ACME_Holiday_FB_Conversions',
    'act_1234567890',
    'Acme Meta Account',
    'paused',
    25000.00,
    'USD',
    'lifetime',
    '2024-11-15',
    '2024-12-31',
    '{"objective": "CONVERSIONS", "optimization_goal": "PURCHASES", "placements": ["facebook", "instagram"]}'::jsonb,
    '["holiday", "conversions", "completed"]'::jsonb
),

-- Globex campaigns
(
    '70000000-2222-0001-0000-000000000001',
    '22222222-2222-2222-2222-222222222222',
    '20000000-0000-0000-0000-000000000001',
    'dv360',
    'dv360-camp-54321',
    'Globex_Tech_Launch_Awareness',
    'adv-22222',
    'Globex Tech',
    'active',
    75000.00,
    'USD',
    'flight',
    '2025-01-15',
    '2025-04-15',
    '{"targeting": {"geo": ["US", "CA"], "interests": ["technology", "innovation"]}, "bidding_strategy": "maximize_reach"}'::jsonb,
    '["product_launch", "awareness"]'::jsonb
),

-- Initech campaign
(
    '70000000-3333-0001-0000-000000000001',
    '33333333-3333-3333-3333-333333333333',
    '30000000-0000-0000-0000-000000000001',
    'meta',
    'meta-camp-11111',
    'Initech_Services_LeadGen',
    'act_9876543210',
    'Initech Consulting',
    'active',
    5000.00,
    'USD',
    'daily',
    '2024-12-01',
    '2025-02-28',
    '{"objective": "LEAD_GENERATION", "optimization_goal": "LEADS", "form_id": "form_12345"}'::jsonb,
    '["lead_gen", "consulting"]'::jsonb
)
ON CONFLICT (org_id, dsp_type, external_id) DO NOTHING;

-- ============================================================================
-- CAMPAIGN METRICS (Performance data for campaigns)
-- ============================================================================

-- Generate 7 days of metrics for each active campaign
INSERT INTO campaign_metrics (id, campaign_id, org_id, metric_date, impressions, clicks, conversions, spend, revenue, ctr, cpc, cpa, roas, synced_at) 
SELECT 
    uuid_generate_v4(),
    c.id,
    c.org_id,
    d.metric_date,
    -- Simulate realistic daily metrics with some variance
    (random() * 50000 + 10000)::bigint,  -- impressions: 10k-60k
    (random() * 1000 + 100)::bigint,      -- clicks: 100-1100
    (random() * 50 + 5)::bigint,          -- conversions: 5-55
    (random() * 2000 + 500)::numeric(15,2),  -- spend: $500-$2500
    (random() * 4000 + 1000)::numeric(15,2), -- revenue: $1000-$5000
    (random() * 2 + 0.5)::numeric(5,4),   -- ctr: 0.5%-2.5%
    (random() * 5 + 1)::numeric(10,4),    -- cpc: $1-$6
    (random() * 100 + 20)::numeric(10,4), -- cpa: $20-$120
    (random() * 3 + 1)::numeric(10,4),    -- roas: 1x-4x
    NOW() - (7 - d.day) * INTERVAL '1 day' + INTERVAL '6 hours'
FROM campaigns c
CROSS JOIN (
    SELECT 
        (CURRENT_DATE - s.day) AS metric_date,
        s.day
    FROM generate_series(0, 6) AS s(day)
) d
WHERE c.status = 'active'
ON CONFLICT (campaign_id, metric_date) DO NOTHING;

-- ============================================================================
-- ETL EXECUTIONS (Pipeline execution history)
-- ============================================================================

INSERT INTO etl_executions (id, pipeline_id, org_id, execution_type, status, bronze_status, bronze_records, bronze_size_bytes, bronze_duration_ms, silver_status, silver_records, silver_records_filtered, silver_duration_ms, gold_status, gold_tables_updated, gold_duration_ms, total_records_processed, total_records_failed, total_duration_ms, started_at, completed_at, workflow_id) VALUES
-- Successful execution
(
    uuid_generate_v4(),
    '50000000-1111-0000-0000-000000000001',
    '11111111-1111-1111-1111-111111111111',
    'scheduled',
    'completed',
    'completed',
    125000,
    45678900,
    3200,
    'completed',
    124850,
    150,
    5600,
    'completed',
    '["campaign_daily", "pacing_metrics"]'::jsonb,
    2100,
    124850,
    150,
    10900,
    NOW() - INTERVAL '18 hours',
    NOW() - INTERVAL '18 hours' + INTERVAL '11 seconds',
    'workflow_dv360_daily_' || to_char(NOW() - INTERVAL '18 hours', 'YYYYMMDD_HH24MISS')
),

-- Failed execution with error
(
    uuid_generate_v4(),
    '50000000-1111-0000-0000-000000000002',
    '11111111-1111-1111-1111-111111111111',
    'scheduled',
    'failed',
    'completed',
    89000,
    32145600,
    2800,
    'failed',
    0,
    0,
    NULL,
    NULL,
    NULL,
    NULL,
    0,
    89000,
    2800,
    NOW() - INTERVAL '25 hours',
    NOW() - INTERVAL '25 hours' + INTERVAL '3 seconds',
    'workflow_meta_hourly_' || to_char(NOW() - INTERVAL '25 hours', 'YYYYMMDD_HH24MISS')
),

-- Running execution
(
    uuid_generate_v4(),
    '50000000-2222-0000-0000-000000000001',
    '22222222-2222-2222-2222-222222222222',
    'manual',
    'running',
    'completed',
    67000,
    24567800,
    2100,
    'running',
    NULL,
    NULL,
    NULL,
    NULL,
    NULL,
    NULL,
    0,
    0,
    NULL,
    NOW() - INTERVAL '3 minutes',
    NULL,
    'workflow_dv360_manual_' || to_char(NOW(), 'YYYYMMDD_HH24MISS')
)
ON CONFLICT (id) DO NOTHING;

-- ============================================================================
-- DATA QUALITY METRICS (DQ tracking for executions)
-- ============================================================================

INSERT INTO data_quality_metrics (id, execution_id, pipeline_id, org_id, layer, metric_type, metric_name, check_count, pass_count, fail_count, severity, details) VALUES
(
    uuid_generate_v4(),
    (SELECT id FROM etl_executions WHERE status = 'completed' LIMIT 1),
    '50000000-1111-0000-0000-000000000001',
    '11111111-1111-1111-1111-111111111111',
    'bronze',
    'completeness',
    'required_fields',
    125000,
    124850,
    150,
    'warning',
    '{"missing_fields": ["creative_id"], "sample_count": 150}'::jsonb
),
(
    uuid_generate_v4(),
    (SELECT id FROM etl_executions WHERE status = 'completed' LIMIT 1),
    '50000000-1111-0000-0000-000000000001',
    '11111111-1111-1111-1111-111111111111',
    'silver',
    'validation',
    'data_types',
    124850,
    124850,
    0,
    'info',
    '{"validated_columns": ["impressions", "clicks", "spend"]}'::jsonb
)
ON CONFLICT (id) DO NOTHING;

-- ============================================================================
-- NOTIFICATIONS (Notification queue)
-- ============================================================================

INSERT INTO notifications (id, org_id, user_id, type, channel, recipient, subject, body, template_id, status, priority, scheduled_at, entity_type, entity_id) VALUES
-- Sent notification
(
    uuid_generate_v4(),
    '11111111-1111-1111-1111-111111111111',
    'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
    'email',
    'email',
    'admin@acme.com',
    'High Pacing Alert: ACME_Q1_ECOM_Prospecting',
    'Campaign ACME_Q1_ECOM_Prospecting is pacing at 125% with 15 days remaining.',
    'alert_high_pacing',
    'sent',
    8,
    NOW() - INTERVAL '2 hours',
    'campaign',
    '70000000-1111-0001-0000-000000000001'
),

-- Pending notification
(
    uuid_generate_v4(),
    '22222222-2222-2222-2222-222222222222',
    'bbbbbbbb-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
    'slack',
    'slack',
    '#alerts',
    'Pipeline Execution Running',
    'DV360 Daily Reports pipeline is currently running.',
    'pipeline_status',
    'pending',
    5,
    NOW(),
    'pipeline',
    '50000000-2222-0000-0000-000000000001'
),

-- Failed notification (for retry)
(
    uuid_generate_v4(),
    '11111111-1111-1111-1111-111111111111',
    'aaaaaaaa-cccc-cccc-cccc-cccccccccccc',
    'email',
    'email',
    'analyst@acme.com',
    'Low CTR Warning',
    'Campaign ACME_Q1_ECOM_Retargeting has CTR of 0.4% (below threshold of 0.5%)',
    'alert_low_ctr',
    'failed',
    6,
    NOW() - INTERVAL '30 minutes',
    'campaign',
    '70000000-1111-0001-0000-000000000002'
)
ON CONFLICT (id) DO NOTHING;

-- ============================================================================
-- ENTITY PERMISSIONS (Fine-grained access control examples)
-- ============================================================================

INSERT INTO entity_permissions (id, org_id, user_id, entity_type, entity_id, permissions, granted_by) VALUES
-- Grant Carol analyst access to specific DV360 account
(
    uuid_generate_v4(),
    '11111111-1111-1111-1111-111111111111',
    'aaaaaaaa-cccc-cccc-cccc-cccccccccccc',
    'dsp_account',
    '10000000-0000-0000-0000-000000000001',
    '["view", "export"]'::jsonb,
    'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'
),

-- Grant Frank viewer access to specific pipeline
(
    uuid_generate_v4(),
    '22222222-2222-2222-2222-222222222222',
    'bbbbbbbb-cccc-cccc-cccc-cccccccccccc',
    'pipeline',
    '50000000-2222-0000-0000-000000000001',
    '["view"]'::jsonb,
    'bbbbbbbb-aaaa-aaaa-aaaa-aaaaaaaaaaaa'
)
ON CONFLICT (id) DO NOTHING;

-- ============================================================================
-- AUDIT LOGS (Sample audit trail entries)
-- ============================================================================

INSERT INTO audit_logs (id, org_id, user_id, action, resource_type, resource_id, old_values, new_values, ip_address, request_id, success) VALUES
(
    uuid_generate_v4(),
    '11111111-1111-1111-1111-111111111111',
    'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
    'pipeline.created',
    'pipeline',
    '50000000-1111-0000-0000-000000000001',
    NULL,
    '{"name": "DV360 Daily Sync", "status": "draft"}'::jsonb,
    '192.168.1.100'::inet,
    'req_' || md5(random()::text),
    true
),
(
    uuid_generate_v4(),
    '11111111-1111-1111-1111-111111111111',
    'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
    'pipeline.updated',
    'pipeline',
    '50000000-1111-0000-0000-000000000001',
    '{"status": "draft"}'::jsonb,
    '{"status": "active"}'::jsonb,
    '192.168.1.100'::inet,
    'req_' || md5(random()::text),
    true
),
(
    uuid_generate_v4(),
    '22222222-2222-2222-2222-222222222222',
    'bbbbbbbb-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
    'rule.created',
    'rule',
    '60000000-2222-0000-0000-000000000001',
    NULL,
    '{"name": "Budget Overspend Alert", "module": "alerts"}'::jsonb,
    '10.0.0.50'::inet,
    'req_' || md5(random()::text),
    true
),
(
    uuid_generate_v4(),
    '11111111-1111-1111-1111-111111111111',
    'aaaaaaaa-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
    'pipeline.execute',
    'pipeline',
    '50000000-1111-0000-0000-000000000002',
    NULL,
    '{"execution_type": "manual"}'::jsonb,
    '192.168.1.105'::inet,
    'req_' || md5(random()::text),
    false
)
ON CONFLICT (id) DO NOTHING;

-- ============================================================================
-- VERIFICATION QUERIES
-- ============================================================================

-- Count records in each table
DO $$
DECLARE
    rec RECORD;
BEGIN
    RAISE NOTICE '=== Seed Data Summary ===';
    RAISE NOTICE '';
    
    FOR rec IN 
        SELECT 
            schemaname,
            tablename,
            n_tup_ins as row_count
        FROM pg_stat_user_tables 
        WHERE schemaname = 'public'
        ORDER BY tablename
    LOOP
        RAISE NOTICE '% rows in %', rec.row_count, rec.tablename;
    END LOOP;
    
    RAISE NOTICE '';
    RAISE NOTICE '=== Seed Data Loaded Successfully ===';
END $$;

-- ============================================================================
-- HELPFUL QUERIES FOR TESTING
-- ============================================================================

-- List all users with their organizations
-- SELECT u.email, o.name as org_name, om.role 
-- FROM users u 
-- JOIN org_memberships om ON u.id = om.user_id 
-- JOIN organizations o ON om.org_id = o.id;

-- List all pipelines with last execution status
-- SELECT p.name, p.status, p.last_run_status, p.next_run_at 
-- FROM pipelines p 
-- ORDER BY p.last_run_at DESC;

-- List all campaigns with today's metrics
-- SELECT c.name, cm.metric_date, cm.impressions, cm.clicks, cm.spend, cm.ctr 
-- FROM campaigns c 
-- JOIN campaign_metrics cm ON c.id = cm.campaign_id 
-- WHERE cm.metric_date = CURRENT_DATE;

-- Check data quality issues
-- SELECT p.name, dqm.layer, dqm.metric_name, dqm.fail_count 
-- FROM data_quality_metrics dqm 
-- JOIN pipelines p ON dqm.pipeline_id = p.id 
-- WHERE dqm.fail_count > 0;