# 🚀 Development

> Roadmap, migration strategy, and development guides.

---

## Section Contents

| Document | Description |
| ---------- | ------------- |
| [Development Roadmap](roadmap.md) | Phased delivery plan |
| [Migration Strategy](migration.md) | Moving from old system |
| [Development Guide](dev-guide.md) | How to contribute |
| [Local Dev Guide](local-dev.md) | How to do local setup |
| [Docker Compose Dev Guide](docker-compose-dev.yaml) | Compose stack on docker |
| [Env Variables for dev](environment-variables.md) | Environment Variables |

---

## Development Roadmap

### Phase Overview

| Phase | Focus | Timeline | Status |
| ------- | ------- | ---------- | -------- |
| **Phase 1** | Foundation + Self-Service | Months 1-4 | 🔄 In Progress |
| **Phase 2** | Core Modules | Months 5-8 | ⏳ Planned |
| **Phase 3** | Campaign Management | Months 9-12 | ⏳ Planned |
| **Phase 4** | Scale & Optimization | Year 2 | ⏳ Planned |

---

## Phase 1: Foundation (Months 1-4)

### Goals

- Self-service onboarding working end-to-end
- Basic alerting functional
- 10 pilot organizations migrated

### Deliverables

| Week | Deliverable | Team |
| ------ | ------------- | ------ |
| 1-2 | Infrastructure provisioning | Platform |
| 3-4 | Auth + Config Services | Backend |
| 5-6 | Connector Framework | Backend |
| 7-8 | Bronze Layer + ETL | Data |
| 9-10 | Silver + Gold Layers | Data |
| 11-12 | GraphQL Gateway + UI | Full Stack |
| 13-14 | Alerts Module | Backend |
| 15-16 | Pilot + Validation | All |

### Success Criteria

- [ ] New org onboarding < 30 minutes
- [ ] Data accuracy > 99%
- [ ] Zero critical bugs

---

## Phase 2: Core Modules (Months 5-8)

### Goals

- All read-only modules migrated
- 50 organizations on platform
- Feature parity with old system

### Deliverables

| Month | Module | Key Features |
| ------- | -------- | -------------- |
| 5 | Alerts (complete) | Rule builder, all types |
| 6 | Pacing & Margin | Booking integration |
| 7 | QA Module | Rule library, SDF |
| 8 | Taxonomy | Pattern builder |

### Success Criteria

- [ ] Feature parity: 100%
- [ ] Onboarding < 10 minutes
- [ ] 50 orgs migrated

---

## Phase 3: Campaign Management (Months 9-12)

### Goals

- Write-back to DSPs operational
- Auto-optimization rules
- Old system decommissioned

### Deliverables

| Month | Capability | DSPs |
| ------- | ------------ | ------ |
| 9 | Pause/Resume | DV360, TTD |
| 10 | Budget adjustments | All |
| 11 | Campaign creation | DV360 |
| 12 | Auto-optimization | All |

### Success Criteria
- [ ] Write-back success > 99%
- [ ] < 1% error rate
- [ ] Old system archived

---

## Phase 4: Scale & Advanced (Year 2)

### Goals

- SSP integrations
- 1000+ organizations
- Advanced automation

### Roadmap Items

- SSP connector framework
- Deal management module
- Inventory forecasting
- Cross-DSP optimization
- Attribution

---

## Migration Strategy

### Approach: Strangler Pattern

```text
Phase 1 (Months 1-4)
┌─────────────────┐     ┌─────────────────┐
│  Old Django     │     │  New Platform   │
│  (100% traffic)  │     │  (shadow mode)  │
└─────────────────┘     └─────────────────┘

Phase 2 (Months 5-8)
┌─────────────────┐     ┌─────────────────┐
│  Old Django     │     │  New Platform   │
│  (50% traffic)   │     │  (50% traffic)   │
└─────────────────┘     └─────────────────┘

Phase 3 (Months 9-12)
┌─────────────────┐     ┌─────────────────┐
│  Old Django     │     │  New Platform   │
│  (read-only)    │     │  (100% traffic)  │
└─────────────────┘     └─────────────────┘
```

### Module Migration Order

| Priority | Module | Risk | Duration |
| ---------- | -------- | ------ | ---------- |
| 1 | Alerts | Low | 4 weeks |
| 2 | Pacing | High | 6 weeks |
| 3 | QA | Medium | 4 weeks |
| 4 | Taxonomy | Low | 3 weeks |

### Data Migration

1. **Dual-Write Phase** - Write to both systems
2. **Validation Phase** - Compare results
3. **Cutover Phase** - Switch traffic
4. **Cleanup Phase** - Decommission old

---

## Team Structure

| Team | Focus | Size |
| ------ | ------- | ------ |
| **Platform** | Auth, Config, Infrastructure | 3 |
| **Data** | Pipeline, Lakehouse, Analytics | 4 |
| **Backend** | Services, Integrations | 4 |
| **Frontend** | UI, UX | 2 |

---

## Key Milestones

```text
┌─────────────────────────────────────────────────────────────────────────────┐
│                           PROJECT TIMELINE                                  │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│   M1    M2    M3    M4    M5    M6    M7    M8    M9    M10   M11   M12     │
│   │     │     │     │     │     │     │     │     │     │     │     │       │
│   ▼     ▼     ▼     ▼     ▼     ▼     ▼     ▼     ▼     ▼     ▼     ▼       │
│   ┌─────────────────┐                                                       │
│   │  Foundation     │                                                       │
│   │  Infrastructure │                                                       │
│   └─────────────────┘                                                       │
│               ┌─────┐                                                       │
│               │Alpha│                                                       │
│               └─────┘                                                       │
│                     ┌─────────────────────┐                                 │
│                     │  Core Modules       │                                 │
│                     │  Migration          │                                 │
│                     └─────────────────────┘                                 │
│                                     ┌─────┐                                 │
│                                     │Beta │                                 │
│                                     └─────┘                                 │
│                                           ┌─────────────────────┐           │
│                                           │  Campaign Mgmt      │           │
│                                           │  Write-back         │           │
│                                           └─────────────────────┘           │
│                                                               ┌─────┐       │
│                                                               │ GA  │       │
│                                                               └─────┘       │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Risk Register

| Risk | Impact | Probability | Mitigation |
| ------ | -------- | ------------- | ------------ |
| DSP API changes | High | Medium | Adapter abstraction |
| Migration data issues | High | Low | Parallel runs, validation |
| Team skill gaps | Medium | Medium | Training, pairing |
| Timeline slip | Medium | Medium | Buffer time, priorities |

---

## Navigation

- **Previous:** [Infrastructure](../08-infrastructure/README.md)
- **Next:** [Appendix](../10-appendix/README.md)

