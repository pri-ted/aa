# QA Module

> Campaign configuration validation and compliance checking.

---

## Module Overview

| Property | Value |
|----------|-------|
| **Module ID** | qa |
| **Phase** | 1 (Read-Only) |
| **Required Dependencies** | DSP Connection |
| **Optional Dependencies** | Booking Database |

---

## Purpose

The QA module validates campaign configurations against organizational rules and industry best practices. It identifies misconfigurations, compliance issues, and optimization opportunities before they impact performance.

---

## QA Check Categories

### Configuration Checks
| Check | Description | Severity |
|-------|-------------|----------|
| Budget Alignment | Campaign budget matches booking | Error |
| Date Alignment | Flight dates match booking | Error |
| Targeting Completeness | Required targeting set | Warning |
| Creative Status | All creatives approved | Error |
| Frequency Cap | Frequency cap configured | Warning |

### Compliance Checks
| Check | Description | Severity |
|-------|-------------|----------|
| Brand Safety | Brand safety settings enabled | Error |
| Viewability | Viewability threshold set | Warning |
| Geo Compliance | Targeting matches allowed regions | Error |
| Data Privacy | Privacy settings compliant | Error |

### Performance Checks
| Check | Description | Severity |
|-------|-------------|----------|
| Bid Strategy | Bid strategy appropriate for goal | Warning |
| Budget Pacing | Daily budget allows full delivery | Warning |
| Audience Size | Audience not too narrow | Info |
| Creative Variety | Multiple creatives active | Info |

---

## QA Rule Configuration

### Basic QA Rule
```yaml
rule:
  name: "Budget Mismatch Check"
  type: "qa_check"
  enabled: true
  
  conditions:
    operator: "AND"
    conditions:
      - field: "campaign_budget"
        operator: "!="
        value: "${booking_budget}"
        tolerance: 0.05  # 5% tolerance
      - field: "campaign_status"
        operator: "=="
        value: "active"
  
  severity: "error"
  category: "configuration"
  
  message_template: |
    Campaign budget (${{campaign_budget}}) does not match 
    booking budget (${{booking_budget}}).
  
  recommendation: |
    Update campaign budget to match booking or 
    revise booking if intentional.
```

### Complex Validation Rule
```yaml
rule:
  name: "Launch Readiness Check"
  type: "qa_check"
  
  conditions:
    operator: "AND"
    conditions:
      - field: "campaign_status"
        operator: "=="
        value: "active"
      - operator: "OR"
        conditions:
          - field: "creatives_approved"
            operator: "<"
            value: 1
          - field: "targeting_configured"
            operator: "=="
            value: false
          - field: "budget"
            operator: "<="
            value: 0
  
  severity: "error"
  category: "launch_readiness"
  
  auto_actions:
    - type: "flag_campaign"
      flag: "not_launch_ready"
```

---

## QA Dashboard Metrics

### Overall Health Score
```
QA Score = (Passed Checks / Total Checks) × 100

Grading:
  A (95-100%): Excellent
  B (85-94%):  Good
  C (70-84%):  Needs Attention
  D (50-69%):  Poor
  F (<50%):    Critical
```

### Issue Distribution
| Category | Weight | Impact on Score |
|----------|--------|-----------------|
| Configuration | 40% | High |
| Compliance | 35% | Critical |
| Performance | 25% | Medium |

---

## Check Execution

### Execution Modes

| Mode | Description | Use Case |
|------|-------------|----------|
| Real-time | On campaign save | Immediate feedback |
| Scheduled | Hourly/Daily cron | Ongoing monitoring |
| On-demand | Manual trigger | Pre-launch review |
| Batch | All campaigns | Weekly audit |

### Execution Flow
```
┌─────────────┐     ┌──────────────┐     ┌─────────────┐
│   Trigger   │ ──▶ │  Load Rules  │ ──▶ │ Fetch Data  │
└─────────────┘     └──────────────┘     └─────────────┘
                                               │
                                               ▼
┌─────────────┐     ┌──────────────┐     ┌─────────────┐
│   Report    │ ◀── │   Evaluate   │ ◀── │   Prepare   │
└─────────────┘     └──────────────┘     └─────────────┘
```

---

## Issue Resolution

### Auto-Fix Suggestions
```yaml
issue:
  type: "frequency_cap_missing"
  severity: "warning"
  
  auto_fix:
    available: true
    action: "set_frequency_cap"
    suggested_value: 3
    suggested_unit: "per_day"
    confidence: 0.85
    source: "organization_default"
```

### Resolution Workflow
1. **Detect** - QA check identifies issue
2. **Notify** - Alert sent to campaign owner
3. **Review** - Owner reviews issue details
4. **Resolve** - Apply fix (manual or auto)
5. **Verify** - Re-run check to confirm

---

## Pre-built Check Templates

### DV360 Checks
| Template | Validates |
|----------|-----------|
| `dv360_brand_safety` | Brand safety settings |
| `dv360_viewability` | Viewability targets |
| `dv360_frequency` | Frequency cap configuration |
| `dv360_geo_targeting` | Geographic targeting |

### TTD Checks
| Template | Validates |
|----------|-----------|
| `ttd_bid_strategy` | Bid optimization settings |
| `ttd_budget_flight` | Budget allocation |
| `ttd_data_segments` | Audience targeting |

### Universal Checks
| Template | Validates |
|----------|-----------|
| `budget_booking_match` | Budget vs. booking alignment |
| `date_booking_match` | Dates vs. booking alignment |
| `creative_approval` | Creative approval status |

---

## API Endpoints

### POST /api/v1/qa/check
Run QA checks on specified campaigns.

**Request:**
```json
{
  "campaign_ids": ["camp_123", "camp_456"],
  "check_types": ["configuration", "compliance"],
  "mode": "full"
}
```

**Response:**
```json
{
  "summary": {
    "total_campaigns": 2,
    "passed": 1,
    "failed": 1,
    "score": 75.5
  },
  "results": [
    {
      "campaign_id": "camp_123",
      "campaign_name": "Holiday Campaign",
      "score": 95.0,
      "issues": []
    },
    {
      "campaign_id": "camp_456",
      "campaign_name": "Q4 Push",
      "score": 56.0,
      "issues": [
        {
          "check": "budget_mismatch",
          "severity": "error",
          "message": "Budget differs from booking by 15%",
          "auto_fix_available": true
        }
      ]
    }
  ]
}
```

---

## Navigation

- **Up:** [Module System](../README.md)
- **Previous:** [Alerts Module](../alerts/README.md)
- **Next:** [Taxonomy Module](../taxonomy/README.md)
