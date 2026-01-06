# Database Schemas

> PostgreSQL and ClickHouse table definitions.

---

## PostgreSQL Schemas

### Authentication & Users

#### users

```sql
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    full_name VARCHAR(255),
    email_verified BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_users_email ON users(email);
```

#### organizations

```sql
CREATE TABLE organizations (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    slug VARCHAR(255) UNIQUE NOT NULL,
    is_premium BOOLEAN DEFAULT FALSE,
    timezone VARCHAR(50) DEFAULT 'UTC',
    currency VARCHAR(3) DEFAULT 'USD',
    enabled_modules JSONB DEFAULT '[]',
    settings JSONB DEFAULT '{}',
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_organizations_slug ON organizations(slug);
```

#### org_memberships

```sql
CREATE TABLE org_memberships (
    user_id INT REFERENCES users(id) ON DELETE CASCADE,
    org_id INT REFERENCES organizations(id) ON DELETE CASCADE,
    role VARCHAR(50) NOT NULL, -- 'owner', 'admin', 'member', 'viewer'
    invited_by INT REFERENCES users(id),
    joined_at TIMESTAMP DEFAULT NOW(),
    PRIMARY KEY (user_id, org_id)
);

CREATE INDEX idx_memberships_user ON org_memberships(user_id);
CREATE INDEX idx_memberships_org ON org_memberships(org_id);
```

#### sessions

```sql
CREATE TABLE sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id INT REFERENCES users(id) ON DELETE CASCADE,
    org_id INT REFERENCES organizations(id) ON DELETE CASCADE,
    refresh_token_hash VARCHAR(255) UNIQUE,
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMP DEFAULT NOW(),
    expires_at TIMESTAMP NOT NULL,
    last_activity TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_sessions_user ON sessions(user_id);
CREATE INDEX idx_sessions_expires ON sessions(expires_at);
```

---

### Configuration

#### pipelines

```sql
CREATE TABLE pipelines (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    org_id INT REFERENCES organizations(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    connector_type VARCHAR(50) NOT NULL, -- 'DV360', 'TTD', 'META', 'CRM'
    status VARCHAR(50) DEFAULT 'active', -- 'active', 'paused', 'failed'
    schedule JSONB NOT NULL,
    config JSONB NOT NULL,
    created_by INT REFERENCES users(id),
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_pipelines_org ON pipelines(org_id);
CREATE INDEX idx_pipelines_status ON pipelines(status);
```

#### dsp_accounts

```sql
CREATE TABLE dsp_accounts (
    id SERIAL PRIMARY KEY,
    org_id INT REFERENCES organizations(id) ON DELETE CASCADE,
    dsp_type VARCHAR(50) NOT NULL, -- 'DV360', 'TTD', 'META', 'GOOGLE_ADS'
    external_id VARCHAR(255) NOT NULL,
    name VARCHAR(255),
    status VARCHAR(50) DEFAULT 'active',
    credentials_encrypted BYTEA,
    token_expires_at TIMESTAMP,
    last_sync_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(org_id, dsp_type, external_id)
);

CREATE INDEX idx_dsp_accounts_org ON dsp_accounts(org_id);
```

#### rules

```sql
CREATE TABLE rules (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    org_id INT REFERENCES organizations(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    module VARCHAR(50) NOT NULL, -- 'alerts', 'qa', 'taxonomy'
    enabled BOOLEAN DEFAULT TRUE,
    conditions JSONB NOT NULL,
    actions JSONB NOT NULL,
    created_by INT REFERENCES users(id),
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_rules_org_module ON rules(org_id, module);
CREATE INDEX idx_rules_enabled ON rules(enabled) WHERE enabled = TRUE;
```

---

### Permissions

#### entity_permissions

```sql
CREATE TABLE entity_permissions (
    id SERIAL PRIMARY KEY,
    user_id INT REFERENCES users(id) ON DELETE CASCADE,
    org_id INT REFERENCES organizations(id) ON DELETE CASCADE,
    entity_type VARCHAR(100) NOT NULL, -- 'dsp_account', 'campaign', 'pipeline', 'rule'
    entity_id VARCHAR(255) NOT NULL,
    permission VARCHAR(100) NOT NULL, -- 'view', 'edit', 'execute', 'delete'
    granted_by INT REFERENCES users(id),
    granted_at TIMESTAMP DEFAULT NOW(),
    expires_at TIMESTAMP,
    UNIQUE(user_id, org_id, entity_type, entity_id, permission)
);

CREATE INDEX idx_entity_perms_user ON entity_permissions(user_id, org_id);
CREATE INDEX idx_entity_perms_entity ON entity_permissions(entity_type, entity_id);
```

---

### Audit

#### audit_logs

```sql
CREATE TABLE audit_logs (
    id BIGSERIAL PRIMARY KEY,
    org_id INT REFERENCES organizations(id),
    user_id INT REFERENCES users(id),
    action VARCHAR(100) NOT NULL,
    resource_type VARCHAR(100),
    resource_id VARCHAR(255),
    details JSONB,
    ip_address INET,
    timestamp TIMESTAMP DEFAULT NOW()
) PARTITION BY RANGE (timestamp);

-- Create monthly partitions
CREATE TABLE audit_logs_2024_12 PARTITION OF audit_logs
    FOR VALUES FROM ('2024-12-01') TO ('2025-01-01');

CREATE INDEX idx_audit_org_time ON audit_logs(org_id, timestamp);
CREATE INDEX idx_audit_user ON audit_logs(user_id);
```

---

## ClickHouse Schemas

### campaign_metrics_daily

```sql
CREATE TABLE campaign_metrics_daily (
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
CREATE TABLE pacing_snapshots (
    org_id UInt32,
    snapshot_time DateTime,
    entity_type LowCardinality(String), -- 'campaign', 'io', 'line_item'
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
ORDER BY (org_id, snapshot_time, entity_type, entity_id)
TTL snapshot_time + INTERVAL 1 YEAR;
```

### alert_events

```sql
CREATE TABLE alert_events (
    org_id UInt32,
    alert_time DateTime,
    rule_id UUID,
    rule_name String,
    severity LowCardinality(String), -- 'critical', 'warning', 'info'
    entity_type LowCardinality(String),
    entity_id String,
    entity_name String,
    condition_details String,
    notified_users Array(UInt32)
) ENGINE = MergeTree()
PARTITION BY (org_id, toYYYYMM(alert_time))
ORDER BY (org_id, alert_time, rule_id)
TTL alert_time + INTERVAL 2 YEAR;
```

### rule_evaluations

```sql
CREATE TABLE rule_evaluations (
    org_id UInt32,
    eval_time DateTime,
    rule_id UUID,
    entity_id String,
    matched UInt8, -- 0 or 1
    condition_results String, -- JSON
    execution_time_ms UInt32
) ENGINE = MergeTree()
PARTITION BY (org_id, toYYYYMM(eval_time))
ORDER BY (org_id, eval_time, rule_id)
TTL eval_time + INTERVAL 90 DAY;
```

---

### Materialized Views

#### mv_daily_campaign_summary

```sql
CREATE MATERIALIZED VIEW mv_daily_campaign_summary
ENGINE = SummingMergeTree()
PARTITION BY (org_id, toYYYYMM(date))
ORDER BY (org_id, date, dsp_type)
POPULATE
AS SELECT
    org_id,
    date,
    dsp_type,
    count(DISTINCT campaign_id) as campaign_count,
    sum(impressions) as total_impressions,
    sum(clicks) as total_clicks,
    sum(spend) as total_spend
FROM campaign_metrics_daily
GROUP BY org_id, date, dsp_type;
```

---

## Entity Relationships

```text
┌─────────────────────────────────────────────────────────────────────────────┐
│                         ENTITY RELATIONSHIP DIAGRAM                         │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│   users                                                                     │
│     │                                                                       │
│     │ 1:N                                                                   │
│     ▼                                                                       │
│   org_memberships ◄───────────────► organizations                           │
│     │                                    │                                  │
│     │                                    │ 1:N                              │
│     │                    ┌───────────────┼───────────────┐                  │
│     │                    │               │               │                  │
│     │                    ▼               ▼               ▼                  │
│     │              dsp_accounts      pipelines        rules                 │
│     │                    │               │               │                  │
│     │                    │               │               │                  │
│     ▼                    ▼               ▼               ▼                  │
│   entity_permissions ◄───────────────────────────────────                   │
│                                                                             │
│   audit_logs (references all entities)                                      │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Navigation

- **Up:** [Data Architecture](README.md)
- **Next:** [API Specifications](../apis/README.md)
