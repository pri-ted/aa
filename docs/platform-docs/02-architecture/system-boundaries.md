# System Boundaries

> What's in scope and out of scope for the platform.

---

## Boundary Overview

```text
┌─────────────────────────────────────────────────────────────────────────────┐
│                          EXTERNAL SYSTEMS                                   │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  DEMAND SIDE (DSPs)              SUPPLY SIDE (Future - Phase 3)             │
│  ┌─────────┐ ┌─────────┐        ┌─────────┐ ┌─────────┐                     │
│  │ DV360   │ │   TTD   │        │   GAM   │ │  Index  │                     │
│  │ READ ✓  │ │ READ ✓  │        │ Phase 3 │ │ Phase 3 │                     │
│  │ WRITE ○ │ │ WRITE ○ │        └─────────┘ └─────────┘                     │
│  └─────────┘ └─────────┘                                                    │
│  ┌─────────┐ ┌─────────┐        DATA SOURCES                                │
│  │  Meta   │ │ Google  │        ┌─────────┐ ┌─────────┐                     │
│  │ READ ✓  │ │  Ads    │        │  CRM    │ │ Booking │                     │
│  │ WRITE ○ │ │ READ ✓  │        │ Sheets  │ │   DB    │                     │
│  └─────────┘ └─────────┘        └─────────┘ └─────────┘                     │
│                                                                             │
│  ✓ = Implemented  ○ = Phase 2                                               │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│                    ┌───────────────────────────────┐                        │
│                    │       PLATFORM BOUNDARY       │                        │
│                    │                               │                        │
│                    │  ┌─────────────────────────┐  │                        │
│                    │  │      INGEST (READ)      │  │                        │
│                    │  │  • DSP data ingestion   │  │                        │
│                    │  │  • CRM integration      │  │                        │
│                    │  │  • Booking sync         │  │                        │
│                    │  └─────────────────────────┘  │                        │
│                    │             │                 │                        │
│                    │             ▼                 │                        │
│                    │  ┌─────────────────────────┐  │                        │
│                    │  │   PROCESS (TRANSFORM)   │  │                        │
│                    │  │  • Bronze → Silver      │  │                        │
│                    │  │  • Silver → Gold        │  │                        │
│                    │  │  • Calculations         │  │                        │
│                    │  └─────────────────────────┘  │                        │
│                    │             │                 │                        │
│                    │             ▼                 │                        │
│                    │  ┌─────────────────────────┐  │                        │
│                    │  │    EXECUTE (WRITE)      │  │                        │
│                    │  │  • Campaign CRUD ○      │  │                        │
│                    │  │  • Budget updates ○     │  │                        │
│                    │  │  • Targeting changes ○  │  │                        │
│                    │  └─────────────────────────┘  │                        │
│                    │                               │                        │
│                    └───────────────────────────────┘                        │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## In Scope

### Phase 1: Read Operations (Current)

| Capability | Description | Status |
| ------------ | ------------- | -------- |
| DSP Data Ingestion | Pull campaign/performance data from DV360, TTD, Meta, Google Ads | ✓ Building |
| CRM Integration | Sync booking data from Google Sheets | ✓ Building |
| Booking Database | Connect to external booking systems | ✓ Building |
| Data Transformation | Bronze → Silver → Gold pipeline | ✓ Building |
| Pacing Calculation | Deliver vs budget tracking | ✓ Building |
| Margin Calculation | Revenue - Cost analysis | ✓ Building |
| QA Validation | Campaign configuration checks | ✓ Building |
| Alerting | Rule-based notifications | ✓ Building |
| Taxonomy | Naming convention validation | ✓ Building |
| Dashboards | Real-time analytics views | ✓ Building |

### Phase 2: Write Operations (Month 3+)

| Capability | Description | Status |
| ------------ | ------------- | -------- |
| Campaign Pause/Resume | Control campaign status via platform | ○ Designed |
| Budget Adjustments | Modify campaign/IO budgets | ○ Designed |
| Targeting Updates | Change targeting parameters | ○ Designed |
| Campaign Creation | Create new campaigns in DSPs | ○ Designed |
| Auto-Optimization | Rule-triggered automatic adjustments | ○ Designed |

### Phase 3: Supply Integration (Year 2+)

| Capability | Description | Status |
| ------------ | ------------- | -------- |
| SSP Connections | GAM, Index Exchange, Magnite | ◇ Future |
| Deal Management | Create/manage programmatic deals | ◇ Future |
| Inventory Forecasting | Predict available inventory | ◇ Future |
| Unified Deal Library | Cross-SSP deal management | ◇ Future |

---

## Out of Scope

### Permanent Out of Scope

| Item | Reason |
| ------ | -------- |
| **Real-time bidding execution** | DSPs handle bid execution |
| **Creative production** | Handled by creative tools |
| **CRM system management** | We integrate, not manage |
| **Payment processing** | Handled by DSPs/finance systems |
| **DSP platform development** | We use DSP APIs |
| **Ad verification** | Third-party services (IAS, DV, etc.) |

### Deferred (May revisit)

| Item | Defer Until | Reason |
| ------ | ------------- | -------- |
| Real-time streaming (< 1 min) | Month 9+ | 15-min batch sufficient |
| Multi-region deployment | Year 1 | Single region meets latency |
| Custom connector development | Never | Security risk |
| Mobile-first UI | Year 1 | Desktop workflow primary |
| AI-powered optimization | Month 12+ | Manual first |

---

## Interface Points

### External Systems We Read From

| System | Data | Frequency | Method |
| -------- | ------ | ----------- | -------- |
| DV360 | Campaigns, Reports, SDF | Daily/Hourly | REST API |
| TTD | Campaigns, Reports | Daily/Hourly | REST API |
| Meta | Campaigns, Insights | Daily/Hourly | Graph API |
| Google Ads | Campaigns, Reports | Daily/Hourly | Google Ads API |
| Google Sheets | Booking data | Hourly | Sheets API |
| Booking DB | Deal information | Real-time | Direct SQL |

### External Systems We Write To (Phase 2)

| System | Operations | Method |
| -------- | ------------ | -------- |
| DV360 | Campaign CRUD, Budget | REST API |
| TTD | Campaign CRUD, Budget | REST API |
| Meta | Campaign CRUD, Budget | Graph API |
| Google Ads | Campaign CRUD, Budget | Google Ads API |

### Systems We Notify

| System | When | Method |
| -------- | ------ | -------- |
| Email (SendGrid) | Alerts, Reports | SMTP/API |
| Slack | Alerts, Notifications | Webhook |
| Custom Webhooks | Configurable triggers | HTTP POST |

---

## Data Ownership

| Data Type | Owner | Source of Truth |
| ----------- | ------- | ----------------- |
| User accounts | Platform | PostgreSQL |
| Organization config | Platform | PostgreSQL |
| Pipeline definitions | Platform | PostgreSQL |
| Rules & alerts | Platform | PostgreSQL |
| Campaign structure | DSP | DSP APIs |
| Performance metrics | DSP | DSP APIs |
| Booking data | Client | CRM/Booking DB |
| Processed analytics | Platform | ClickHouse |

**Key Principle:** DSPs are the source of truth for campaign data. Platform syncs and enriches but doesn't override DSP state without explicit write-back.

---

## Dependency Matrix

```text
                    ┌─────────────────────────────────────────────────────┐
                    │              EXTERNAL DEPENDENCIES                  │
                    ├─────────────────────────────────────────────────────┤
                    │                                                     │
Platform Feature    │ DV360  TTD  Meta  GSheet  BookingDB  Slack  Email   │
────────────────────┼─────────────────────────────────────────────────────│
Basic Dashboards    │   ◐     ◐    ◐      ○         ○        ○      ○     │
Pacing              │   ●     ●    ●      ○         ◐        ○      ○     │
Margin              │   ●     ●    ●      ●         ●        ○      ○     │
QA Validation       │   ●     ●    ●      ○         ◐        ○      ○     │
Alerts              │   ●     ●    ●      ○         ○        ◐      ◐     │
Taxonomy            │   ●     ●    ●      ○         ◐        ○      ○     │
Campaign Mgmt (P2)  │   ●     ●    ●      ○         ○        ○      ○     │
                    │                                                     │
● = Required  ◐ = Optional  ○ = Not needed                                │
                    └─────────────────────────────────────────────────────┘
```

---

## Navigation

- **Previous:** [High-Level Design](hld.md)
- **Next:** [Data Flow](data-flow.md)
