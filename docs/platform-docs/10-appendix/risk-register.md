# Risk Register

> Identified risks and mitigation strategies.

---

## Risk Summary

| ID  | Risk                  | Probability | Impact   | Score | Status     |
| --- | --------------------- | ----------- | -------- | ----- | ---------- |
| R1  | DSP API changes       | High        | High     | 9     | Mitigating |
| R2  | Scale issues          | Medium      | High     | 6     | Monitoring |
| R3  | Data quality          | Medium      | Medium   | 4     | Mitigating |
| R4  | Key person dependency | High        | Medium   | 6     | Mitigating |
| R5  | Security breach       | Low         | Critical | 5     | Monitoring |
| R6  | Cost overrun          | Medium      | Medium   | 4     | Monitoring |

---

## R1: DSP API Changes

**Probability:** High  
**Impact:** High  
**Score:** 9

### Description

DSP providers (DV360, TTD, Meta) may change APIs without notice, breaking integrations.

### Mitigation Strategies

1. **Abstraction Layer** - Connector interface isolates changes
2. **Version Detection** - Auto-detect API versions
3. **Graceful Degradation** - Continue with cached data
4. **Monitoring** - Alert on API response changes
5. **Relationships** - Maintain DSP partner contacts

### Contingency Plan

- Switch to backup data source
- Notify affected customers
- Fast-track connector update

### Owner: Data Team Lead

---

## R2: Scale Issues at 1000+ Orgs

**Probability:** Medium  
**Impact:** High  
**Score:** 6

### Description

System may not handle 1000+ organizations efficiently.

### Mitigation Strategies

1. **Load Testing** - Regular testing at 2x target
2. **Horizontal Scaling** - All services stateless
3. **Caching** - Redis for hot data
4. **Database Sharding** - By org_id
5. **Async Processing** - Kafka for decoupling

### Early Warning Signs

- Query latency > 500ms
- CPU utilization > 70%
- Queue depth growing

### Owner: Platform Team Lead

---

## R3: Data Quality Issues

**Probability:** Medium  
**Impact:** Medium  
**Score:** 4

### Description

Poor data quality from DSPs or CRM may cause incorrect metrics.

### Mitigation Strategies

1. **Quality Gates** - Validation at each layer
2. **Quality Scoring** - Per-record quality score
3. **Anomaly Detection** - Flag unusual patterns
4. **Quarantine** - Isolate bad data
5. **Lineage** - Track data source

### Metrics to Watch

- Quality score < 90%
- Quarantine rate > 5%
- Reconciliation mismatches

### Owner: Data Team Lead

---

## R4: Key Person Dependency

**Probability:** High  
**Impact:** Medium  
**Score:** 6

### Description

Critical knowledge held by single team members (e.g., Sneh for legacy system).

### Mitigation Strategies

1. **Knowledge Transfer** - Documented sessions
2. **Pair Programming** - Share expertise
3. **Documentation** - Comprehensive docs
4. **Cross-Training** - Rotate responsibilities
5. **Hiring** - Build redundancy

### Current Dependencies

| Person | Knowledge               | Backup  |
| ------ | ----------------------- | ------- |
| Sneh   | Legacy system, DSP auth | Pending |
| TBD    | Infrastructure          | None    |

### Owner: Engineering Manager

---

## R5: Security Breach

**Probability:** Low  
**Impact:** Critical  
**Score:** 5

### Description

Unauthorized access to customer data or DSP credentials.

### Mitigation Strategies

1. **Encryption** - At rest and in transit
2. **Access Control** - RBAC + entity permissions
3. **Audit Logging** - All access logged
4. **Penetration Testing** - Quarterly
5. **SOC 2** - Compliance certification

### Contingency Plan

- Incident response team activation
- Credential rotation
- Customer notification
- Forensic analysis

### Owner: Security Lead

---

## R6: Cost Overrun

**Probability:** Medium  
**Impact:** Medium  
**Score:** 4

### Description

Infrastructure or development costs exceed budget.

### Mitigation Strategies

1. **Cost Monitoring** - Real-time tracking
2. **Budget Alerts** - At 75%, 90%
3. **Reserved Instances** - Commit for savings
4. **Right-sizing** - Regular resource review
5. **Cost per Org** - Track unit economics

### Budget Breakdown

| Category       | Budget   | Current  |
| -------------- | -------- | -------- |
| Infrastructure | $200K/yr | On track |
| Development    | $1.72M   | On track |
| Operations     | $150K/yr | On track |

### Owner: Finance Lead

---

## Risk Matrix

```text
Impact
  ▲
Critical │     │     │     │ R5  │
         │─────┼─────┼─────┼─────┤
High     │     │ R2  │ R1  │     │
         │─────┼─────┼─────┼─────┤
Medium   │     │R3 R6│ R4  │     │
         │─────┼─────┼─────┼─────┤
Low      │     │     │     │     │
         └─────┴─────┴─────┴─────▶ Probability
           Low   Med   High  Critical
```

---

## Navigation

- **Up:** [Appendix](README.md)
- **Previous:** [Decision Log](decision-log.md)
- **Next:** [Cost Analysis](cost-analysis.md)
