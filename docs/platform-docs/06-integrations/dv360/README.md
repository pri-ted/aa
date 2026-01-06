# DV360 Integration

> Google Display & Video 360 connector.

---

## Overview

| Property | Value |
| ---------- | ------- |
| **DSP** | DV360 |
| **Auth** | OAuth 2.0 |
| **API** | Display & Video 360 API v3 |
| **Read** | ✓ Implemented |
| **Write** | ○ Phase 2 |

---

## Authentication

### OAuth 2.0 Flow

1. User clicks "Connect DV360"
2. Redirect to Google OAuth consent
3. User authorizes scopes
4. Exchange code for tokens
5. Store encrypted refresh token

### Required Scopes

```code
https://www.googleapis.com/auth/display-video
https://www.googleapis.com/auth/doubleclickbidmanager
```

---

## Data Available

### Campaign Structure

| Entity | Fields |
| -------- | -------- |
| Partner | ID, name, status |
| Advertiser | ID, name, currency |
| Campaign | ID, name, budget, dates |
| Insertion Order | ID, name, budget, pacing |
| Line Item | ID, name, bid, targeting |
| Creative | ID, name, format, status |

### Performance Metrics

| Metric | Description |
| -------- | ------------- |
| Impressions | Ad views |
| Clicks | User clicks |
| Conversions | Completed actions |
| Spend | Media cost |
| Video Views | Video ad views |
| Video Completions | Videos watched to end |

---

## Rate Limits

| Limit | Value |
| ------- | ------- |
| Requests/minute | 50 |
| Requests/day | 10,000 |
| Burst | 100 |

---

## Read Operations

### Fetch Campaigns

```go
GET /v3/advertisers/{advertiserId}/campaigns
```

### Fetch Reports (Query-based)

1. Create query with metrics/dimensions
2. Submit query
3. Poll for completion
4. Download results

### Fetch SDF

1. Request SDF generation
2. Poll for completion
3. Download ZIP
4. Extract and parse CSVs

---

## Write Operations (Phase 2)

| Operation | Endpoint |
| ----------- | ---------- |
| Create Campaign | POST /v3/advertisers/{id}/campaigns |
| Update Campaign | PATCH /v3/campaigns/{id} |
| Pause Campaign | PATCH /v3/campaigns/{id} (status) |
| Update Budget | PATCH /v3/insertionOrders/{id} |

---

## Error Handling

| Error | Action |
| ------- | -------- |
| 401 Unauthorized | Refresh token |
| 403 Forbidden | Check permissions |
| 429 Rate Limit | Queue with backoff |
| 5xx Server Error | Retry 3x |

---

## Navigation

- **Up:** [Integration Layer](../README.md)
