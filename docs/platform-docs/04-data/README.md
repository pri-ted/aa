# 💾 Data Architecture

> Database schemas, API specifications, and data lake design.

---

## Section Contents

| Document | Description |
| ---------- | ------------- |
| [Database Schemas](schemas/README.md) | PostgreSQL and ClickHouse table definitions |
| [API Specifications](apis/README.md) | Complete REST and GraphQL API reference |
| [Iceberg Lakehouse](lakehouse/README.md) | Bronze/Silver/Gold layer design |
| [Events Specifications](events/README.md) | Event schemas for asynchronous messaging between services |
| [Proto Specifications](proto/README.md) | service contracts for inter-service communication |

---

## Data Storage Overview

```text
┌─────────────────────────────────────────────────────────────────────────────┐
│                          DATA STORAGE ARCHITECTURE                          │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│   ┌─────────────────────────────────────────────────────────────────────┐   │
│   │                      POSTGRESQL (OLTP)                              │   │
│   │  • Users, Organizations, Permissions                                │   │
│   │  • Configurations, Pipelines, Rules                                  │   │
│   │  • Audit logs, Sessions                                             │   │
│   │  Characteristics: ACID, low latency, referential integrity          │   │
│   └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
│   ┌─────────────────────────────────────────────────────────────────────┐   │
│   │                      CLICKHOUSE (OLAP)                              │   │
│   │  • Campaign performance metrics                                     │   │
│   │  • Aggregated analytics data                                        │   │
│   │  • Materialized views for dashboards                                │   │
│   │  Characteristics: Sub-second queries, columnar, compression         │   │
│   └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
│   ┌─────────────────────────────────────────────────────────────────────┐   │
│   │                      ICEBERG (LAKEHOUSE)                            │   │
│   │  • Bronze layer (raw data)                                          │   │
│   │  • Silver layer (cleaned data)                                      │   │
│   │  • Historical data, time travel                                     │   │
│   │  Characteristics: Schema evolution, partitioning, open format       │   │
│   └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
│   ┌─────────────────────────────────────────────────────────────────────┐   │
│   │                         REDIS (CACHE)                               │   │
│   │  • Session tokens                                                   │   │
│   │  • Rate limit counters                                              │   │
│   │  • Query result cache                                               │   │
│   │  Characteristics: Sub-ms latency, TTL support                       │   │
│   └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Storage Tiers

| Tier | Storage | Use Case | Retention | Cost |
| ------ | --------- | ---------- | ----------- | ------ |
| **Hot** | ClickHouse + Redis | Active dashboards, real-time | 90 days | $$$ |
| **Warm** | Iceberg (Standard) | Historical analysis, ad-hoc | 1 year | $$ |
| **Cold** | Iceberg (Archive) | Compliance, audit trail | 7 years | $ |

---

## Data Model Summary

### Transactional Data (PostgreSQL)

| Table | Records (Est.) | Growth Rate |
| ------- | --------------- | ------------- |
| users | 10K | 100/month |
| organizations | 1K | 50/month |
| org_memberships | 20K | 200/month |
| pipelines | 10K | 500/month |
| rules | 50K | 1K/month |
| audit_logs | 10M | 1M/month |

### Analytics Data (ClickHouse)

| Table | Records (Est.) | Growth Rate |
| ------- | --------------- | ------------- |
| campaign_metrics_daily | 100M | 10M/month |
| pacing_snapshots | 50M | 5M/month |
| alert_events | 10M | 500K/month |
| rule_evaluations | 500M | 50M/month |

### Lakehouse Data (Iceberg)

| Layer | Size (Est.) | Growth Rate |
| ------- | ------------- | ------------- |
| Bronze | 5TB | 500GB/month |
| Silver | 2TB | 200GB/month |
| Gold (historical) | 1TB | 100GB/month |

---

## Partitioning Strategy

**All tables partitioned by:**

1. `org_id` - Tenant isolation
2. `date` or `created_at` - Time-based queries

**Why:**

- Query performance (partition pruning)
- Data lifecycle management (retention by date)
- Multi-tenant isolation (never cross org data)

---

## Navigation

- **Previous:** [Service Catalog](../03-services/README.md)
- **Next:** [Module System](../05-modules/README.md)
