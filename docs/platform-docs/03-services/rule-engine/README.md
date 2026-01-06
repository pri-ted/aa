# Rule Engine

> Condition evaluation and action execution.

---

## Service Overview

| Property | Value |
| ---------- | ------- |
| **Language** | Rust |
| **Framework** | Actix-web |
| **Database** | PostgreSQL |
| **Port** | 8009 |
| **gRPC Port** | 9009 |
| **Replicas** | 3 |
| **Owner** | Platform Team |

---

## Responsibilities

1. **Condition Evaluation** - Evaluate rule conditions
2. **Action Execution** - Trigger alerts, webhooks
3. **Test Mode** - Dry-run against historical data
4. **Scheduling** - Cron-based rule execution
5. **Tracking** - Record all matches and actions

---

## Rule Structure

```json
{
  "id": "rule_123",
  "name": "High Pacing Alert",
  "type": "alert",
  "enabled": true,
  "conditions": {
    "operator": "AND",
    "conditions": [
      {"field": "pacing_rate", "operator": ">", "value": 120},
      {"field": "days_remaining", "operator": ">", "value": 3}
    ]
  },
  "actions": [
    {
      "type": "alert",
      "severity": "warning",
      "channels": ["email", "slack"]
    }
  ],
  "schedule": "0 */6 * * *"
}
```

---

## Condition Operators

| Operator | Description | Example |
| ---------- | ------------- | --------- |
| `=` / `==` | Equals | `status == 'active'` |
| `!=` | Not equals | `dsp != 'META'` |
| `>` | Greater than | `pacing > 100` |
| `<` | Less than | `margin < 10` |
| `>=` | Greater or equal | `spend >= 1000` |
| `<=` | Less or equal | `days <= 7` |
| `contains` | String contains | `name contains 'Holiday'` |
| `starts_with` | String prefix | `campaign starts_with 'Q4'` |
| `in` | Value in list | `status in ['active', 'paused']` |
| `between` | Value in range | `pacing between 90 and 110` |
| `is_null` | Null check | `booking is_null` |

---

## Action Types

### Phase 1 (Alert Only)

| Action | Description |
| -------- | ------------- |
| `alert` | Send notification |
| `log` | Record to audit log |
| `webhook` | Call external URL |

### Phase 2 (Write-back)

| Action | Description |
| -------- | ------------- |
| `pause_campaign` | Pause in DSP |
| `adjust_budget` | Modify budget |
| `update_bid` | Change bid strategy |

---

## API Endpoints

### POST /api/v1/rules/execute

Execute rule (live or test mode).

**Request:**

```json
{
  "rule_id": "rule_123",
  "mode": "test",
  "params": {
    "date_range": {
      "start": "2024-12-20",
      "end": "2024-12-23"
    }
  }
}
```

**Response (200):**

```json
{
  "execution_id": "rexec_456",
  "status": "completed",
  "matches": 23,
  "actions_triggered": [
    {
      "type": "alert",
      "count": 23,
      "details": "Sent 23 high-priority alerts"
    }
  ],
  "affected_entities": [
    {
      "entity_type": "campaign",
      "entity_id": "camp_789",
      "entity_name": "Holiday Campaign",
      "matched_conditions": {
        "pacing_rate": 125.5,
        "threshold": 110
      }
    }
  ]
}
```

---

### GET /api/v1/rules/{rule_id}/history

Get rule execution history.

**Response (200):**

```json
{
  "executions": [
    {
      "id": "rexec_456",
      "executed_at": "2024-12-23T06:00:00Z",
      "status": "completed",
      "matches": 23,
      "duration_ms": 1250
    }
  ],
  "statistics": {
    "total_executions": 145,
    "avg_matches": 18.5,
    "last_7_days": {
      "executions": 28,
      "total_matches": 521
    }
  }
}
```

---

## Database Schemas

### rule_executions

```sql
CREATE TABLE rule_executions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    rule_id UUID REFERENCES rules(id),
    org_id INT REFERENCES organizations(id),
    mode VARCHAR(50),
    status VARCHAR(50),
    matches INT DEFAULT 0,
    actions_triggered JSONB,
    result JSONB,
    error TEXT,
    duration_ms INT,
    executed_at TIMESTAMP DEFAULT NOW()
);
```

### rule_matches

```sql
CREATE TABLE rule_matches (
    id BIGSERIAL PRIMARY KEY,
    execution_id UUID REFERENCES rule_executions(id),
    rule_id UUID REFERENCES rules(id),
    org_id INT REFERENCES organizations(id),
    entity_type VARCHAR(100),
    entity_id VARCHAR(255),
    matched_values JSONB,
    actions_taken JSONB,
    created_at TIMESTAMP DEFAULT NOW()
);
```

---

## Execution Flow

```text
┌─────────────────────────────────────────────────────────────────────────────┐
│                        RULE EXECUTION FLOW                                  │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│   1. Load Rule               2. Fetch Data             3. Evaluate          │
│   ┌─────────────┐           ┌─────────────┐           ┌─────────────┐       │
│   │  rules DB   │ ────────▶ │ ClickHouse  │ ────────▶ │  Condition  │       │
│   │             │           │   (Gold)    │           │   Engine    │       │
│   └─────────────┘           └─────────────┘           └─────────────┘       │
│                                                              │              │
│                                                              ▼              │
│   4. Execute Actions        5. Record Results                               │
│   ┌─────────────┐           ┌─────────────┐                                 │
│   │ Notification │ ◀──────── │  Matches    │                                 │
│   │   Service   │           │   Found     │                                 │
│   └─────────────┘           └─────────────┘                                 │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Configuration

```yaml
rule_engine:
  execution:
    max_concurrent: 10
    timeout_seconds: 300
  scheduling:
    default_cron: "0 */6 * * *"
  limits:
    max_rules_per_org: 500
    max_conditions_per_rule: 20
    max_actions_per_rule: 10
```

---

## Events Published

| Topic | Event |
| ------- | ------- |
| `rules.events` | `rule.executed`, `rule.matched` |
| `rules.alerts` | Alert notifications |

---

## Navigation

- **Up:** [Service Catalog](../README.md)
- **Previous:** [Calculation Engine](../calculation/README.md)
- **Next:** [Analytics Service](../analytics/README.md)
