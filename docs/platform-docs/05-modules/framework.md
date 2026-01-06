# Module Framework

> How modules work and how to configure them.

---

## Module Structure

Every module follows this standard pattern:

```yaml
module:
  id: "pacing"
  name: "Pacing & Margin"
  version: "1.0.0"
  
  # What this module needs to function
  dependencies:
    required:
      - dsp_connection
    optional:
      - booking_database
      - crm_integration
  
  # What features are available
  capabilities:
    base:
      - basic_pacing
      - spend_tracking
    enhanced:
      - margin_calculation  # requires: booking_database
      - variance_analysis   # requires: booking_database + crm_integration
  
  # Configuration schema
  configuration:
    fields:
      - name: pacing_formula
        type: formula
        default: "(delivered / booked) * (total_days / elapsed_days) * 100"
      - name: alert_threshold
        type: number
        default: 20
        range: [0, 100]
  
  # Failure handling
  failure_modes:
    dsp_unavailable:
      read_behavior: "serve_cached"
      stale_after: "4h"
    calculation_error:
      behavior: "show_last_valid"
      alert: true
```

---

## Module Lifecycle

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                          MODULE LIFECYCLE                                    │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│   DISABLED ──────────────────► ENABLING                                     │
│       ▲                            │                                        │
│       │                            │ Check dependencies                     │
│       │                            ▼                                        │
│       │                     Dependencies met?                               │
│       │                       │          │                                  │
│       │                      Yes         No                                 │
│       │                       │          │                                  │
│       │                       ▼          ▼                                  │
│       │                   ENABLED    BLOCKED                                │
│       │                       │          │                                  │
│       │                       │          │ Show missing deps                │
│       │                       │          │                                  │
│       │                       ▼          │                                  │
│       │               Running normally    │                                  │
│       │                       │          │                                  │
│       │                       ▼          │                                  │
│       │               User disables      │                                  │
│       │                       │          │                                  │
│       └───────────────────────┴──────────┘                                  │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Configuration Options

### Template-Based Configuration

Most users start with templates:

```json
{
  "templates": [
    {
      "id": "tmpl_pacing_standard",
      "name": "Standard Pacing",
      "description": "Track spend-based pacing with daily updates",
      "config": {
        "pacing_type": "spend",
        "update_frequency": "daily",
        "alert_thresholds": {
          "under_pacing": 80,
          "over_pacing": 120
        }
      },
      "usage_count": 156,
      "avg_satisfaction": 4.5
    }
  ]
}
```

### Custom Configuration

Power users can customize everything:

```json
{
  "pacing_formula": "CASE WHEN buy_model = 'CPM' THEN (impressions / booked_impressions) * 100 ELSE (spend / booked_spend) * 100 END",
  "margin_formula": "(booking_revenue - (spend + variable_costs)) / booking_revenue * 100",
  "alert_rules": [
    {
      "name": "Critical Under-Pacing",
      "condition": "pacing_rate < 50 AND days_remaining > 7",
      "severity": "critical",
      "channels": ["email", "slack"]
    }
  ]
}
```

---

## Capability Detection

The system automatically determines available capabilities:

```go
func (m *Module) GetAvailableCapabilities(org *Organization) []Capability {
    capabilities := m.BaseCapabilities
    
    // Check each optional dependency
    for _, dep := range m.OptionalDependencies {
        if org.HasIntegration(dep) {
            // Add capabilities unlocked by this dependency
            capabilities = append(capabilities, m.GetCapabilitiesFor(dep)...)
        }
    }
    
    return capabilities
}
```

---

## Failure Modes

### Graceful Degradation

When data sources are unavailable:

| Scenario | Behavior | User Experience |
|----------|----------|-----------------|
| DSP API down | Serve cached data | Banner: "Data may be stale" |
| Calculation error | Show last valid result | Warning icon on affected metrics |
| Rate limit hit | Queue request | "Refreshing in X minutes" |
| Config invalid | Block save | Inline validation errors |

### Circuit Breaker States

```
CLOSED (Normal)
    │
    │ 5 consecutive failures
    ▼
OPEN (Failing)
    │
    │ 30 seconds wait
    ▼
HALF-OPEN (Testing)
    │
    ├── Success → CLOSED
    │
    └── Failure → OPEN
```

---

## Module Permissions

Modules respect entity-level permissions:

| Permission | Allows |
|------------|--------|
| `view:{module}` | See module data |
| `configure:{module}` | Change module settings |
| `manage:{module}` | Enable/disable module |

```
User wants to view pacing for Campaign A:
1. Check user has `view:pacing` permission
2. Check user has `view` permission on Campaign A
3. Both pass → Show data
```

---

## Adding New Modules

### Module Registration

```go
type Module struct {
    ID           string
    Name         string
    Dependencies Dependencies
    Capabilities []Capability
    ConfigSchema ConfigSchema
    FailureModes FailureModes
}

func RegisterModule(m Module) error {
    // Validate module definition
    if err := validateModule(m); err != nil {
        return err
    }
    
    // Register with module registry
    return registry.Register(m)
}
```

### Checklist for New Modules

- [ ] Define module metadata (ID, name, version)
- [ ] Specify required and optional dependencies
- [ ] Define capabilities per dependency level
- [ ] Create configuration schema with defaults
- [ ] Define failure modes and degradation behavior
- [ ] Create UI components for configuration
- [ ] Write integration tests
- [ ] Document in module catalog

---

## Navigation

- **Previous:** [Module System Overview](README.md)
- **Next:** [Pacing & Margin Module](pacing/README.md)

