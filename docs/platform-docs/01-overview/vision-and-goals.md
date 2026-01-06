# Vision & Strategic Goals

> The north star for platform development.

---

## Platform Vision

> **"Any media agency, regardless of size, can connect their DSPs, configure their workflows, and start managing campaigns in under 10 minutes — with zero engineering support."**

---

## Strategic Goals

### G1: Eliminate Engineering Bottleneck

Every customer action that currently requires engineering must become self-service through UI-driven configuration.

| Current | Target |
| --------- | -------- |
| Engineer creates BigQuery tables | Auto-provisioned on signup |
| Engineer writes org-specific SQL | User configures via formula builder |
| Engineer deploys config changes | User saves config in UI |
| Engineer debugs pipeline failures | User sees clear error + auto-fix |

### G2: Enable Campaign Lifecycle Management

Progress from read-only analytics to full campaign lifecycle control:

```text
┌─────────────────────────────────────────────────────────────────────┐
│                    CAMPAIGN LIFECYCLE                               │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│   PLAN ──▶ BUILD ──▶ LAUNCH ──▶ MONITOR ──▶ OPTIMIZE ──▶ REPORT     │
│    │        │         │          │           │           │          │
│    ▼        ▼         ▼          ▼           ▼           ▼          │
│  Budget   Campaign   QA        Pacing     Auto-Bid    Cross-DSP     │
│  Alloc    Creation   Valid     Alerts     Adjust      Analytics     │
│                                                                     │
│  Phase 3  Phase 2   Phase 1   Phase 1    Phase 2     Phase 1        │
└─────────────────────────────────────────────────────────────────────┘
```

### G3: Cloud-Agnostic & Resilient

| Requirement | Implementation |
| ------------- | ---------------- |
| Run on any cloud | Kubernetes-native, no cloud-specific services |
| Survive failures | Circuit breakers, graceful degradation |
| Scale horizontally | Stateless services, partitioned data |
| No vendor lock-in | Open formats (Iceberg), standard protocols |

### G4: Cost-Efficient Multi-Tenancy

| Goal | Approach |
| ------ | ---------- |
| 10x cost reduction | Shared infrastructure, smart scheduling |
| Resource isolation | Namespace per tier, quotas per org |
| Usage-based billing | Metering at service level |
| Predictable costs | Budget alerts, cost tracking |

---

## Non-Goals (Explicit)

| Non-Goal | Reason | Revisit When |
| ---------- | -------- | -------------- |
| Real-time streaming (< 1 min) | 15-min batch sufficient | Month 6+ |
| Multi-region deployment | Single region meets latency | Year 1 |
| Custom DSP connector development | Security risk, complexity | Never |
| Mobile-first UI | Desktop workflow primary | Year 1 |
| AI-powered automation | Focus on reliable manual first | Month 12+ |

---

## User Personas

### Campaign Manager

#### Primary User

- Day-to-day campaign operations
- Needs: Unified dashboard, automated QA, real-time alerts
- Success: Manage 2x campaigns with same effort

### Media Planner

#### Strategic User

- Campaign strategy and budget allocation
- Needs: Booking integration, margin tracking
- Success: 50% faster planning cycles

### Media Buyer / Trader

#### Power User

- Campaign optimization and execution
- Needs: Auto-optimization rules, bulk operations
- Success: 30% better campaign performance

### Agency Admin

#### Governance User

- Platform governance and team management
- Needs: Cost tracking, access control
- Success: Full visibility, compliance

---

## Success Metrics by Phase

### Phase 1: Foundation

| Metric | Target |
| -------- | -------- |
| Onboarding time | < 30 minutes |
| Data accuracy | > 99% |
| Platform uptime | 99.9% |
| API latency (p95) | < 200ms |

### Phase 2: Core Modules

| Metric | Target |
| -------- | -------- |
| Onboarding time | < 10 minutes |
| Feature parity | 100% |
| User satisfaction | > 4.0/5.0 |
| Support tickets | 50% reduction |

### Phase 3: Campaign Management

| Metric | Target |
| -------- | -------- |
| Write-back success | > 99% |
| Auto-optimization adoption | > 60% |
| Cross-DSP operations | Supported |
| Old system | Decommissioned |

---

## Navigation

- **Previous:** [Executive Summary](executive-summary.md)
- **Next:** [Architectural Principles](principles.md)
