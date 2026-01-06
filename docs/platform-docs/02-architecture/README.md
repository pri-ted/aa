# 🏗️ System Architecture

> Complete system design from high-level to component level.

---

## Section Contents

| Document | Description |
| ---------- | ------------- |
| [High-Level Design (HLD)](hld.md) | System overview, layers, components |
| [System Boundaries](system-boundaries.md) | What's in/out of scope |
| [Data Flow](data-flow.md) | How data moves through the system |
| [Technology Stack](tech-stack.md) | Languages, databases, tools |

---

## Architecture at a Glance

```text
┌─────────────────────────────────────────────────────────────────────────────┐
│                           PLATFORM ARCHITECTURE                             │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│   PRESENTATION          API GATEWAY         CONTROL PLANE                   │
│   ┌───────────┐        ┌───────────┐       ┌─────────────────────────┐      │
│   │  Next.js  │───────▶│   Kong    │──────▶│ Auth │ Config │ Modules │      │
│   │  Frontend │        │  Gateway  │       └─────────────────────────┘      │
│   └───────────┘        └───────────┘                   │                    │
│                                                        ▼                    │
│                                              ┌─────────────────────────┐    │
│                                              │    EXECUTION PLANE      │    │
│                                              ├─────────────────────────┤    │
│                                              │ Connectors │ ETL │ Data │    │
│                                              │ Intelligence Layer      │    │
│                                              └─────────────────────────┘    │
│                                                        │                    │
│                                                        ▼                    │
│                                            ┌───────────────────────────┐    │
│                                            │   PERSISTENCE LAYER       │    │
│                                            │ PG │ CH │ Redis │ Iceberg |    │
│                                            └───────────────────────────┘    │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Key Architectural Decisions

| Decision | Choice | Rationale |
| ---------- | -------- | ----------- |
| Service Communication | gRPC + Kafka | Performance + async decoupling |
| API Style | GraphQL (external) | Flexible queries, fewer round trips |
| Database (OLTP) | PostgreSQL | ACID, JSONB, mature ecosystem |
| Database (OLAP) | ClickHouse | Sub-second analytics, cost-effective |
| Data Lake | Apache Iceberg | Schema evolution, open format |
| Orchestration | Kubernetes | Cloud-agnostic, industry standard |
| Workflows | Temporal.io | Durable execution, visibility |

---

## Service Count

| Category | Count | Services |
| ---------- | ------- | ---------- |
| Control Plane | 3 | Auth, Config, Module Registry |
| Connectors | 1 | Connector Orchestrator |
| Data Pipeline | 4 | ETL, Bronze, Silver, Gold |
| Intelligence | 3 | Calculation, Rule Engine, Analytics |
| Interface | 2 | Notification, Query (GraphQL) |
| **Total** | **13** | |

---

## Navigation

- **Previous:** [Overview](../01-overview/README.md)
- **Next:** [Service Catalog](../03-services/README.md)
