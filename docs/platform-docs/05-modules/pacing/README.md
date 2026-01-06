# Pacing & Margin Module

> Track campaign delivery against booked targets and calculate margins.

---

## Overview

| Property | Value |
|----------|-------|
| **Module ID** | pacing |
| **Phase** | 1 |
| **Required Dependencies** | DSP Connection |
| **Optional Dependencies** | Booking Database, CRM |

---

## Capabilities

| Capability | Dependencies | Description |
|------------|--------------|-------------|
| Basic Pacing | DSP | Spend/impressions vs time |
| Spend Tracking | DSP | Raw spend metrics |
| Budget Pacing | DSP + Booking | Delivery vs booked |
| Margin Calculation | DSP + Booking | Revenue - Cost |
| Variance Analysis | DSP + Booking + CRM | Booking reconciliation |

---

## Key Metrics

### Pacing Rate

```
pacing_rate = (delivered / booked) × (total_days / elapsed_days) × 100

Where:
- delivered = actual impressions or spend
- booked = target impressions or spend
- total_days = flight duration
- elapsed_days = days since start
```

### Margin Percent

```
margin_percent = ((booking_revenue - actual_cost) / booking_revenue) × 100

Where:
- booking_revenue = client-facing revenue
- actual_cost = DSP spend + variable costs
```

### Pacing Status

| Status | Condition |
|--------|-----------|
| On Track | 90% ≤ pacing_rate ≤ 110% |
| Under Pacing | pacing_rate < 90% |
| Over Pacing | pacing_rate > 110% |
| Critical Under | pacing_rate < 50% |
| Critical Over | pacing_rate > 150% |

---

## Configuration

```yaml
pacing:
  formulas:
    pacing_rate: "(delivered / booked) * (total_days / elapsed_days) * 100"
    margin: "((revenue - cost) / revenue) * 100"
  
  thresholds:
    under_pacing: 90
    over_pacing: 110
    critical_under: 50
    critical_over: 150
  
  update_frequency: "hourly"
```

---

## Data Sources

| Source | Data | Required |
|--------|------|----------|
| DSP | Impressions, clicks, spend | Yes |
| Booking DB | Booked amount, dates, rate | Optional |
| CRM | Client name, deal ID | Optional |

---

## Alerts Integration

The pacing module can trigger alerts:

```yaml
alert_rules:
  - name: "Critical Under-Pacing"
    condition: "pacing_rate < 50 AND days_remaining > 7"
    severity: "critical"
    
  - name: "Over-Pacing Warning"
    condition: "pacing_rate > 120"
    severity: "warning"
```

---

## Navigation

- **Up:** [Module System](../README.md)
