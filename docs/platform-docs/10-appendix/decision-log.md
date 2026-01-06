# Decision Log

> Key architectural decisions and rationale.

---

## ADR-001: Go + Rust for Backend Services

**Date:** 2025-12-25  
**Status:** Proposed

### Context

Need to choose programming languages for 12 microservices with varying requirements.

### Decision

- **Go** for I/O-bound services (Auth, Connector, ETL, Analytics, Notification)
- **Rust** for CPU-bound services (Config, Bronze, Silver, Gold, Calculation, Rules)
- **TypeScript** for GraphQL gateway

### Rationale

| Language | Strength | Use Case |
| ---------- | ---------- | ---------- |
| Go | Fast I/O, simple concurrency | API services, orchestration |
| Rust | Memory safety, performance | Data processing |
| TypeScript | Ecosystem, flexibility | GraphQL, frontend |

### Consequences

- Two language ecosystems to maintain
- Need developers proficient in both
- Optimal performance for each workload

---

## ADR-002: ClickHouse for Analytics

**Date:** 2025-12-25  
**Status:** Proposed

### Context

Need OLAP database for sub-second query performance on large datasets.

### Decision

Use ClickHouse for Gold layer analytics.

### Alternatives Considered

| Option | Pros | Cons |
| -------- | ------ | ------ |
| ClickHouse | Fast, columnar, compression | Operational complexity |
| PostgreSQL | Simple, familiar | Too slow at scale |
| BigQuery | Managed, scalable | Vendor lock-in, cost |
| Druid | Real-time | Operational complexity |

### Rationale

- 10-100x faster than PostgreSQL for analytics
- Excellent compression (10:1 typical)
- Good enough for our scale
- Open source, no vendor lock-in

### Consequences

- Additional operational burden
- Need ClickHouse expertise
- Excellent query performance

---

## ADR-003: Temporal for Workflow Orchestration

**Date:** 2025-12-25
**Status:** Proposed

### Context

Need durable workflow orchestration for ETL pipelines.

### Decision

Use Temporal.io for workflow orchestration.

### Alternatives Considered

| Option | Pros | Cons |
| -------- | ------ | ------ |
| Temporal | Durable, versioned, mature | Self-hosted complexity |
| Airflow | Popular, UI | Python-only, DAG limitations |
| Step Functions | Managed | AWS lock-in, cost |
| Prefect | Modern | Less mature |

### Rationale

- Durable execution (survives failures)
- Built-in retry and timeout handling
- Language-native SDKs (Go, Rust)
- Workflow versioning

### Consequences

- Need Temporal cluster management
- Learning curve for developers
- Robust pipeline execution

---

## ADR-004: Apache Iceberg for Data Lakehouse

**Date:** 2025-12-25
**Status:** Proposed

### Context

Need data lake format supporting ACID, time travel, schema evolution.

### Decision

Use Apache Iceberg for Bronze/Silver layers.

### Alternatives Considered

| Option | Pros | Cons |
| -------- | ------ | ------ |
| Iceberg | ACID, time travel, open | Newer |
| Delta Lake | Databricks ecosystem | Spark-centric |
| Hudi | Streaming support | Complex |
| Parquet only | Simple | No ACID |

### Rationale

- True open standard
- Excellent time travel support
- Schema evolution without rewrites
- Works with any query engine

### Consequences

- Need Iceberg-compatible tools
- Catalog management (Glue/Nessie)
- Future-proof data format

---

## ADR-005: GraphQL for API Gateway

**Date:** 2025-12-25
**Status:** Proposed

### Context

Need flexible API for dashboard with real-time subscriptions.

### Decision

Use Apollo Server with GraphQL for the Query Service.

### Alternatives Considered

| Option | Pros | Cons |
| -------- | ------ | ------ |
| GraphQL | Flexible, typed, subscriptions | Complexity, caching |
| REST | Simple, cacheable | Over/under-fetching |
| gRPC | Fast, typed | Browser support |

### Rationale

- Dashboards need flexible queries
- Subscriptions for real-time updates
- Strong typing with schema
- Aggregates multiple backends

### Consequences

- N+1 query challenges
- Need DataLoader pattern
- Excellent developer experience

---

## ADR-006: Kong for API Gateway

**Date:** 2025-12-25
**Status:** Proposed

### Context

Need API gateway for authentication, rate limiting, routing.

### Decision

Use Kong as the API gateway.

### Alternatives Considered

| Option | Pros | Cons |
| -------- | ------ | ------ |
| Kong | Full-featured, plugins | Resource usage |
| Envoy | High performance | Limited plugins |
| NGINX | Simple, fast | Less features |
| AWS API Gateway | Managed | Vendor lock-in |

### Rationale

- Rich plugin ecosystem
- JWT validation built-in
- Rate limiting per tier
- Kubernetes-native (Ingress Controller)

### Consequences

- Additional component to manage
- License considerations for enterprise features
- Flexible request handling

---

## Navigation

- **Up:** [Appendix](README.md)
- **Next:** [Risk Register](risk-register.md)
