# Google Ads Integration

> Google Ads connector for Search, Display, and YouTube campaigns.

---

## Integration Overview

| Property | Value |
| ---------- | ------- |
| **DSP** | Google Ads |
| **Auth** | OAuth 2.0 |
| **API Version** | v15 |
| **Read Support** | ✓ Production |
| **Write Support** | ○ Phase 2 |
| **Rate Limit** | 15,000 req/day |

---

## Authentication

### OAuth 2.0 Flow

```yaml
oauth:
  authorization_url: "https://accounts.google.com/o/oauth2/v2/auth"
  token_url: "https://oauth2.googleapis.com/token"
  scopes:
    - "https://www.googleapis.com/auth/adwords"
  refresh_token_lifetime: "no_expiry"
```

### Required Headers

```http
Authorization: Bearer {access_token}
developer-token: {developer_token}
login-customer-id: {manager_account_id}
```

---

## Data Available

### Entity Hierarchy

```text
Manager Account (MCC)
  └── Customer (Account)
        └── Campaign
              └── Ad Group
                    └── Ad
                    └── Keywords
                    └── Audiences
```

### Campaign Types

| Type | Description |
| ------ | ------------- |
| SEARCH | Search ads |
| DISPLAY | Display network |
| VIDEO | YouTube ads |
| SHOPPING | Shopping ads |
| PERFORMANCE_MAX | Automated cross-channel |
| APP | App install/engagement |

### Performance Metrics

| Metric | Description |
| -------- | ------------- |
| impressions | Total impressions |
| clicks | Total clicks |
| cost_micros | Cost in micros (÷1M for currency) |
| conversions | Total conversions |
| conversions_value | Total conversion value |
| ctr | Click-through rate |
| average_cpc | Average cost per click |
| average_cpm | Average cost per 1000 impressions |
| search_impression_share | Search impression share |
| video_views | Video views (YouTube) |

---

## Rate Limits

| Resource | Daily Limit | Per-Request |
| ---------- | ------------- | ------------- |
| API Requests | 15,000 | N/A |
| Mutate operations | 10,000 | 5,000 |
| Report downloads | 1,000 | N/A |

### Basic Access Limits

| Level | Daily Operations |
| ------- | ----------------- |
| Basic | 15,000 |
| Standard | 50,000 |

---

## Read Operations

### GAQL Query (Google Ads Query Language)

```sql
SELECT
  campaign.id,
  campaign.name,
  campaign.status,
  campaign.advertising_channel_type,
  metrics.impressions,
  metrics.clicks,
  metrics.cost_micros
FROM campaign
WHERE segments.date DURING LAST_7_DAYS
  AND campaign.status != 'REMOVED'
ORDER BY metrics.impressions DESC
LIMIT 100
```

### API Request

```http
POST /v15/customers/{customer_id}/googleAds:search
Authorization: Bearer {access_token}
developer-token: {developer_token}

{
  "query": "SELECT campaign.id, campaign.name... FROM campaign..."
}
```

### Streaming Reports

```http
POST /v15/customers/{customer_id}/googleAds:searchStream

{
  "query": "SELECT ... FROM campaign ..."
}
```

---

## Write Operations (Phase 2)

| Operation | Method | Status |
| ----------- | -------- | -------- |
| Create Campaign | mutate | Planned |
| Update Campaign | mutate | Planned |
| Pause Campaign | mutate | Planned |
| Update Budget | mutate | Planned |
| Add Keywords | mutate | Planned |

### Mutate Example

```json
{
  "operations": [
    {
      "update": {
        "resourceName": "customers/123/campaigns/456",
        "status": "PAUSED"
      },
      "updateMask": "status"
    }
  ]
}
```

---

## Data Mapping

### Status Mapping

| Google Ads Status | Platform Status |
| ------------------- | ----------------- |
| ENABLED | active |
| PAUSED | paused |
| REMOVED | deleted |

### Channel Mapping

| Channel Type | Platform Type |
| -------------- | --------------- |
| SEARCH | search |
| DISPLAY | display |
| VIDEO | video |
| SHOPPING | shopping |
| PERFORMANCE_MAX | pmax |

### Cost Conversion

```python
# Google Ads returns cost in micros
cost_usd = cost_micros / 1_000_000
```

---

## Error Handling

| Error | Meaning | Action |
| ------- | --------- | -------- |
| AUTHENTICATION_ERROR | Token invalid | Refresh token |
| AUTHORIZATION_ERROR | No permission | Check access |
| QUOTA_ERROR | Rate limited | Back off |
| REQUEST_ERROR | Bad request | Fix and retry |
| INTERNAL_ERROR | Server error | Retry 3x |

---

## Configuration

```yaml
google_ads:
  api_version: "v15"
  developer_token: "${GOOGLE_ADS_DEV_TOKEN}"
  rate_limit:
    daily_operations: 15000
    mutate_per_request: 5000
  retry:
    max_attempts: 3
    backoff_multiplier: 2
  report:
    page_size: 10000
    use_streaming: true
```

---

## Navigation

- **Up:** [Integration Layer](../README.md)
- **Previous:** [Meta Integration](../meta/README.md)
- **Next:** [CRM Integration](../crm/README.md)
