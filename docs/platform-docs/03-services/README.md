# ⚙️ Service Catalog

> Detailed specifications for all 12 microservices.

---

## Service Overview

| Service | Language | Database | Owner |
| --------- | ---------- | ---------- | ------- |
| [Auth Service](auth/README.md) | Go | PostgreSQL + Redis | Platform |
| [Config Service](config/README.md) | Rust | PostgreSQL | Platform |
| [Connector Service](connector/README.md) | Go | PostgreSQL + Kafka | Data |
| [ETL Orchestrator](etl/README.md) | Go | Temporal | Data |
| [Bronze Service](bronze/README.md) | Rust | Iceberg | Data |
| [Silver Service](silver/README.md) | Rust | Iceberg | Data |
| [Gold Service](gold/README.md) | Rust | ClickHouse | Data |
| [Calculation Engine](calculation/README.md) | Rust | Redis | Platform |
| [Rule Engine](rule-engine/README.md) | Rust | PostgreSQL | Platform |
| [Analytics Service](analytics/README.md) | Go | ClickHouse | Platform |
| [Notification Service](notification/README.md) | Go | PostgreSQL | Platform |
| [Query Service](query/README.md) | TypeScript | Redis | Platform |

---

## Service Architecture

```text
┌─────────────────────────────────────────────────────────────────────────────┐
│                           SERVICE ARCHITECTURE                              │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  CONTROL PLANE (User-facing, low latency)                                   │
│  ┌────────────┐ ┌────────────┐ ┌────────────┐                               │
│  │    Auth    │ │   Config   │ │   Query    │                               │
│  │    (Go)    │ │   (Rust)   │ │    (TS)    │                               │
│  │   :8001    │ │   :8002    │ │   :8010    │                               │
│  └────────────┘ └────────────┘ └────────────┘                               │
│                                                                             │
│  DATA PLANE (Background, throughput-focused)                                │
│  ┌────────────┐ ┌────────────┐ ┌────────────┐ ┌────────────┐                │
│  │ Connector  │ │    ETL     │ │   Bronze   │ │   Silver   │                │
│  │    (Go)    │ │    (Go)    │ │   (Rust)   │ │   (Rust)   │                │
│  │   :8003    │ │   :8004    │ │   :8005    │ │   :8006    │                │
│  └────────────┘ └────────────┘ └────────────┘ └────────────┘                │
│  ┌────────────┐                                                             │
│  │    Gold    │                                                             │
│  │   (Rust)   │                                                             │
│  │   :8007    │                                                             │
│  └────────────┘                                                             │
│                                                                             │
│  INTELLIGENCE PLANE (Business logic)                                        │
│  ┌────────────┐ ┌────────────┐ ┌────────────┐ ┌────────────┐                │
│  │Calculation │ │    Rule    │ │ Analytics  │ │   Notif    │                │
│  │   (Rust)   │ │   (Rust)   │ │    (Go)    │ │    (Go)    │                │
│  │   :8008    │ │   :8009    │ │   :8011    │ │   :8012    │                │
│  └────────────┘ └────────────┘ └────────────┘ └────────────┘                │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Service Communication Matrix

| From / To | Auth | Config | Connector | ETL | Bronze | Silver | Gold | Calc | Rule | Analytics | Notif | Query |
| ----------- | ------ | -------- | ----------- | ----- | -------- | -------- | ------ | ------ | ------ | ----------- | ------- | ------- |
| **Auth** | - | ○ | ○ | ○ | ○ | ○ | ○ | ○ | ○ | ○ | ○ | ○ |
| **Config** | ● | - | ○ | ○ | ○ | ○ | ○ | ○ | ● | ○ | ○ | ○ |
| **Connector** | ● | ● | - | ● | ○ | ○ | ○ | ○ | ○ | ○ | ○ | ○ |
| **ETL** | ● | ● | ● | - | ● | ● | ● | ○ | ○ | ○ | ○ | ○ |
| **Bronze** | ○ | ● | ○ | ○ | - | ○ | ○ | ○ | ○ | ○ | ○ | ○ |
| **Silver** | ○ | ● | ○ | ○ | ● | - | ○ | ○ | ○ | ○ | ○ | ○ |
| **Gold** | ○ | ● | ○ | ○ | ○ | ● | - | ● | ○ | ○ | ○ | ○ |
| **Calc** | ○ | ● | ○ | ○ | ○ | ○ | ● | - | ○ | ○ | ○ | ○ |
| **Rule** | ● | ● | ○ | ○ | ○ | ○ | ● | ● | - | ○ | ● | ○ |
| **Analytics** | ● | ○ | ○ | ○ | ○ | ○ | ● | ○ | ○ | - | ○ | ○ |
| **Notif** | ● | ● | ○ | ○ | ○ | ○ | ○ | ○ | ○ | ○ | - | ○ |
| **Query** | ● | ● | ○ | ○ | ○ | ○ | ● | ● | ● | ● | ○ | - |

● = Calls directly  ○ = No direct communication

---

## Resource Requirements (Per Service)

| Service | Replicas | CPU | Memory | Storage |
| --------- | ---------- | ----- | -------- | --------- |
| Auth | 3 | 500m | 512Mi | - |
| Config | 3 | 1000m | 1Gi | - |
| Connector | 5 | 2000m | 2Gi | - |
| ETL | 3 | 1000m | 1Gi | - |
| Bronze | 5 | 2000m | 4Gi | - |
| Silver | 5 | 2000m | 4Gi | - |
| Gold | 5 | 2000m | 4Gi | - |
| Calculation | 3 | 2000m | 2Gi | - |
| Rule Engine | 3 | 2000m | 2Gi | - |
| Analytics | 3 | 1000m | 1Gi | - |
| Notification | 2 | 500m | 512Mi | - |
| Query | 5 | 1000m | 1Gi | - |

---

## Health Check Endpoints

All services expose:

- `GET /health` - Basic health check
- `GET /ready` - Readiness probe
- `GET /metrics` - Prometheus metrics

---

## Navigation

- **Previous:** [Architecture](../02-architecture/README.md)
- **Next:** [Data Architecture](../04-data/README.md)
