# The Trade Desk (TTD) Integration

> The Trade Desk DSP connector for campaign data and management.

---

## Integration Overview

| Property | Value |
| ---------- | ------- |
| **DSP** | The Trade Desk |
| **Auth** | API Key + Secret |
| **API Version** | v3 |
| **Read Support** | ✓ Production |
| **Write Support** | ○ Phase 2 |
| **Rate Limit** | 100 req/min |

---

## Authentication

### API Key Authentication

TTD uses API key + secret authentication (not OAuth).

```yaml
credentials:
  type: "api_key"
  api_key: "${TTD_API_KEY}"
  api_secret: "${TTD_API_SECRET}"
  partner_id: "${TTD_PARTNER_ID}"
```

### Token Generation

```bash
# Generate auth token
curl -X POST "https://api.thetradedesk.com/v3/authentication" \
  -H "Content-Type: application/json" \
  -d '{
    "Login": "${TTD_API_KEY}",
    "Password": "${TTD_API_SECRET}"
  }'

# Response
{
  "Token": "eyJ...",
  "TokenExpirationUtc": "2024-12-23T12:00:00Z"
}
```

---

## Data Available

### Entity Hierarchy

```text
Partner
  └── Advertiser
        └── Campaign
              └── Ad Group
                    └── Ad
                          └── Creative
```

### Campaign Structure

| Entity | Fields |
| -------- | -------- |
| Campaign | ID, name, budget, dates, status, pacing |
| Ad Group | ID, name, bid, targeting, frequency |
| Ad | ID, name, creative, tracking |
| Creative | ID, name, format, size, content |

### Performance Metrics

| Metric | Description | Update Frequency |
| -------- | ------------- | ------------------ |
| Impressions | Total ad views | Hourly |
| Clicks | User clicks | Hourly |
| Conversions | Completed actions | Hourly |
| Spend | Media cost (USD) | Hourly |
| Video Views | Video ad views | Hourly |
| Video Completions | 100% watched | Hourly |
| Viewable Impressions | MRC viewable | Daily |

---

## Rate Limits

| Endpoint | Limit | Window |
| ---------- | ------- | -------- |
| Authentication | 10 | per minute |
| Campaign Read | 100 | per minute |
| Report Query | 20 | per minute |
| Bulk Operations | 50 | per minute |

### Rate Limit Handling

```go
// TTD returns 429 with Retry-After header
if response.StatusCode == 429 {
    retryAfter := response.Header.Get("Retry-After")
    time.Sleep(parseDuration(retryAfter))
    return retry(request)
}
```

---

## Read Operations

### Fetch Campaigns

```http
GET /v3/campaign/query/advertiser
Authorization: Bearer {token}

{
  "AdvertiserId": "abc123",
  "PageSize": 100,
  "PageStartIndex": 0
}
```

### Fetch Reports

```http
POST /v3/myreports/reportexecution/query
Authorization: Bearer {token}

{
  "AdvertiserIds": ["abc123"],
  "ReportScheduleName": "DailyPerformance",
  "ReportDateRange": "Last7Days",
  "Dimensions": ["CampaignId", "AdGroupId", "Date"],
  "Metrics": ["Impressions", "Clicks", "Spend"]
}
```

### Report Execution Flow

1. Create report schedule
2. Execute report
3. Poll for completion (5-10 min typical)
4. Download results (CSV/JSON)

---

## Write Operations (Phase 2)

| Operation | Endpoint | Status |
| ----------- | ---------- | -------- |
| Create Campaign | POST /v3/campaign | Planned |
| Update Campaign | PUT /v3/campaign/{id} | Planned |
| Pause Campaign | PUT /v3/campaign/{id} | Planned |
| Update Budget | PUT /v3/campaign/{id}/budget | Planned |
| Create Ad Group | POST /v3/adgroup | Planned |

---

## Data Mapping

### Campaign Status Mapping

| TTD Status | Platform Status |
| ------------ | ----------------- |
| Active | active |
| Paused | paused |
| InFlight | active |
| Completed | completed |
| Archived | archived |

### Metric Normalization

```yaml
mappings:
  ttd.Impressions: impressions
  ttd.Clicks: clicks
  ttd.TotalSpend: spend
  ttd.Conversions: conversions
  ttd.VideoCompletions: video_completions
  ttd.ViewableImpressions: viewable_impressions
```

---

## Error Handling

| Error Code | Meaning | Action |
| ------------ | --------- | -------- |
| 401 | Token expired | Refresh token |
| 403 | Permission denied | Check credentials |
| 404 | Entity not found | Log and skip |
| 429 | Rate limited | Wait and retry |
| 500 | Server error | Retry 3x with backoff |

---

## Configuration

```yaml
ttd:
  base_url: "https://api.thetradedesk.com/v3"
  token_refresh_interval: 3600  # 1 hour
  rate_limit:
    requests_per_minute: 100
    burst: 20
  retry:
    max_attempts: 3
    backoff_multiplier: 2
  report:
    poll_interval: 30s
    max_wait: 30m
```

---

## Navigation

- **Up:** [Integration Layer](../README.md)
- **Previous:** [DV360 Integration](../dv360/README.md)
- **Next:** [Meta Integration](../meta/README.md)
