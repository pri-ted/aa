# Meta (Facebook/Instagram) Integration

> Meta Ads connector for Facebook and Instagram campaigns.

---

## Integration Overview

| Property | Value |
| ---------- | ------- |
| **DSP** | Meta Ads |
| **Auth** | OAuth 2.0 |
| **API Version** | v18.0 |
| **Read Support** | ✓ Production |
| **Write Support** | ○ Phase 2 |
| **Rate Limit** | 200 req/hour |

---

## Authentication

### OAuth 2.0 Flow

```text
1. User clicks "Connect Meta"
2. Redirect to Meta OAuth consent
3. User authorizes app
4. Exchange code for tokens
5. Store encrypted long-lived token
```

### Required Permissions

```code
ads_read
ads_management (Phase 2)
business_management
read_insights
```

### Token Management

```yaml
tokens:
  short_lived:
    ttl: 1h
    refresh: on_use
  long_lived:
    ttl: 60d
    refresh: before_expiry
```

---

## Data Available

### Entity Hierarchy

```text
Business
  └── Ad Account
        └── Campaign
              └── Ad Set
                    └── Ad
                          └── Creative
```

### Campaign Fields

| Field | Description |
| ------- | ------------- |
| id | Campaign ID |
| name | Campaign name |
| status | ACTIVE, PAUSED, DELETED |
| objective | AWARENESS, CONSIDERATION, CONVERSION |
| daily_budget | Daily spend limit |
| lifetime_budget | Total budget |
| start_time | Campaign start |
| stop_time | Campaign end |

### Performance Metrics

| Metric | Description |
| -------- | ------------- |
| impressions | Total impressions |
| reach | Unique users reached |
| clicks | Total clicks |
| spend | Amount spent |
| cpm | Cost per 1000 impressions |
| cpc | Cost per click |
| ctr | Click-through rate |
| frequency | Avg impressions per user |
| conversions | Total conversions |
| roas | Return on ad spend |

---

## Rate Limits

| Type | Limit | Window |
| ------ | ------- | -------- |
| API Calls | 200 | per hour |
| Insights | 100 | per hour |
| Batch | 50 | per request |

### Rate Limit Headers

```http
x-business-use-case-usage: {
  "123456789": [{
    "call_count": 45,
    "total_cputime": 120,
    "total_time": 180,
    "estimated_time_to_regain_access": 0
  }]
}
```

---

## Read Operations

### Fetch Campaigns

```http
GET /v18.0/act_{ad_account_id}/campaigns
  ?fields=id,name,status,objective,daily_budget,lifetime_budget
  &limit=100
Authorization: Bearer {access_token}
```

### Fetch Insights

```http
GET /v18.0/{campaign_id}/insights
  ?fields=impressions,clicks,spend,cpm,ctr
  &date_preset=last_7d
  &level=campaign
Authorization: Bearer {access_token}
```

### Batch Requests

```http
POST /v18.0/
Authorization: Bearer {access_token}

{
  "batch": [
    {"method": "GET", "relative_url": "campaign_1/insights?..."},
    {"method": "GET", "relative_url": "campaign_2/insights?..."}
  ]
}
```

---

## Write Operations (Phase 2)

| Operation | Endpoint | Status |
| ----------- | ---------- | -------- |
| Create Campaign | POST /act_{id}/campaigns | Planned |
| Update Campaign | POST /{campaign_id} | Planned |
| Pause Campaign | POST /{campaign_id} | Planned |
| Update Budget | POST /{campaign_id} | Planned |

---

## Data Mapping

### Status Mapping

| Meta Status | Platform Status |
| ------------- | ----------------- |
| ACTIVE | active |
| PAUSED | paused |
| DELETED | deleted |
| ARCHIVED | archived |
| WITH_ISSUES | degraded |

### Objective Mapping

| Meta Objective | Platform Type |
| ---------------- | --------------- |
| OUTCOME_AWARENESS | awareness |
| OUTCOME_TRAFFIC | consideration |
| OUTCOME_ENGAGEMENT | consideration |
| OUTCOME_LEADS | conversion |
| OUTCOME_SALES | conversion |

---

## Error Handling

| Error Code | Meaning | Action |
| ------------ | --------- | -------- |
| 190 | Token expired | Refresh token |
| 200 | Permission error | Re-authorize |
| 613 | Too many calls | Back off 1 hour |
| 100 | Invalid parameter | Log and fix |
| 1 | Unknown error | Retry 3x |

---

## Configuration

```yaml
meta:
  base_url: "https://graph.facebook.com/v18.0"
  app_id: "${META_APP_ID}"
  app_secret: "${META_APP_SECRET}"
  rate_limit:
    calls_per_hour: 200
    insights_per_hour: 100
  retry:
    max_attempts: 3
    backoff_seconds: 60
  batch:
    max_size: 50
```

---

## Navigation

- **Up:** [Integration Layer](../README.md)
- **Previous:** [TTD Integration](../ttd/README.md)
- **Next:** [Google Ads Integration](../google-ads/README.md)
