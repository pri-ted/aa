# Kafka Event Schemas

> Event schemas for asynchronous messaging between services.

---

## Overview

All platform services communicate asynchronously via Apache Kafka. This directory contains the canonical Avro schema definitions for all events, ensuring type-safe, evolvable contracts.

---

## Directory Structure

```text
events/
├── README.md                    # This file
├── schemas/
│   ├── common/
│   │   ├── metadata.avsc        # Common event metadata
│   │   └── entity.avsc          # Entity reference types
│   ├── connector/
│   │   └── data-raw.avsc        # Raw data from DSP connectors
│   ├── bronze/
│   │   └── data-cleaned.avsc    # Cleaned data events
│   ├── silver/
│   │   └── data-processed.avsc  # Processed data events
│   ├── gold/
│   │   └── data-ready.avsc      # Analytics-ready data events
│   ├── rules/
│   │   └── alerts.avsc          # Alert events
│   ├── config/
│   │   └── changes.avsc         # Configuration change events
│   ├── etl/
│   │   └── execution.avsc       # ETL execution events
│   └── audit/
│       └── events.avsc          # Audit trail events
└── topic-config.yaml            # Kafka topic configuration
```

---

## Topic Naming Convention

```text
{domain}.{entity}.{action}

Examples:
- connector.data.raw
- bronze.data.cleaned
- silver.data.processed
- gold.data.ready
- rules.alerts.triggered
- config.pipeline.updated
- audit.events.logged
```

---

## Topic Configuration

| Topic | Partitions | Replication | Retention | Key |
| ------- | ------------ | ------------- | ----------- | ----- |
| `connector.data.raw` | 12 | 3 | 7 days | org_id |
| `bronze.data.cleaned` | 12 | 3 | 7 days | org_id |
| `silver.data.processed` | 12 | 3 | 7 days | org_id |
| `gold.data.ready` | 12 | 3 | 7 days | org_id |
| `rules.alerts.triggered` | 6 | 3 | 30 days | org_id |
| `config.changes` | 6 | 3 | 30 days | org_id |
| `etl.execution` | 6 | 3 | 7 days | pipeline_id |
| `audit.events` | 6 | 3 | 90 days | org_id |

---

## Schema Registry

We use Confluent Schema Registry for schema management:

```yaml
schema_registry:
  url: http://schema-registry:8081
  compatibility: BACKWARD
  auto_register: true
```

### Compatibility Rules

- **BACKWARD** (default): New schema can read old data
- All field additions must have defaults
- Fields can only be deleted if they had defaults
- Field types cannot change

---

## Event Envelope

All events follow a standard envelope:

```json
{
  "event_id": "uuid",
  "event_type": "connector.data.raw",
  "event_version": "1.0.0",
  "timestamp": "2024-12-26T10:00:00Z",
  "source": {
    "service": "connector-service",
    "instance": "connector-service-abc123"
  },
  "correlation_id": "uuid",
  "org_id": 456,
  "payload": { ... }
}
```

---

## Consumer Groups

| Group | Topics | Purpose |
| ------- | -------- | --------- |
| `bronze-processor` | `connector.data.raw` | Process raw data |
| `silver-processor` | `bronze.data.cleaned` | Clean and validate |
| `gold-processor` | `silver.data.processed` | Aggregate and enrich |
| `rule-evaluator` | `gold.data.ready` | Evaluate rules |
| `notification-sender` | `rules.alerts.triggered` | Send notifications |
| `audit-writer` | `audit.events` | Write to audit store |

---

## Dead Letter Queues

Failed messages are routed to DLQ topics:

```code
{original_topic}.dlq

Examples:
- connector.data.raw.dlq
- bronze.data.cleaned.dlq
```

DLQ retention: 14 days

---

## Partitioning Strategy

All topics are partitioned by `org_id` to ensure:

1. **Ordering**: Events for the same org are processed in order
2. **Locality**: Related events go to the same partition
3. **Isolation**: One org's backlog doesn't affect others

```java
// Partition key computation
int partition = Math.abs(orgId.hashCode()) % numPartitions;
```

---

## Event Processing Guarantees

| Guarantee | Configuration |
| ----------- | --------------- |
| Delivery | At-least-once |
| Ordering | Per-partition (per-org) |
| Idempotency | Via event_id deduplication |
| Transactions | Single-partition only |

---

## Monitoring

Key metrics to monitor:

- `kafka_consumer_lag`: Consumer lag per group
- `kafka_messages_in_per_sec`: Message throughput
- `kafka_bytes_in_per_sec`: Bytes throughput
- `schema_registry_schemas_total`: Schema count

---

## Navigation

- **Up:** [Data Architecture](../README.md)
- **Next:** [Common Schemas](schemas/common/metadata.avsc)
