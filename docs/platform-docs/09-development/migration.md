# Migration Strategy

> Moving from legacy system to new platform.

---

## Migration Overview

### Current State

- 24 organizations on legacy system
- 97 manual steps per onboarding
- 40-60 hours per organization
- No self-service capability

### Target State

- 1000+ organizations on new platform
- Automated onboarding
- 5 minutes per organization
- Full self-service

---

## Migration Approach

### Strangler Pattern

```text
┌─────────────────────────────────────────────────────────────────────────────┐
│                        STRANGLER PATTERN                                    │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│   Phase 1: Shadow                                                           │
│   ┌─────────┐     ┌─────────┐     ┌─────────┐                               │
│   │ Traffic  │ ──▶ │ Legacy  │ ──▶ │ Response│                               │
│   │         │     │ System  │     │         │                               │
│   │         │ ──▶ │ New     │ ──▶ │ Compare │ (logged, not returned)        │
│   └─────────┘     └─────────┘     └─────────┘                               │
│                                                                             │
│   Phase 2: Parallel                                                         │
│   ┌─────────┐     ┌─────────┐     ┌─────────┐                               │
│   │ Traffic  │ ──▶ │ Legacy  │ ──▶ │ Response│                               │
│   │         │     │         │     │         │                               │
│   │ New Orgs│ ──▶ │ New     │ ──▶ │ Response│                               │
│   └─────────┘     └─────────┘     └─────────┘                               │
│                                                                             │
│   Phase 3: Cutover                                                          │
│   ┌─────────┐     ┌─────────┐     ┌─────────┐                               │
│   │ Traffic  │ ──▶ │ New     │ ──▶ │ Response│                               │
│   │         │     │ System  │     │         │                               │
│   └─────────┘     └─────────┘     └─────────┘                               │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Organization Migration

### Migration Phases

| Phase | Organizations | Duration |
| ------- | --------------- | ---------- |
| Pilot | 3 orgs | 2 weeks |
| Early Adopter | 10 orgs | 4 weeks |
| General | Remaining | 8 weeks |

### Per-Organization Steps

#### 1. Pre-Migration**

- [ ] Audit current configuration
- [ ] Document custom logic
- [ ] Export historical data
- [ ] Verify DSP credentials

#### 2. Data Migration**

- [ ] Create organization in new system
- [ ] Import users and roles
- [ ] Configure DSP connections
- [ ] Migrate pipelines

#### 3. Validation**

- [ ] Run parallel for 7 days
- [ ] Compare data accuracy
- [ ] Verify all metrics match
- [ ] User acceptance testing

#### 4. Cutover**

- [ ] Disable legacy access
- [ ] Enable new platform
- [ ] Monitor for 48 hours
- [ ] Decommission legacy

---

## Data Migration

### Historical Data

```sql
-- Export from legacy
COPY (
  SELECT 
    org_id,
    campaign_id,
    metric_date,
    impressions,
    clicks,
    spend
  FROM legacy_metrics
  WHERE org_id = 123
    AND metric_date >= '2024-01-01'
) TO '/export/org_123_metrics.csv';

-- Import to new platform
INSERT INTO silver.campaign_metrics
SELECT * FROM read_csv('/export/org_123_metrics.csv');
```

### Configuration Migration

```yaml
migration:
  source:
    type: "legacy_db"
    connection: "${LEGACY_DB_URL}"
  
  mappings:
    pipelines:
      source_table: "legacy_pipelines"
      target_table: "pipelines"
      field_mappings:
        - legacy: "pipeline_name"
          new: "name"
        - legacy: "cron_schedule"
          new: "schedule.expression"
    
    rules:
      source_table: "legacy_alerts"
      target_table: "rules"
      transform: "alert_to_rule_converter"
```

---

## Rollback Plan

### Rollback Triggers

- Data accuracy < 99%
- Error rate > 1%
- User-reported critical issues
- DSP sync failures

### Rollback Procedure

```bash
# 1. Re-enable legacy access
./scripts/enable-legacy.sh --org 123

# 2. Redirect traffic
kubectl patch ingress platform \
  -p '{"spec":{"rules":[{"host":"org123.platform.com","backend":"legacy"}]}}'

# 3. Notify users
./scripts/notify-org.sh --org 123 --message "rollback"

# 4. Investigate
tail -f /var/log/platform/org-123.log
```

---

## Success Metrics

| Metric | Target | Measurement |
| -------- | -------- | ------------- |
| Data accuracy | 99.9% | Automated comparison |
| Feature parity | 100% | Checklist validation |
| User satisfaction | > 4/5 | Survey |
| Support tickets | < 5/org | Ticket count |

---

## Timeline

```text
Week 1-2:   Pilot (3 orgs)
Week 3-4:   Pilot validation & fixes
Week 5-8:   Early adopters (10 orgs)
Week 9-12:  General migration batch 1
Week 13-16: General migration batch 2
Week 17-18: Legacy decommission
```

---

## Navigation

- **Up:** [Development](README.md)
- **Previous:** [Roadmap](roadmap.md)
- **Next:** [Development Guide](dev-guide.md)
