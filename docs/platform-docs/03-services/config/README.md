# Config Service

> Metadata store, schema registry, and configuration management.

---

## Service Overview

| Property | Value |
| ---------- | ------- |
| **Language** | Rust |
| **Framework** | Actix-web 4.x |
| **Database** | PostgreSQL 16 |
| **Port** | 8002 |
| **gRPC Port** | 9002 |
| **Replicas** | 3 (HA) |
| **Owner** | Platform Team |

---

## Responsibilities

1. **Pipeline Configuration** - CRUD for data pipelines
2. **Schema Registry** - Entity schema management
3. **Template Management** - Pipeline templates with smart defaults
4. **Validation Engine** - Configuration validation before save
5. **Smart Defaults** - Learn from similar organizations
6. **Deduplication Detection** - Identify similar pipelines

---

## Architecture

```text
┌─────────────────────────────────────────────────────────────────────────────┐
│                         CONFIG SERVICE                                      │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│   ┌───────────────────────────────────────────────────────────────────┐     │
│   │                      API Layer (Actix)                            │     │
│   │   /pipelines  /templates  /rules  /schemas  /analyze              │     │
│   └───────────────────────────────────────────────────────────────────┘     │
│                                   │                                         │
│                                   ▼                                         │
│   ┌───────────────────────────────────────────────────────────────────┐     │
│   │                      Business Logic                               │     │
│   │  PipelineManager  TemplateEngine  ValidationEngine  SmartDefaults │     │
│   └───────────────────────────────────────────────────────────────────┘     │
│                                   │                                         │
│                                   ▼                                         │
│   ┌───────────────────────────────────────────────────────────────────┐     │
│   │                      PostgreSQL                                   │     │
│   │   pipelines  templates  rules  rule_versions  schemas             │     │
│   └───────────────────────────────────────────────────────────────────┘     │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## API Endpoints

### GET /api/v1/config/pipelines

List pipelines for organization.

**Query Params:**

- `page`: int (default: 1)
- `limit`: int (default: 20)
- `status`: enum (active, paused, failed)

**Response (200):**

```json
{
  "pipelines": [
    {
      "id": "pipe_123",
      "name": "DV360 Daily Reports",
      "connector_type": "DV360",
      "status": "active",
      "schedule": {
        "type": "cron",
        "expression": "0 6 * * *",
        "timezone": "America/New_York"
      },
      "config": {
        "account_id": "dsp_acc_456",
        "metrics": ["impressions", "clicks", "conversions"]
      },
      "created_at": "2024-12-01T10:00:00Z",
      "updated_at": "2024-12-20T15:30:00Z"
    }
  ],
  "pagination": {
    "total": 45,
    "page": 1,
    "limit": 20
  }
}
```

---

### POST /api/v1/config/pipelines

Create new pipeline.

**Request:**

```json
{
  "name": "DV360 Hourly Refresh",
  "connector_type": "DV360",
  "template_id": "tmpl_dv360_standard",
  "schedule": {
    "type": "cron",
    "expression": "0 * * * *"
  },
  "config": {
    "account_id": "dsp_acc_456",
    "metrics": ["impressions", "clicks"],
    "date_range": "last_7_days"
  }
}
```

**Response (201):**

```json
{
  "id": "pipe_789",
  "message": "Pipeline created successfully",
  "optimization": {
    "type": "similar_pipeline_detected",
    "similarity": 0.92,
    "existing_pipeline_id": "pipe_123",
    "suggestion": {
      "action": "merge",
      "savings_per_month": 45.50
    }
  }
}
```

---

### POST /api/v1/config/pipelines/analyze

Analyze pipeline config before creation.

**Request:**

```json
{
  "connector_type": "DV360",
  "schedule": "0 6 * * *",
  "config": {
    "metrics": ["impressions", "clicks"]
  }
}
```

**Response (200):**

```json
{
  "optimization": {
    "type": "similar_pipeline_detected",
    "existing_pipelines": [
      {
        "id": "pipe_123",
        "name": "DV360 Daily",
        "similarity": 0.92,
        "differences": ["schedule: 6AM vs 8AM", "metrics: +CTR"]
      }
    ],
    "recommendation": "merge",
    "estimated_savings": 45.50
  },
  "validation": {
    "is_valid": true,
    "warnings": [
      {
        "field": "schedule",
        "message": "Hourly schedules may hit rate limits",
        "suggestion": "Consider daily schedule"
      }
    ]
  },
  "smart_defaults": {
    "confidence": 0.89,
    "learned_from": "47 similar organizations",
    "suggestions": {
      "schedule": "Daily at 6 AM (76% use this)",
      "metrics": ["impressions", "clicks", "conversions", "ctr"]
    }
  }
}
```

---

### GET /api/v1/config/templates

List available templates.

**Response (200):**

```json
{
  "templates": [
    {
      "id": "tmpl_dv360_standard",
      "name": "DV360 Daily Performance",
      "connector_type": "DV360",
      "description": "Standard daily campaign reporting",
      "default_config": {
        "schedule": "0 6 * * *",
        "metrics": ["impressions", "clicks", "conversions", "spend"]
      },
      "required_inputs": ["account_id", "schedule_time"],
      "optional_inputs": ["additional_metrics", "custom_filters"],
      "usage_count": 47,
      "satisfaction_rating": 4.7
    }
  ]
}
```

---

### GET /api/v1/config/rules

List rules for organization.

**Response (200):**

```json
{
  "rules": [
    {
      "id": "rule_123",
      "name": "Overpacing Alert",
      "type": "qa_check",
      "enabled": true,
      "conditions": {
        "logic": "AND",
        "rules": [
          {"field": "pacing_rate", "operator": ">", "value": 110},
          {"field": "days_remaining", "operator": "<", "value": 5}
        ]
      },
      "actions": [
        {
          "type": "send_alert",
          "config": {"severity": "high", "channels": ["email", "slack"]}
        }
      ],
      "created_at": "2024-12-01T10:00:00Z"
    }
  ]
}
```

---

### POST /api/v1/config/rules/test

Test rule against historical data.

**Request:**

```json
{
  "rule": {
    "conditions": {
      "logic": "AND",
      "rules": [{"field": "pacing_rate", "operator": ">", "value": 110}]
    }
  },
  "date_range": {"start": "2024-12-16", "end": "2024-12-23"}
}
```

**Response (200):**

```json
{
  "test_results": {
    "total_entities_evaluated": 450,
    "matches": 23,
    "affected_campaigns": [
      {
        "campaign_id": "camp_789",
        "campaign_name": "Holiday Campaign",
        "matched_values": {"pacing_rate": 125.5}
      }
    ],
    "estimated_alerts_per_day": 3.2
  }
}
```

---

## Database Schemas

### pipelines

```sql
CREATE TABLE pipelines (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    org_id INT REFERENCES organizations(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    connector_type VARCHAR(50) NOT NULL,
    status VARCHAR(50) DEFAULT 'active',
    schedule JSONB NOT NULL,
    config JSONB NOT NULL,
    metadata JSONB DEFAULT '{}',
    created_by INT REFERENCES users(id),
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    last_run_at TIMESTAMP,
    next_run_at TIMESTAMP
);

CREATE INDEX idx_pipelines_org ON pipelines(org_id);
CREATE INDEX idx_pipelines_status ON pipelines(status);
```

### pipeline_templates

```sql
CREATE TABLE pipeline_templates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    connector_type VARCHAR(50) NOT NULL,
    description TEXT,
    default_config JSONB NOT NULL,
    required_inputs JSONB DEFAULT '[]',
    optional_inputs JSONB DEFAULT '[]',
    usage_count INT DEFAULT 0,
    is_public BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT NOW()
);
```

### rules

```sql
CREATE TABLE rules (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    org_id INT REFERENCES organizations(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    type VARCHAR(50) NOT NULL,
    enabled BOOLEAN DEFAULT TRUE,
    conditions JSONB NOT NULL,
    actions JSONB NOT NULL,
    schedule VARCHAR(255),
    version INT DEFAULT 1,
    created_by INT REFERENCES users(id),
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_rules_org ON rules(org_id);
CREATE INDEX idx_rules_type ON rules(type);
```

### rule_versions

```sql
CREATE TABLE rule_versions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    rule_id UUID REFERENCES rules(id) ON DELETE CASCADE,
    version INT NOT NULL,
    conditions JSONB NOT NULL,
    actions JSONB NOT NULL,
    created_by INT REFERENCES users(id),
    created_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(rule_id, version)
);
```

---

## Smart Defaults Algorithm

```rust
fn get_smart_defaults(org: &Organization, connector_type: &str) -> SmartDefaults {
    // Find similar organizations
    let similar_orgs = find_similar_orgs(org, 50);
    
    // Analyze their pipeline configurations
    let configs = get_pipeline_configs(&similar_orgs, connector_type);
    
    // Calculate most common values
    let schedule = mode(&configs.map(|c| c.schedule));
    let metrics = top_n(&configs.flat_map(|c| c.metrics), 5);
    
    SmartDefaults {
        confidence: calculate_confidence(configs.len()),
        learned_from: format!("{} similar organizations", similar_orgs.len()),
        suggestions: Suggestions { schedule, metrics }
    }
}
```

---

## Configuration

```yaml
config:
  similarity_threshold: 0.85
  template_cache_ttl: 3600
  validation:
    max_pipelines_per_org: 100
    max_rules_per_org: 500
  smart_defaults:
    min_sample_size: 10
    confidence_threshold: 0.7
```

---

## Events Published

| Topic | Event |
| ------- | ------- |
| `config.events` | `pipeline.created`, `pipeline.updated`, `pipeline.deleted` |
| `config.events` | `rule.created`, `rule.updated`, `rule.enabled`, `rule.disabled` |

---

## Navigation

- **Up:** [Service Catalog](../README.md)
- **Previous:** [Auth Service](../auth/README.md)
- **Next:** [Connector Service](../connector/README.md)
