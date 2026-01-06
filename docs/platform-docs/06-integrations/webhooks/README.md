# Webhook Integration

> Send real-time event notifications to external systems via HTTP webhooks.

---

## Overview

| Property | Value |
| ---------- | ------- |
| **Direction** | Outbound |
| **Protocol** | HTTPS |
| **Authentication** | HMAC-SHA256 signature |
| **Retry Policy** | Exponential backoff (5 attempts) |
| **Timeout** | 30 seconds |

---

## Webhook Events

### Available Events

| Event | Description | Payload |
| ------- | ------------- | --------- |
| `alert.triggered` | Rule triggered an alert | Alert details |
| `pipeline.started` | Pipeline execution started | Pipeline info |
| `pipeline.completed` | Pipeline execution completed | Execution summary |
| `pipeline.failed` | Pipeline execution failed | Error details |
| `campaign.status_changed` | Campaign status changed | Old/new status |
| `data.refreshed` | New data available | Data summary |
| `deal.matched` | Deal matched to campaign | Match details |
| `deal.unmatched` | Deal could not be matched | Deal info |

### Event Categories

```yaml
categories:
  alerts:
    - alert.triggered
    - alert.acknowledged
    - alert.resolved
    
  pipelines:
    - pipeline.started
    - pipeline.completed
    - pipeline.failed
    
  data:
    - data.refreshed
    - data.quality_issue
    
  campaigns:
    - campaign.status_changed
    - campaign.budget_alert
    
  deals:
    - deal.matched
    - deal.unmatched
    - deal.synced
```

---

## Webhook Delivery

### Request Format

```http
POST {webhook_url}
Content-Type: application/json
X-Platform-Event: alert.triggered
X-Platform-Signature: sha256=abc123...
X-Platform-Timestamp: 1703580000
X-Platform-Delivery-Id: del_abc123
User-Agent: Platform-Webhook/1.0
```

### Request Body

```json
{
  "id": "evt_abc123",
  "type": "alert.triggered",
  "created_at": "2024-12-26T10:00:00Z",
  "organization": {
    "id": 456,
    "name": "Acme Corp"
  },
  "data": {
    "alert_id": "alert_xyz789",
    "rule_id": "rule_123",
    "rule_name": "High Pacing Alert",
    "severity": "warning",
    "entity": {
      "type": "campaign",
      "id": "camp_456",
      "name": "Holiday Campaign"
    },
    "message": "Campaign 'Holiday Campaign' is pacing at 125%",
    "triggered_at": "2024-12-26T10:00:00Z",
    "conditions": [
      {
        "field": "pacing_rate",
        "operator": ">",
        "expected": "110",
        "actual": "125"
      }
    ]
  }
}
```

---

## Signature Verification

### Signature Algorithm

```code
HMAC-SHA256(timestamp.body, secret)
```

### Verification Steps

1. Extract `X-Platform-Timestamp` header
2. Extract `X-Platform-Signature` header (format: `sha256=...`)
3. Concatenate: `{timestamp}.{raw_body}`
4. Compute HMAC-SHA256 with webhook secret
5. Compare with provided signature (constant-time)
6. Reject if timestamp > 5 minutes old

### Example (Python)

```python
import hmac
import hashlib
import time

def verify_webhook(payload: bytes, timestamp: str, signature: str, secret: str) -> bool:
    # Check timestamp freshness (5 minute window)
    if abs(time.time() - int(timestamp)) > 300:
        return False
    
    # Compute expected signature
    message = f"{timestamp}.{payload.decode()}"
    expected = hmac.new(
        secret.encode(),
        message.encode(),
        hashlib.sha256
    ).hexdigest()
    
    # Extract provided signature
    provided = signature.replace("sha256=", "")
    
    # Constant-time comparison
    return hmac.compare_digest(expected, provided)
```

### Example (Node.js)

```javascript
const crypto = require('crypto');

function verifyWebhook(payload, timestamp, signature, secret) {
  // Check timestamp freshness
  const now = Math.floor(Date.now() / 1000);
  if (Math.abs(now - parseInt(timestamp)) > 300) {
    return false;
  }
  
  // Compute expected signature
  const message = `${timestamp}.${payload}`;
  const expected = crypto
    .createHmac('sha256', secret)
    .update(message)
    .digest('hex');
  
  // Extract provided signature
  const provided = signature.replace('sha256=', '');
  
  // Constant-time comparison
  return crypto.timingSafeEqual(
    Buffer.from(expected),
    Buffer.from(provided)
  );
}
```

---

## Retry Policy

### Retry Schedule

| Attempt | Delay | Total Time |
| --------- | ------- | ------------ |
| 1 | Immediate | 0s |
| 2 | 1 minute | 1m |
| 3 | 5 minutes | 6m |
| 4 | 30 minutes | 36m |
| 5 | 2 hours | 2h 36m |

### Success Codes

Delivery is considered successful if:

- HTTP status code: 200, 201, 202, or 204
- Response received within 30 seconds

### Failure Handling

After 5 failed attempts:

1. Event marked as failed
2. Webhook flagged for review
3. Admin notification sent (if configured)

---

## Event Payloads

### alert.triggered

```json
{
  "type": "alert.triggered",
  "data": {
    "alert_id": "alert_xyz789",
    "rule_id": "rule_123",
    "rule_name": "High Pacing Alert",
    "module": "pacing",
    "severity": "warning",
    "entity": {
      "type": "campaign",
      "id": "camp_456",
      "name": "Holiday Campaign",
      "url": "https://app.example.com/campaigns/camp_456"
    },
    "parent_entities": [
      {
        "type": "advertiser",
        "id": "adv_123",
        "name": "Acme Corp"
      }
    ],
    "message": "Campaign 'Holiday Campaign' is pacing at 125%",
    "conditions": [
      {
        "field": "pacing_rate",
        "operator": ">",
        "expected": "110",
        "actual": "125",
        "matched": true
      }
    ],
    "data_snapshot": {
      "pacing_rate": 125.5,
      "spend": 45000,
      "budget": 50000,
      "days_remaining": 5
    },
    "triggered_at": "2024-12-26T10:00:00Z"
  }
}
```

### pipeline.completed

```json
{
  "type": "pipeline.completed",
  "data": {
    "execution_id": "exec_abc123",
    "pipeline_id": "pipe_xyz",
    "pipeline_name": "DV360 Daily Reports",
    "status": "completed",
    "started_at": "2024-12-26T06:00:00Z",
    "completed_at": "2024-12-26T06:15:32Z",
    "duration_ms": 932000,
    "metrics": {
      "records_processed": 45230,
      "records_failed": 12,
      "quality_score": 98.5
    },
    "layers": [
      {"layer": "bronze", "status": "completed", "records": 45230},
      {"layer": "silver", "status": "completed", "records": 45218},
      {"layer": "gold", "status": "completed", "records": 45218}
    ]
  }
}
```

### pipeline.failed

```json
{
  "type": "pipeline.failed",
  "data": {
    "execution_id": "exec_def456",
    "pipeline_id": "pipe_xyz",
    "pipeline_name": "DV360 Daily Reports",
    "status": "failed",
    "started_at": "2024-12-26T06:00:00Z",
    "failed_at": "2024-12-26T06:05:12Z",
    "error": {
      "code": "DSP_AUTH_ERROR",
      "message": "OAuth token expired",
      "layer": "connector",
      "retryable": true
    }
  }
}
```

### campaign.status_changed

```json
{
  "type": "campaign.status_changed",
  "data": {
    "campaign_id": "camp_456",
    "campaign_name": "Holiday Campaign",
    "dsp": "DV360",
    "previous_status": "active",
    "new_status": "paused",
    "changed_at": "2024-12-26T10:00:00Z",
    "change_source": "dsp_sync",
    "advertiser": {
      "id": "adv_123",
      "name": "Acme Corp"
    }
  }
}
```

---

## API Endpoints

### POST /api/v1/webhooks

Create a new webhook.

**Request:**

```json
{
  "name": "Slack Alerts",
  "url": "https://hooks.slack.com/services/xxx/yyy/zzz",
  "events": ["alert.triggered", "pipeline.failed"],
  "enabled": true
}
```

**Response:**

```json
{
  "id": "wh_abc123",
  "name": "Slack Alerts",
  "url": "https://hooks.slack.com/services/xxx/yyy/zzz",
  "secret": "whsec_xxxxxxxxxxxxxxxxxxxxxxxxxxx",
  "events": ["alert.triggered", "pipeline.failed"],
  "enabled": true,
  "created_at": "2024-12-26T10:00:00Z"
}
```

> ⚠️ The `secret` is only returned once at creation. Store it securely.

### GET /api/v1/webhooks

List all webhooks for the organization.

### GET /api/v1/webhooks/{id}

Get webhook details.

### PATCH /api/v1/webhooks/{id}

Update webhook configuration.

### DELETE /api/v1/webhooks/{id}

Delete a webhook.

### POST /api/v1/webhooks/{id}/test

Send a test event.

```json
{
  "event_type": "alert.triggered"
}
```

### GET /api/v1/webhooks/{id}/deliveries

List recent deliveries.

```json
{
  "deliveries": [
    {
      "id": "del_abc123",
      "event_type": "alert.triggered",
      "status": "delivered",
      "response_status": 200,
      "response_time_ms": 245,
      "created_at": "2024-12-26T10:00:00Z",
      "delivered_at": "2024-12-26T10:00:00.245Z"
    },
    {
      "id": "del_def456",
      "event_type": "pipeline.failed",
      "status": "failed",
      "response_status": 500,
      "attempts": 5,
      "last_error": "Internal Server Error",
      "created_at": "2024-12-26T09:00:00Z"
    }
  ]
}
```

### POST /api/v1/webhooks/{id}/deliveries/{delivery_id}/retry

Manually retry a failed delivery.

---

## Best Practices

### For Webhook Receivers

1. **Respond quickly** - Return 2xx within 5 seconds
2. **Process asynchronously** - Queue work, don't block
3. **Handle duplicates** - Use `delivery_id` for idempotency
4. **Verify signatures** - Always validate HMAC
5. **Log everything** - Keep audit trail of received events

### For Webhook Consumers

```python
# Example: Async processing with queue

from flask import Flask, request
import redis
import json

app = Flask(__name__)
redis_client = redis.Redis()

@app.route('/webhook', methods=['POST'])
def webhook():
    # 1. Verify signature (see above)
    if not verify_webhook(...):
        return '', 401
    
    # 2. Check for duplicate
    delivery_id = request.headers.get('X-Platform-Delivery-Id')
    if redis_client.get(f"webhook:{delivery_id}"):
        return '', 200  # Already processed
    
    # 3. Queue for processing
    event = request.json
    redis_client.lpush('webhook_queue', json.dumps(event))
    
    # 4. Mark as received
    redis_client.setex(f"webhook:{delivery_id}", 86400, "1")
    
    # 5. Return immediately
    return '', 200
```

---

## Monitoring

### Metrics Exposed

| Metric | Description |
| -------- | ------------- |
| `webhook_deliveries_total` | Total deliveries by status |
| `webhook_delivery_duration_ms` | Delivery latency histogram |
| `webhook_retry_count` | Retries by webhook |
| `webhook_queue_depth` | Pending deliveries |

### Alerts

- Webhook delivery failure rate > 10%
- Webhook response time p95 > 5s
- Webhook disabled due to failures

---

## Navigation

- **Up:** [Integrations](README.md)
- **Previous:** [Google Sheets](google-sheets.md)
