# 🔌 Integration Layer

> DSP and external system integrations.

---

## Section Contents

| Document | Description |
| ---------- | ------------- |
| [Connector Framework](connector-framework.md) | How connectors work |
| [DV360 Integration](dv360/README.md) | Google Display & Video 360 |
| [TTD Integration](ttd/README.md) | The Trade Desk |
| [Meta Integration](meta/README.md) | Facebook/Instagram Ads |
| [CRM Integration](crm/README.md) | Google Sheets, Booking DB |
| [Google Sheets](google-sheets/README.md) | Google Sheets, Booking DB |
| [Webhooks](webhooks/README.md) | Webhooks Support |

---

## Connector Overview

| DSP | Auth | Read | Write | Status |
| ----- | ------ | ------ | ------- | -------- |
| **DV360** | OAuth 2.0 | ✓ | ○ | Production |
| **TTD** | API Key | ✓ | ○ | Production |
| **Meta** | OAuth 2.0 | ✓ | ○ | Production |
| **Google Ads** | OAuth 2.0 | ✓ | ○ | Beta |
| **Amazon DSP** | OAuth 2.0 | ○ | ○ | Planned |

✓ = Implemented  ○ = Phase 2

---

## Connector Architecture

```text
┌─────────────────────────────────────────────────────────────────────────────┐
│                       CONNECTOR ARCHITECTURE                                │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│   ┌─────────────────────────────────────────────────────────────────────┐   │
│   │                    CONNECTOR ORCHESTRATOR                           │   │
│   │                                                                     │   │
│   │  ┌───────────────┐  ┌───────────────┐  ┌───────────────┐            │   │
│   │  │ Rate Limiter  │  │ Circuit       │  │ Request       │            │   │
│   │  │               │  │ Breaker       │  │ Queue         │            │   │
│   │  └───────────────┘  └───────────────┘  └───────────────┘            │   │
│   │                                                                     │   │
│   └─────────────────────────────────────────────────────────────────────┘   │
│                                    │                                        │
│              ┌─────────────────────┼─────────────────────┐                  │
│              │                     │                     │                  │
│              ▼                     ▼                     ▼                  │
│   ┌────────────────┐    ┌────────────────┐    ┌────────────────┐            │
│   │  DV360 Adapter │    │  TTD Adapter   │    │  Meta Adapter  │            │
│   │                │    │                │    │                │            │
│   │  • OAuth 2.0   │    │  • API Key     │    │  • OAuth 2.0   │            │
│   │  • Query-based │    │  • Template    │    │  • Graph API   │            │
│   │  • SDF support │    │  • Bulk ops    │    │  • Insights    │            │
│   └────────────────┘    └────────────────┘    └────────────────┘            │
│              │                     │                     │                  │
│              └─────────────────────┼─────────────────────┘                  │
│                                    │                                        │
│                                    ▼                                        │
│                            DSP APIs (External)                              │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Connector Interface

All connectors implement this interface:

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

### Per-DSP Limits

| DSP | Requests/Min | Daily Limit | Burst |
| ----- | -------------- | ------------- | ------- |
| DV360 | 50 | 10,000 | 100 |
| TTD | 100 | 50,000 | 200 |
| Meta | 200/hour | - | 300 |
| Google Ads | 15,000/day | 15,000 | 100 |

### Priority Queue

```text
Priority 1 (Highest)
  └── Manual triggers from premium users

Priority 2
  └── Manual triggers from standard users

Priority 3
  └── Scheduled jobs

Priority 4 (Lowest)
  └── Retry queue
```

---

## Circuit Breaker Configuration

```yaml
circuit_breaker:
  dv360:
    failure_threshold: 5          # failures before opening
    recovery_timeout: 30s         # time before half-open
    success_threshold: 2          # successes to close
  ttd:
    failure_threshold: 5
    recovery_timeout: 30s
    success_threshold: 2
  meta:
    failure_threshold: 3          # lower threshold (stricter API)
    recovery_timeout: 60s
    success_threshold: 3
```

---

## OAuth Flow

```text
┌─────────────────────────────────────────────────────────────────────────────┐
│                            OAUTH 2.0 FLOW                                   │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│   User                    Platform                     DSP                  │
│     │                        │                          │                   │
│     │  1. Click "Connect"    │                          │                   │
│     │ ─────────────────────► │                          │                   │
│     │                        │                          │                   │
│     │  2. Redirect to DSP    │                          │                   │
│     │ ◄───────────────────── │                          │                   │
│     │                        │                          │                   │
│     │  3. Login & Authorize  │                          │                   │
│     │ ─────────────────────────────────────────────────►│                   │
│     │                        │                          │                   │
│     │  4. Redirect with code │                          │                   │
│     │ ◄─────────────────────────────────────────────────│                   │
│     │                        │                          │                   │
│     │                        │  5. Exchange code        │                   │
│     │                        │ ────────────────────────►│                   │
│     │                        │                          │                   │
│     │                        │  6. Access + Refresh     │                   │
│     │                        │ ◄────────────────────────│                   │
│     │                        │                          │                   │
│     │  7. Connection success │                          │                   │
│     │ ◄───────────────────── │                          │                   │
│     │                        │                          │                   │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Error Handling

| Error Type | Action | User Message |
| ------------ | -------- | -------------- |
| Auth expired | Refresh token | (Silent) |
| Auth revoked | Prompt reconnect | "Please reconnect your account" |
| Rate limit | Queue with backoff | "Request queued, ~5 min wait" |
| API error | Retry 3x | "Temporary issue, retrying" |
| Permanent error | Alert + skip | "Could not fetch data for X" |

---

## Navigation

- **Previous:** [Module System](../05-modules/README.md)
- **Next:** [Security Architecture](../07-security/README.md)
