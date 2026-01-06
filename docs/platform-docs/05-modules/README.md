# 📦 Module System

> Business modules and their configurations.

---

## Section Contents

| Document | Description |
|----------|-------------|
| [Module Framework](framework.md) | How modules work |
| [Pacing & Margin](pacing/README.md) | Campaign delivery tracking |
| [Alerts](alerts/README.md) | Rule-based notifications |
| [QA (Quality Assurance)](qa/README.md) | Campaign validation |
| [Taxonomy](taxonomy/README.md) | Naming convention validation |

---

## Module Overview

| Module | Purpose | Phase |
|--------|---------|-------|
| **Pacing & Margin** | Track delivery vs budget, calculate margins | 1 |
| **Alerts** | Monitor metrics, trigger notifications | 1 |
| **QA** | Validate campaign configurations | 1 |
| **Taxonomy** | Enforce naming conventions | 1 |
| **Campaign Management** | Create/modify campaigns in DSPs | 2 |
| **Optimization** | Auto-adjust budgets/bids | 2 |

---

## Module Dependencies

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        MODULE DEPENDENCY GRAPH                               │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│                          ┌─────────────────┐                                │
│                          │  DSP Connection │                                │
│                          │   (Required)    │                                │
│                          └────────┬────────┘                                │
│                                   │                                          │
│              ┌────────────────────┼────────────────────┐                    │
│              │                    │                    │                    │
│              ▼                    ▼                    ▼                    │
│     ┌────────────────┐  ┌────────────────┐  ┌────────────────┐            │
│     │     Pacing     │  │     Alerts     │  │       QA       │            │
│     │    (Basic)     │  │    (Basic)     │  │    (Basic)     │            │
│     └────────┬───────┘  └────────┬───────┘  └────────┬───────┘            │
│              │                   │                   │                      │
│              │                   │                   │                      │
│     ┌────────┴───────┐          │          ┌────────┴───────┐             │
│     │    Booking     │          │          │    Booking     │             │
│     │   Database     │          │          │   Database     │             │
│     │  (Optional)    │          │          │  (Optional)    │             │
│     └────────┬───────┘          │          └────────────────┘             │
│              │                   │                                          │
│              ▼                   │                                          │
│     ┌────────────────┐          │                                          │
│     │     Pacing     │          │                                          │
│     │   + Margins    │          │                                          │
│     └────────┬───────┘          │                                          │
│              │                   │                                          │
│     ┌────────┴───────┐          │                                          │
│     │      CRM       │          │                                          │
│     │  Integration   │          │                                          │
│     │  (Optional)    │          │                                          │
│     └────────┬───────┘          │                                          │
│              │                   │                                          │
│              ▼                   │                                          │
│     ┌────────────────┐          │                                          │
│     │  Full Pacing   │◄─────────┘                                          │
│     │  + Variance    │   (Can trigger alerts)                              │
│     └────────────────┘                                                      │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Capability Matrix

| Capability | DSP Only | + Booking | + CRM |
|------------|----------|-----------|-------|
| Basic Pacing | ✓ | ✓ | ✓ |
| Spend Tracking | ✓ | ✓ | ✓ |
| Budget Pacing | | ✓ | ✓ |
| Margin Calculation | | ✓ | ✓ |
| Booking Reconciliation | | | ✓ |
| Variance Analysis | | | ✓ |
| Performance Alerts | ✓ | ✓ | ✓ |
| Budget Alerts | | ✓ | ✓ |
| Margin Alerts | | ✓ | ✓ |
| DSP QA Checks | ✓ | ✓ | ✓ |
| Booking QA Checks | | ✓ | ✓ |
| Naming Validation | ✓ | ✓ | ✓ |
| Booking Cross-Ref | | ✓ | ✓ |

---

## Module Enablement

### User Flow

```
1. User enables module
      │
      ▼
2. System checks required dependencies
      │
      ├── Missing? → Show setup wizard
      │
      └── Met? → Continue
            │
            ▼
3. System checks optional dependencies
      │
      ├── Available → Enable enhanced features
      │
      └── Missing → Enable basic features + show upgrade path
            │
            ▼
4. Module active with available capabilities
```

### API

```
POST /api/v1/modules/{module_id}/enable

Response:
{
  "module": "pacing",
  "status": "enabled",
  "capabilities": {
    "enabled": ["basic_pacing", "spend_tracking"],
    "locked": ["margin_calculation", "variance_analysis"]
  },
  "unlock_requirements": {
    "margin_calculation": "Connect booking database",
    "variance_analysis": "Connect CRM integration"
  }
}
```

---

## Navigation

- **Previous:** [Data Architecture](../04-data/README.md)
- **Next:** [Integration Layer](../06-integrations/README.md)

