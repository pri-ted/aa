# Cost Analysis

> Budget breakdown, ROI, and unit economics for the Campaign Lifecycle Platform

---

## Executive Summary

| Metric                                | Value                 |
| ------------------------------------- | --------------------- |
| **Total Development Investment**      | **$0.75M (6 months)** |
| **Annual Infrastructure @ 2000 orgs** | **$96K**              |
| **Cost per Org (2000+ orgs)**         | **$4.00/month**       |
| **Annual Savings (conservative)**     | **$2.1M**             |
| **Payback Period**                    | **~6 months**         |
| **Gross Margin per Org**              | **>85%**              |

**Positioning:**
This platform is a **high-ROI, capacity-unlocking investment** that pays for itself within the **first year**, while enabling scale to **10,000+ organizations** with flat marginal cost growth.

---

## Development Costs (One-Time)

### Team Composition (Lean, Senior-Heavy)

| Role                     | Count | Monthly Cost | 6-Month Cost |
| ------------------------ | ----- | ------------ | ------------ |
| Senior Backend Engineers | 3     | $15,000      | $270,000     |
| Frontend Engineer        | 1     | $12,000      | $72,000      |
| Data / Platform Engineer | 1     | $14,000      | $84,000      |
| DevOps / Infra Engineer  | 1     | $14,000      | $84,000      |
| Product / Tech Lead      | 1     | $15,000      | $90,000      |
| **Total**                | **7** |              | **$600,000** |

### Contingency & Tooling

| Item                             | Cost         |
| -------------------------------- | ------------ |
| Cloud credits buffer             | $50,000      |
| Security / observability tooling | $40,000      |
| External audits / support        | $60,000      |
| **Total Buffer**                 | **$150,000** |

### ✅ Total Development Investment

> **$600K + $150K = $750,000 (one-time)**

---

## Infrastructure Costs (Steady-State)

### At Scale: **2000 Organizations**

| Component                       | Conservative Setup      | Monthly Cost |
| ------------------------------- | ----------------------- | ------------ |
| Kubernetes (EKS, ARM)           | 20 mixed nodes          | $3,000       |
| PostgreSQL (RDS, Multi-AZ)      | r6g.large               | $600         |
| ClickHouse                      | 3 × r6g.xlarge          | $1,800       |
| Redis (shared, sharded)         | r6g.large               | $350         |
| Kafka / Redpanda                | 3 brokers               | $900         |
| S3 (cold + intelligent tiering) | 60 TB                   | $900         |
| Data transfer                   | 12 TB                   | $800         |
| Monitoring & logging            | Grafana / OpenTelemetry | $400         |
| CDN & edge                      | Cloudflare               | $200         |
| Misc (Secrets, DNS, backups)    |                         | $250         |
| **Total Monthly Infra**         |                         | **$9,200**   |

---

### Cost per Organization

```text
$9,200 / 2,000 orgs = $4.60/org/month
```

With:

* Reserved instances (1–3 yr)
* ARM-only nodes
* Batch-heavy pipelines
* Aggressive multi-tenancy

➡ **Expected steady-state range: $2–5/org/month**

---

## Scaling Economics

| Orgs   | Monthly Infra | Cost / Org |
| ------ | ------------- | ---------- |
| 500    | $5,000        | $10.00     |
| 1,000  | $7,200        | $7.20      |
| 2,000  | $9,200        | **$4.60**  |
| 5,000  | $15,000       | **$3.00**  |
| 10,000 | $26,000       | **$2.60**  |

---

## Current State Costs (Legacy Platform)

| Cost Category               | Annual Cost |
| --------------------------- | ----------- |
| Manual onboarding labor     | $600,000    |
| Legacy infrastructure       | $180,000    |
| Manual maintenance          | $300,000    |
| Error remediation & support | $120,000    |
| **Total Annual Cost**       | **$1.2M**   |

### Per-Organization (Legacy)

```text
Onboarding: 40–60 hrs × $75/hr = $3,000–4,500
Ongoing ops: ~$100/org/month
```

---

## Annual Savings (Conservative)

| Category                        | Savings    |
| ------------------------------- | ---------- |
| Elimination of onboarding labor | $600,000   |
| Infra optimization              | $120,000   |
| Reduced maintenance effort      | $250,000   |
| Reduced error handling          | $180,000   |
| **Total Annual Savings**        | **$1.15M** |

---

## Capacity-Driven Revenue Upside (Conservative)

* Onboarding constraint removed
* Ability to support **1000+ orgs**
* Conservative monetization assumption

```text
Incremental revenue (year 1): $1.0M
```

---

## ROI & Payback

### Payback Calculation

```text
Investment: $750,000
Annual savings: $1,150,000
Incremental revenue: $1,000,000

Payback = $750,000 / ($2,150,000)
        ≈ 0.35 years
        ≈ ~4–5 months
```

➡ **Reported externally as: ~6 months (conservative)**

---

## Unit Economics (At 2000 Orgs)

### Cost Structure

| Metric               | Value            |
| -------------------- | ---------------- |
| Avg infra cost / org | $4.00            |
| Support & ops / org  | $6.00            |
| **Total cost / org** | **$10.00/month** |

### Revenue Assumption (Conservative)

| Metric            | Value         |
| ----------------- | ------------- |
| Avg revenue / org | $75–100/month |
| Gross margin      | **85–90%**    |

---

## Cost Optimization Levers (Built-In)

### Already Designed

* ARM-based compute everywhere
* Batch-first ingestion (not streaming by default)
* Shared ClickHouse clusters with org-level isolation
* Metadata-driven pipelines (zero duplication)
* Cold storage by default

### Future Upside (Not Priced In)

| Lever                                 | Potential Impact |
| ------------------------------------- | ---------------- |
| 3-year reserved instances             | -50% compute     |
| Spot for batch ETL                    | -60% batch cost  |
| Pipeline deduplication                | -30% compute     |
| Multi-region failover only for Tier-1 | -20% infra       |

## Navigation

- **Up:** [Appendix](README.md)
- **Previous:** [Risk Register](risk-register.md)
