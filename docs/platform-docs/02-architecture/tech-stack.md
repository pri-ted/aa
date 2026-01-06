# Technology Stack

> Complete technology choices with rationale.

---

## Stack Overview

| Layer | Technology | Version |
| ------- | ------------ | --------- |
| **Frontend** | Next.js + TypeScript | 16.x + 5.x |
| **API Gateway** | Kong | 3.x |
| **Services (Performance)** | Rust + Actix-web | 4.x |
| **Services (I/O)** | Go + Gin + GORM | 1.10.x + 1.25.x |
| **Services (API)** | TypeScript + Apollo | 4.x |
| **Workflow** | Temporal.io | 1.23.x |
| **Messaging** | Kafka/Redpanda | 3.9.x |
| **OLTP** | PostgreSQL | 18.x |
| **OLAP** | ClickHouse | 25.x |
| **Cache** | Redis | 7.x |
| **Lakehouse** | Apache Iceberg | 1.6.x |
| **Orchestration** | Kubernetes | 1.35.x |

---

## Frontend Stack

### Next.js 16

**Why Next.js:**

- Server-side rendering for initial load performance
- App Router for modern React patterns
- TypeScript-first development
- Built-in optimization (images, fonts, scripts)

**Key Dependencies:**

| Package | Purpose |
| --------- | --------- |
| `@tanstack/react-query` | Server state management |
| `@apollo/client` | GraphQL client |
| `tailwindcss` | Utility-first CSS |
| `monaco-editor` | Formula editor |
| `recharts` | Charts and visualizations |
| `react-hook-form` | Form handling |
| `zod` | Schema validation |

---

## Backend Languages

### Rust Services

**Used For:** Config Service, Bronze/Silver/Gold, Calculation Engine, Rule Engine

**Why Rust:**

| Benefit | Impact |
| --------- | -------- |
| Memory safety | No null pointer bugs, no data races |
| Predictable latency | No GC pauses |
| Performance | Near-C speed |
| Concurrency | Tokio async runtime |
| Type safety | Compile-time guarantees |

**Key Crates:**

| Crate | Purpose |
| ------- | --------- |
| `actix-web` | HTTP framework |
| `tokio` | Async runtime |
| `sqlx` | Database access |
| `datafusion` | SQL query engine |
| `serde` | Serialization |
| `tracing` | Observability |

### Go Services

**Used For:** Auth, Connector, ETL, Analytics, Notification

**Why Go:**

| Benefit | Impact |
| --------- | -------- |
| Fast compilation | Quick iteration |
| Simple concurrency | Goroutines for I/O |
| Strong stdlib | HTTP, crypto, encoding |
| Team expertise | Existing knowledge |
| Deployment | Single binary |

**Key Packages:**

| Package | Purpose |
| --------- | --------- |
| `gin` | HTTP framework |
| `gorm` | ORM |
| `temporal-sdk` | Workflow SDK |
| `go-redis` | Redis client |
| `zap` | Logging |
| `otel` | OpenTelemetry |

### TypeScript Services

**Used For:** GraphQL Gateway

**Why TypeScript:**

| Benefit | Impact |
| --------- | -------- |
| Apollo ecosystem | Best GraphQL support |
| Type safety | Catch errors early |
| Schema sharing | Frontend type generation |
| Developer experience | Familiar to frontend team |

**Key Packages:**

| Package | Purpose |
| --------- | --------- |
| `@apollo/server` | GraphQL server |
| `graphql-codegen` | Type generation |
| `dataloader` | N+1 prevention |
| `ioredis` | Redis client |

---

## Databases

### PostgreSQL 18

**Role:** Primary OLTP database

**Why PostgreSQL:**

| Feature | Use Case |
| --------- | ---------- |
| ACID compliance | Configuration consistency |
| JSONB | Flexible schema storage |
| Row-level security | Multi-tenant isolation |
| Mature ecosystem | Tools, extensions, expertise |

**Configuration:**

```yaml
# Key settings
max_connections: 200
shared_buffers: 4GB
effective_cache_size: 12GB
work_mem: 64MB
maintenance_work_mem: 512MB
wal_level: replica
```

**Extensions:**

- `pg_stat_statements` - Query analysis
- `pgcrypto` - Encryption
- `pg_trgm` - Text search
- `timescaledb` - Time-series (optional)

---

### ClickHouse 25

**Role:** OLAP analytics database

**Why ClickHouse:**

| Feature | Benefit |
| --------- | --------- |
| Columnar storage | Fast aggregations |
| Compression | 10x storage reduction |
| Sub-second queries | Interactive dashboards |
| Cost-effective | 4x cheaper than BigQuery |

**Configuration:**

```xml
<!-- Key settings -->
<max_memory_usage>10000000000</max_memory_usage>
<max_threads>16</max_threads>
<max_concurrent_queries>100</max_concurrent_queries>
```

**Table Engines:**

| Engine | Use Case |
| -------- | ---------- |
| `MergeTree` | Primary tables |
| `ReplicatedMergeTree` | HA tables |
| `MaterializedView` | Pre-aggregated data |
| `Distributed` | Cross-shard queries |

---

### Redis 7

**Role:** Cache, sessions, rate limiting

**Why Redis:**

| Feature | Use Case |
| --------- | ---------- |
| Sub-ms latency | Hot path caching |
| Data structures | Rate limit counters |
| Pub/Sub | Real-time updates |
| Cluster mode | Horizontal scaling |

**Data Structures Used:**

| Type | Use Case |
| ------ | ---------- |
| `STRING` | Session tokens |
| `HASH` | User preferences cache |
| `SORTED SET` | Rate limit windows |
| `STREAM` | Real-time events |

---

### Apache Iceberg

**Role:** Data lakehouse tables

**Why Iceberg:**

| Feature | Benefit |
| --------- | --------- |
| Schema evolution | Add columns without rewrite |
| Time travel | Query historical data |
| Partition evolution | Change partitioning live |
| Open format | No vendor lock-in |

**Table Properties:**

```sql
TBLPROPERTIES (
    'write.format.default' = 'parquet',
    'write.parquet.compression-codec' = 'zstd',
    'write.target-file-size-bytes' = '134217728',
    'commit.retry.num-retries' = '3'
)
```

---

## Messaging

### Kafka/Redpanda

**Role:** Event streaming

**Why Kafka:**

| Feature | Benefit |
| --------- | --------- |
| Durability | No data loss |
| Ordering | Per-partition guarantees |
| Scalability | Linear scaling |
| Ecosystem | Connectors, tools |

**Why Redpanda (alternative):**

- Compatible with Kafka protocol
- Simpler operations (no ZooKeeper)
- Better resource efficiency

**Topic Configuration:**

| Topic | Partitions | Retention | Replication |
| ------- | ------------ | ----------- | ------------- |
| `connector.data.raw` | 12 | 7 days | 3 |
| `bronze.data.cleaned` | 12 | 7 days | 3 |
| `silver.data.processed` | 12 | 7 days | 3 |
| `gold.data.ready` | 12 | 7 days | 3 |
| `rules.alerts` | 6 | 30 days | 3 |
| `audit.events` | 6 | 90 days | 3 |

---

## Workflow Orchestration

### Temporal.io

**Role:** Durable workflow execution

**Why Temporal:**

| Feature | Benefit |
| --------- | --------- |
| Durable execution | Survives crashes |
| Visibility | See workflow state |
| Retries | Built-in error handling |
| Compensation | Saga pattern support |

**Workflow Types:**

| Workflow | Purpose |
| ---------- | --------- |
| `DataIngestionWorkflow` | DSP data fetch |
| `ETLWorkflow` | Bronze → Silver → Gold |
| `OnboardingWorkflow` | New org setup |
| `WriteBackWorkflow` | DSP modifications |

---

## Infrastructure

### Kubernetes

**Role:** Container orchestration

**Why Kubernetes:**

| Feature | Benefit |
| --------- | --------- |
| Cloud-agnostic | AWS, GCP, Azure |
| Declarative | GitOps friendly |
| Self-healing | Auto-restart |
| Scaling | HPA, VPA |

**Key Components:**

| Component | Purpose |
| ----------- | --------- |
| ArgoCD | GitOps deployments |
| Cert-Manager | TLS certificates |
| External Secrets | Secret management |
| Ingress NGINX | Load balancing |
| Prometheus | Metrics |
| Loki | Logs |
| Tempo | Traces |

---

## Decision Matrix

| Decision | Options Considered | Choice | Rationale |
| ---------- | ------------------- | -------- | ----------- |
| Primary language | Rust, Go, Java | Go + Rust | Go for I/O, Rust for compute |
| OLAP database | BigQuery, Snowflake, ClickHouse | ClickHouse | 4x cost savings, self-hosted |
| Data lake | Delta, Hudi, Iceberg | Iceberg | Open format, schema evolution |
| Workflow | Airflow, Temporal, Step Functions | Temporal | Durable execution, visibility |
| API style | REST, GraphQL, gRPC | GraphQL + gRPC | GraphQL external, gRPC internal |
| Message queue | Kafka, RabbitMQ, SQS | Kafka | Durability, ordering, ecosystem |

---

## Navigation

- **Previous:** [Data Flow](data-flow.md)
- **Up:** [Architecture](README.md)
