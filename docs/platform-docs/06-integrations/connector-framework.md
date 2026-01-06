# Connector Framework

> How DSP and external system connectors work.

---

## Connector Interface

All connectors implement this standard interface:

```go
type DSPConnector interface {
    // Authentication
    Authenticate(ctx context.Context, creds Credentials) (*Token, error)
    RefreshToken(ctx context.Context, token *Token) (*Token, error)
    
    // Read Operations
    FetchCampaigns(ctx context.Context, accountID string, filters Filters) ([]Campaign, error)
    FetchReport(ctx context.Context, config ReportConfig) (*Report, error)
    FetchSDF(ctx context.Context, advertiserIDs []string) (*SDFData, error)
    
    // Write Operations (Phase 2)
    CreateCampaign(ctx context.Context, campaign Campaign) (*Campaign, error)
    UpdateCampaign(ctx context.Context, id string, updates Updates) error
    PauseCampaign(ctx context.Context, id string) error
    ResumeCampaign(ctx context.Context, id string) error
    
    // Metadata
    GetRateLimits() RateLimitConfig
    GetSupportedFeatures() []Feature
}
```

---

## Rate Limiting

### Priority Queue

```text
Priority 1 (Highest): Manual triggers from premium users
Priority 2: Manual triggers from standard users
Priority 3: Scheduled jobs
Priority 4 (Lowest): Retry queue
```

### Request Batching

Similar requests within 5-minute window are merged.

---

## Circuit Breaker

```text
CLOSED (Normal) ──► 5 failures ──► OPEN (Failing)
       ▲                              │
       │                              │ 30s wait
       │                              ▼
       └─────── success ◄──── HALF-OPEN (Testing)
```

---

## Navigation

- **Up:** [Integration Layer](README.md)
