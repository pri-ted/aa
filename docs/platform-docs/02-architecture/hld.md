# High-Level Design (HLD)

> System architecture overview and component relationships.

---

## System Layers

The platform is organized into five conceptual layers:

### Layer 1: Presentation Layer

**Purpose:** User interface and API access

**Components:**

- Next.js 16 Frontend (SSR, TypeScript)
- Configuration Wizards
- Visual Rule Builder
- Real-time Dashboards
- Monaco Editor (formula editing)

**Responsibilities:**

- Render UI components
- Handle user interactions
- Manage client-side state
- Communicate with API Gateway

---

### Layer 2: API Gateway Layer

**Purpose:** Entry point for all API traffic

**Components:**

- Kong/Envoy Gateway
- GraphQL Federation

**Responsibilities:**

- Authentication (JWT validation)
- Rate limiting (per user, per org)
- Request routing
- API versioning
- Request/response transformation

**Configuration:**

```yaml
# Kong rate limiting
plugins:
  - name: rate-limiting
    config:
      minute: 100        # Free tier
      minute: 1000       # Premium tier
      policy: redis
      redis_host: redis-cluster
```

---

### Layer 3: Control Plane

**Purpose:** Manage configuration, users, and permissions

**Services:**

| Service | Language | Database | Port |
| --------- | ---------- | ---------- | ------ |
| Auth Service | Go | PostgreSQL + Redis | 8001 |
| Config Service | Rust | PostgreSQL | 8002 |
| Module Registry | Rust | PostgreSQL | 8003 |
| Cost Tracker | Go | PostgreSQL + ClickHouse | 8004 |

**Characteristics:**

- Highly available (3+ replicas)
- Low latency (< 200ms)
- Authoritative state
- Horizontal scaling

---

### Layer 4: Execution Plane

**Purpose:** Process data and execute business logic

**Sub-layers:**

#### 4.1 Connector Layer

| Service | Language | Purpose |
| --------- | ---------- | --------- |
| Connector Orchestrator | Go | DSP/CRM adapters, OAuth, rate limiting |

#### 4.2 Data Layer

| Service | Language | Storage | Purpose |
| --------- | ---------- | --------- | --------- |
| ETL Orchestrator | Go | - | Temporal workflows |
| Bronze Service | Rust | Iceberg | Raw data ingestion |
| Silver Service | Rust | Iceberg | Data cleaning |
| Gold Service | Rust | ClickHouse | Aggregations |

#### 4.3 Intelligence Layer

| Service | Language | Purpose |
| --------- | ---------- | --------- |
| Calculation Engine | Rust | Formula evaluation |
| Rule Engine | Rust | Condition evaluation, actions |
| Analytics Service | Go | Health, costs, recommendations |
| Notification Service | Go | Email, Slack, in-app |

---

### Layer 5: Persistence Layer

**Purpose:** Durable data storage

**Components:**

| Store | Technology | Use Case |
| ------- | ------------ | ---------- |
| PostgreSQL 16 | OLTP | Users, configs, metadata |
| ClickHouse 24 | OLAP | Analytics, dashboards |
| Redis 7 | Cache | Sessions, rate limits |
| Iceberg on S3 | Lakehouse | Bronze/Silver data |
| Kafka/Redpanda | Messaging | Event streaming |

---

## Component Diagram

```text
┌──────────────────────────────────────────────────────────────────────────────┐
│                              PRESENTATION LAYER                              │
│  ┌─────────────────────────────────────────────────────────────────────────┐ │
│  │  Next.js Frontend                                                       │ │
│  │  • Configuration Wizards  • Visual Rule Builder  • Real-time Dashboards │ │
│  └─────────────────────────────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────────────────────────┘
                                       │
                                       ▼
┌──────────────────────────────────────────────────────────────────────────────┐
│                              API GATEWAY LAYER                               │
│  ┌─────────────────────────────────────────────────────────────────────────┐ │
│  │  Kong/Envoy Gateway                                                     │ │
│  │  • Authentication  • Rate Limiting  • Request Routing  • API Versioning │ │
│  └─────────────────────────────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────────────────────────┘
                                       │
                                       ▼
┌──────────────────────────────────────────────────────────────────────────────┐
│                               CONTROL PLANE                                  │
│  ┌────────────┐ ┌────────────┐ ┌────────────┐ ┌────────────┐                 │
│  │    Auth    │ │   Config   │ │   Module   │ │    Cost    │                 │
│  │  Service   │ │  Service   │ │  Registry  │ │  Tracker   │                 │
│  │    (Go)    │ │   (Rust)   │ │   (Rust)   │ │    (Go)    │                 │
│  └────────────┘ └────────────┘ └────────────┘ └────────────┘                 │
└──────────────────────────────────────────────────────────────────────────────┘
                                       │
                                       ▼
┌──────────────────────────────────────────────────────────────────────────────┐
│                              EXECUTION PLANE                                 │
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────────┐ │
│  │                      CONNECTOR LAYER                                    │ │
│  │  ┌───────────┐ ┌───────────┐ ┌───────────┐ ┌───────────┐                │ │
│  │  │   DV360   │ │    TTD    │ │   Meta    │ │    CRM    │                │ │
│  │  │  Adapter  │ │  Adapter  │ │  Adapter  │ │  Adapter  │                │ │
│  │  └───────────┘ └───────────┘ └───────────┘ └───────────┘                │ │
│  └─────────────────────────────────────────────────────────────────────────┘ │
│                                       │                                      │
│                                       ▼                                      │
│  ┌─────────────────────────────────────────────────────────────────────────┐ │
│  │                           DATA LAYER                                    │ │
│  │  ┌────────────┐    ┌────────────┐    ┌────────────┐                     │ │
│  │  │   Bronze   │───▶│   Silver   │───▶│    Gold    │                     │ │
│  │  │   (Raw)    │    │  (Cleaned) │    │ (Business) │                     │ │
│  │  │  Iceberg   │    │  Iceberg   │    │ ClickHouse │                     │ │
│  │  └────────────┘    └────────────┘    └────────────┘                     │ │
│  └─────────────────────────────────────────────────────────────────────────┘ │
│                                       │                                      │
│                                       ▼                                      │
│  ┌─────────────────────────────────────────────────────────────────────────┐ │
│  │                      INTELLIGENCE LAYER                                 │ │
│  │  ┌────────────┐ ┌────────────┐ ┌────────────┐ ┌────────────┐            │ │
│  │  │ Calculation│ │    Rule    │ │  Analytics │ │Notification│            │ │
│  │  │   Engine   │ │   Engine   │ │  Service   │ │  Service   │            │ │
│  │  └────────────┘ └────────────┘ └────────────┘ └────────────┘            │ │
│  └─────────────────────────────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────────────────────────┘
                                       │
                                       ▼
┌──────────────────────────────────────────────────────────────────────────────┐
│                            PERSISTENCE LAYER                                 │
│  ┌────────────┐ ┌────────────┐ ┌────────────┐ ┌────────────┐ ┌────────────┐  │
│  │ PostgreSQL │ │ ClickHouse │ │   Redis    │ │  Iceberg   │ │   Kafka    │  │
│  │   (OLTP)   │ │   (OLAP)   │ │  (Cache)   │ │ (Lakehouse)│ │ (Events)   │  │
│  └────────────┘ └────────────┘ └────────────┘ └────────────┘ └────────────┘  │
└──────────────────────────────────────────────────────────────────────────────┘
```

---

## Service Communication

### Synchronous (Request/Response)

| From | To | Protocol | Use Case |
| ------ | ---- | --------- | --------- |
| Frontend | Gateway | HTTPS | All user requests |
| Gateway | Services | gRPC | Internal calls |
| Service | Service | gRPC | Sync operations |

### Asynchronous (Event-Driven)

| From | To | Via | Use Case |
| ------ | ---- | ---- | ---------- |
| Connector | Bronze | Kafka | Data ingestion |
| Bronze | Silver | Kafka | Data processing |
| Rule Engine | Notification | Kafka | Alert delivery |
| Any | Analytics | Kafka | Metrics collection |

---

## Kafka Topics

| Topic | Producers | Consumers | Partitions |
| ------- | ----------- | ----------- | ------------ |
| `connector.data.raw` | Connector | Bronze | 12 |
| `bronze.data.cleaned` | Bronze | Silver | 12 |
| `silver.data.processed` | Silver | Gold | 12 |
| `gold.data.ready` | Gold | Analytics, Rule Engine | 12 |
| `rules.alerts` | Rule Engine | Notification | 6 |
| `audit.events` | All Services | Audit Service | 6 |
| `metrics.collected` | All Services | Analytics | 3 |

**Partitioning Strategy:** All data topics partitioned by `org_id` to ensure ordering within org.

---

## Scaling Strategy

| Component | Scaling Type | Trigger |
| ----------- | ------------- | --------- |
| Frontend | Horizontal | Request count |
| API Gateway | Horizontal | Request count |
| Control Plane Services | Horizontal | CPU/Memory |
| Connector Workers | Pool-based | Queue depth |
| Data Layer Workers | Pool-based | Partition lag |
| PostgreSQL | Vertical + Read replicas | Query load |
| ClickHouse | Horizontal (shards) | Data volume |
| Redis | Cluster (slots) | Key count |

---

## Navigation

- **Previous:** [Architecture Overview](README.md)
- **Next:** [System Boundaries](system-boundaries.md)
  