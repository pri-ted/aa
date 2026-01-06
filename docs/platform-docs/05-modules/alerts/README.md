# Alerts Module

> Rule-based monitoring and multi-channel notifications.

---

## Module Overview

| Property | Value |
|----------|-------|
| **Module ID** | alerts |
| **Phase** | 1 (Read-Only) |
| **Required Dependencies** | DSP Connection |
| **Optional Dependencies** | Booking Database, CRM |

---

## Purpose

The Alerts module enables organizations to define custom monitoring rules that trigger notifications when campaign metrics meet specified conditions. It provides early warning for pacing issues, budget concerns, and performance anomalies.

---

## Alert Types

### Threshold Alerts
Trigger when a metric crosses a defined threshold.

| Alert | Condition | Severity |
|-------|-----------|----------|
| Over-Pacing | `pacing_rate > 120%` | Warning |
| Critical Over-Pacing | `pacing_rate > 150%` | Critical |
| Under-Pacing | `pacing_rate < 80%` | Warning |
| Critical Under-Pacing | `pacing_rate < 50%` | Critical |
| Low Margin | `margin_percent < 10%` | Warning |
| Budget Exhaustion | `spend > budget * 0.9` | Critical |

### Anomaly Alerts
Detect unusual patterns compared to historical data.

| Alert | Detection Method |
|-------|-----------------|
| Spend Spike | `daily_spend > avg_7d * 2` |
| CTR Drop | `ctr < avg_7d * 0.5` |
| Conversion Anomaly | `conversions = 0 AND impressions > 10000` |

### Deadline Alerts
Time-based warnings for campaign end dates.

| Alert | Condition |
|-------|-----------|
| Campaign Ending Soon | `days_remaining <= 3` |
| Flight End Warning | `days_remaining <= 7 AND pacing_rate < 80%` |

---

## Alert Configuration

### Basic Alert Rule
```yaml
rule:
  name: "High Pacing Alert"
  type: "alert"
  enabled: true
  
  conditions:
    operator: "AND"
    conditions:
      - field: "pacing_rate"
        operator: ">"
        value: 120
      - field: "days_remaining"
        operator: ">"
        value: 3
  
  actions:
    - type: "alert"
      severity: "warning"
      channels: ["email", "slack"]
      recipients:
        - role: "campaign_owner"
        - email: "alerts@company.com"
  
  schedule: "0 */4 * * *"  # Every 4 hours
  
  settings:
    cooldown_minutes: 60      # Don't re-alert within 1 hour
    escalation_after: 3       # Escalate after 3 occurrences
    auto_resolve: true        # Resolve when condition clears
```

### Composite Alert Rule
```yaml
rule:
  name: "Campaign Health Check"
  type: "alert"
  
  conditions:
    operator: "OR"
    conditions:
      - operator: "AND"
        conditions:
          - field: "pacing_rate"
            operator: ">"
            value: 150
          - field: "days_remaining"
            operator: "<"
            value: 7
      - operator: "AND"
        conditions:
          - field: "margin_percent"
            operator: "<"
            value: 5
          - field: "spend"
            operator: ">"
            value: 10000
  
  actions:
    - type: "alert"
      severity: "critical"
      channels: ["email", "slack", "pagerduty"]
```

---

## Notification Channels

| Channel | Configuration | Use Case |
|---------|--------------|----------|
| Email | SMTP / SendGrid | Default notifications |
| Slack | Webhook URL | Team collaboration |
| Webhook | Custom URL | Integration with external systems |
| PagerDuty | API Key | On-call escalation |

### Channel Configuration
```yaml
channels:
  slack:
    webhook_url: "https://hooks.slack.com/..."
    default_channel: "#campaign-alerts"
    mention_on_critical: "@here"
  
  email:
    from: "alerts@platform.com"
    reply_to: "support@company.com"
  
  pagerduty:
    routing_key: "${PAGERDUTY_KEY}"
    severity_mapping:
      critical: "critical"
      warning: "warning"
      info: "info"
```

---

## Alert Lifecycle

```
┌─────────┐     ┌─────────┐     ┌─────────┐     ┌──────────┐
│ PENDING │ ──▶ │ ACTIVE  │ ──▶ │NOTIFIED │ ──▶ │ RESOLVED │
└─────────┘     └─────────┘     └─────────┘     └──────────┘
     │               │               │                │
     │               ▼               ▼                │
     │          ┌─────────┐    ┌──────────┐          │
     └────────▶ │ SNOOZED │    │ESCALATED │──────────┘
                └─────────┘    └──────────┘
```

| State | Description |
|-------|-------------|
| PENDING | Condition detected, within cooldown |
| ACTIVE | Alert triggered, awaiting notification |
| NOTIFIED | Notification sent, awaiting resolution |
| SNOOZED | Temporarily suppressed by user |
| ESCALATED | Escalated to higher severity/team |
| RESOLVED | Condition cleared or manually resolved |

---

## Alert Actions

### Available Actions (Phase 1)
| Action | Description |
|--------|-------------|
| `send_notification` | Send alert to configured channels |
| `create_ticket` | Create ticket in external system |
| `log_event` | Record to audit log |
| `webhook` | Call external webhook |

### Future Actions (Phase 2+)
| Action | Description |
|--------|-------------|
| `pause_campaign` | Pause campaign in DSP |
| `adjust_budget` | Modify campaign budget |
| `change_bid` | Update bidding strategy |

---

## Severity Levels

| Severity | Response Time | Escalation | Channels |
|----------|--------------|------------|----------|
| Critical | Immediate | After 15 min | All + PagerDuty |
| Warning | 1 hour | After 4 hours | Email, Slack |
| Info | 24 hours | None | Email digest |

---

## Metrics Available

| Metric | Description | Source |
|--------|-------------|--------|
| `pacing_rate` | Delivery vs. target (%) | Gold Layer |
| `margin_percent` | Revenue - Cost (%) | Gold Layer |
| `spend` | Total media spend | DSP |
| `impressions` | Total impressions | DSP |
| `clicks` | Total clicks | DSP |
| `ctr` | Click-through rate | Calculated |
| `cvr` | Conversion rate | Calculated |
| `days_remaining` | Days until flight end | Calculated |
| `days_elapsed` | Days since flight start | Calculated |

---

## Best Practices

1. **Start Conservative** - Begin with wider thresholds, tighten over time
2. **Use Cooldowns** - Prevent alert fatigue with 1+ hour cooldowns
3. **Layer Severities** - Warning at 120%, Critical at 150%
4. **Test First** - Always use test mode before enabling
5. **Review Weekly** - Audit alert effectiveness regularly

---

## Navigation

- **Up:** [Module System](../README.md)
- **Previous:** [Pacing Module](../pacing/README.md)
- **Next:** [QA Module](../qa/README.md)
