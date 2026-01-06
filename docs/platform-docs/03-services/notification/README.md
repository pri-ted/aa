# Notification Service

> Multi-channel alerting and notification delivery.

---

## Service Overview

| Property | Value |
| ---------- | ------- |
| **Language** | Go 1.21+ |
| **Framework** | Gin |
| **Database** | PostgreSQL + Redis |
| **Port** | 8012 |
| **gRPC Port** | 9012 |
| **Replicas** | 3 |
| **Owner** | Platform Team |

---

## Responsibilities

1. **Multi-Channel Delivery** - Email, Slack, webhook
2. **Template Management** - Notification templates
3. **Batching** - Group similar notifications
4. **Retry Logic** - Handle delivery failures
5. **Preference Management** - User notification settings

---

## Supported Channels

| Channel | Provider | Status |
| --------- | ---------- | -------- |
| Email | SendGrid | Production |
| Slack | Slack API | Production |
| Webhook | HTTP POST | Production |
| SMS | Twilio | Planned |
| Push | Firebase | Planned |

---

## API Endpoints

### POST /api/v1/notifications/send

Send notification.

**Request:**

```json
{
  "type": "alert",
  "severity": "warning",
  "channels": ["email", "slack"],
  "recipients": {
    "user_ids": [123, 456],
    "emails": ["external@example.com"]
  },
  "template": "pacing_alert",
  "data": {
    "campaign_name": "Holiday Campaign",
    "pacing_rate": 125.5,
    "threshold": 110
  }
}
```

**Response (200):**

```json
{
  "notification_id": "notif_789",
  "status": "queued",
  "delivery_status": {
    "email": {"status": "queued", "count": 3},
    "slack": {"status": "queued", "count": 1}
  }
}
```

---

### GET /api/v1/notifications/preferences

Get user notification preferences.

**Response (200):**

```json
{
  "preferences": {
    "channels": {
      "email": true,
      "slack": true,
      "webhook": false
    },
    "frequency": {
      "immediate": ["critical"],
      "hourly_digest": ["warning"],
      "daily_digest": ["info"]
    },
    "quiet_hours": {
      "enabled": true,
      "start": "22:00",
      "end": "08:00",
      "timezone": "America/New_York"
    }
  }
}
```

---

### PUT /api/v1/notifications/preferences

Update notification preferences.

**Request:**

```json
{
  "channels": {
    "email": true,
    "slack": false
  },
  "quiet_hours": {
    "enabled": true,
    "start": "21:00",
    "end": "09:00"
  }
}
```

---

## Notification Templates

### pacing_alert

```handlebars
Subject: [{{severity}}] Pacing Alert: {{campaign_name}}

Campaign "{{campaign_name}}" is pacing at {{pacing_rate}}%.

Current Status:
- Pacing Rate: {{pacing_rate}}%
- Threshold: {{threshold}}%
- Days Remaining: {{days_remaining}}

View Campaign: {{campaign_url}}
```

### budget_alert

```handlebars
Subject: Budget Alert - {{percent_used}}% Used

Your organization has used {{percent_used}}% of the monthly budget.

Current Spend: ${{current_spend}}
Budget Limit: ${{budget_limit}}
Forecast: ${{forecast}}

Review Usage: {{analytics_url}}
```

---

## Batching Logic

```go
// Batch similar notifications within 5 minutes
func shouldBatch(n1, n2 Notification) bool {
    return n1.Type == n2.Type &&
           n1.Template == n2.Template &&
           n1.Severity == n2.Severity &&
           time.Since(n1.CreatedAt) < 5*time.Minute
}

// Create digest
func createDigest(notifications []Notification) Notification {
    return Notification{
        Type: "digest",
        Template: "batch_alert",
        Data: map[string]interface{}{
            "count": len(notifications),
            "items": summarize(notifications),
        },
    }
}
```

---

## Database Schemas

### notifications

```sql
CREATE TABLE notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    org_id INT REFERENCES organizations(id),
    type VARCHAR(100) NOT NULL,
    severity VARCHAR(50),
    template VARCHAR(100),
    data JSONB,
    status VARCHAR(50) DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT NOW(),
    sent_at TIMESTAMP
);
```

### notification_deliveries

```sql
CREATE TABLE notification_deliveries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    notification_id UUID REFERENCES notifications(id),
    channel VARCHAR(50) NOT NULL,
    recipient VARCHAR(255) NOT NULL,
    status VARCHAR(50) DEFAULT 'pending',
    attempts INT DEFAULT 0,
    last_attempt_at TIMESTAMP,
    error TEXT,
    delivered_at TIMESTAMP
);
```

### notification_preferences

```sql
CREATE TABLE notification_preferences (
    user_id INT REFERENCES users(id) PRIMARY KEY,
    channels JSONB DEFAULT '{"email": true, "slack": true}',
    frequency JSONB DEFAULT '{}',
    quiet_hours JSONB DEFAULT '{}',
    updated_at TIMESTAMP DEFAULT NOW()
);
```

---

## Retry Strategy

| Attempt | Delay | Action |
| --------- | ------- | -------- |
| 1 | Immediate | First try |
| 2 | 1 minute | Retry |
| 3 | 5 minutes | Retry |
| 4 | 15 minutes | Retry |
| 5 | 1 hour | Final retry |
| 6+ | - | Mark failed, alert ops |

---

## Configuration

```yaml
notification:
  channels:
    email:
      provider: sendgrid
      api_key: ${SENDGRID_API_KEY}
      from: "alerts@platform.com"
    slack:
      webhook_url: ${SLACK_WEBHOOK}
  batching:
    window: 5m
    max_batch_size: 50
  retry:
    max_attempts: 5
    initial_delay: 1m
```

---

## Events Consumed

| Topic | Event |
| ------- | ------- |
| `rules.alerts` | Alert triggers |
| `etl.events` | Pipeline failures |
| `analytics.events` | Budget alerts |

---

## Navigation

- **Up:** [Service Catalog](../README.md)
- **Previous:** [Analytics Service](../analytics/README.md)
- **Next:** [Query Service](../query/README.md)
