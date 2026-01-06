# Service Environment Variables

> Complete environment variable specifications for all platform services.

---

## Common Environment Variables

These variables are used by all services:

```yaml
# Logging
LOG_LEVEL:
  description: "Logging level"
  type: string
  default: "info"
  values: ["debug", "info", "warn", "error"]

LOG_FORMAT:
  description: "Log output format"
  type: string
  default: "json"
  values: ["json", "console", "text"]

# Tracing
OTEL_EXPORTER_OTLP_ENDPOINT:
  description: "OpenTelemetry collector endpoint"
  type: string
  example: "http://otel-collector:4317"

OTEL_SERVICE_NAME:
  description: "Service name for tracing"
  type: string

# Metrics
METRICS_ENABLED:
  description: "Enable Prometheus metrics"
  type: boolean
  default: true
```

---

## Auth Service

**Ports:** 8001 (HTTP), 9001 (gRPC)

```yaml
required:
  DATABASE_URL:
    description: "PostgreSQL connection string"
    example: "postgres://user:pass@host:5432/auth?sslmode=require"
    secret: true

  REDIS_URL:
    description: "Redis connection string for sessions"
    example: "redis://:password@redis:6379"
    secret: true

  JWT_SECRET:
    description: "Secret for signing JWT tokens (min 32 chars)"
    secret: true
    validation: "min_length: 32"

  KAFKA_BROKERS:
    description: "Comma-separated Kafka broker list"
    example: "kafka-0:9092,kafka-1:9092"

optional:
  HTTP_PORT:
    description: "HTTP server port"
    default: "8001"

  GRPC_PORT:
    description: "gRPC server port"
    default: "9001"

  JWT_ACCESS_TOKEN_TTL:
    description: "Access token TTL in seconds"
    default: "3600"

  JWT_REFRESH_TOKEN_TTL:
    description: "Refresh token TTL in seconds"
    default: "604800"

  BCRYPT_COST:
    description: "bcrypt cost factor for password hashing"
    default: "12"

  SESSION_MAX_AGE:
    description: "Maximum session age in seconds"
    default: "86400"

  RATE_LIMIT_LOGIN:
    description: "Max login attempts per minute per IP"
    default: "10"

  CORS_ORIGINS:
    description: "Comma-separated allowed CORS origins"
    default: "*"
```

---

## Config Service

**Ports:** 8002 (HTTP), 9002 (gRPC)

```yaml
required:
  DATABASE_URL:
    description: "PostgreSQL connection string"
    example: "postgres://user:pass@host:5432/config?sslmode=require"
    secret: true

  KAFKA_BROKERS:
    description: "Comma-separated Kafka broker list"
    example: "kafka-0:9092,kafka-1:9092"

  AUTH_SERVICE_URL:
    description: "Auth service gRPC address"
    example: "auth-service:9001"

optional:
  HTTP_PORT:
    description: "HTTP server port"
    default: "8002"

  GRPC_PORT:
    description: "gRPC server port"
    default: "9002"

  CACHE_TTL_SECONDS:
    description: "Default cache TTL for configurations"
    default: "300"

  SMART_DEFAULTS_ENABLED:
    description: "Enable AI-powered smart defaults"
    default: "true"

  VALIDATION_STRICT_MODE:
    description: "Fail on validation warnings"
    default: "false"
```

---

## Connector Service

**Ports:** 8003 (HTTP), 9003 (gRPC)

```yaml
required:
  DATABASE_URL:
    description: "PostgreSQL connection string"
    secret: true

  REDIS_URL:
    description: "Redis for rate limiting and caching"
    secret: true

  KAFKA_BROKERS:
    description: "Comma-separated Kafka broker list"

  AUTH_SERVICE_URL:
    description: "Auth service gRPC address"

  CONFIG_SERVICE_URL:
    description: "Config service gRPC address"

  S3_ENDPOINT:
    description: "S3-compatible storage endpoint"
    example: "https://s3.amazonaws.com"

  S3_BUCKET:
    description: "S3 bucket for raw data storage"
    example: "platform-bronze"

  S3_ACCESS_KEY:
    description: "S3 access key"
    secret: true

  S3_SECRET_KEY:
    description: "S3 secret key"
    secret: true

  ENCRYPTION_KEY:
    description: "Key for encrypting OAuth tokens at rest"
    secret: true

optional:
  HTTP_PORT:
    default: "8003"

  GRPC_PORT:
    default: "9003"

  # DV360 Configuration
  DV360_CLIENT_ID:
    description: "Google OAuth client ID for DV360"
    secret: true

  DV360_CLIENT_SECRET:
    description: "Google OAuth client secret for DV360"
    secret: true

  DV360_RATE_LIMIT:
    description: "Requests per minute for DV360"
    default: "50"

  # TTD Configuration
  TTD_API_BASE_URL:
    description: "The Trade Desk API base URL"
    default: "https://api.thetradedesk.com/v3"

  TTD_RATE_LIMIT:
    description: "Requests per minute for TTD"
    default: "100"

  # Meta Configuration
  META_APP_ID:
    description: "Meta/Facebook App ID"
    secret: true

  META_APP_SECRET:
    description: "Meta/Facebook App Secret"
    secret: true

  META_RATE_LIMIT:
    description: "Requests per hour for Meta"
    default: "200"

  # Circuit Breaker
  CIRCUIT_BREAKER_THRESHOLD:
    description: "Failures before circuit opens"
    default: "5"

  CIRCUIT_BREAKER_TIMEOUT:
    description: "Seconds before attempting recovery"
    default: "60"

  # Request Queue
  QUEUE_MAX_SIZE:
    description: "Maximum pending requests per DSP"
    default: "1000"

  QUEUE_BATCH_SIZE:
    description: "Requests to batch together"
    default: "10"
```

---

## ETL Service

**Ports:** 8004 (HTTP), 9004 (gRPC)

```yaml
required:
  TEMPORAL_ADDRESS:
    description: "Temporal server address"
    example: "temporal:7233"

  TEMPORAL_NAMESPACE:
    description: "Temporal namespace"
    default: "platform-etl"

  KAFKA_BROKERS:
    description: "Comma-separated Kafka broker list"

  AUTH_SERVICE_URL:
    description: "Auth service gRPC address"

  CONFIG_SERVICE_URL:
    description: "Config service gRPC address"

  CONNECTOR_SERVICE_URL:
    description: "Connector service gRPC address"

optional:
  HTTP_PORT:
    default: "8004"

  GRPC_PORT:
    default: "9004"

  TEMPORAL_WORKER_COUNT:
    description: "Number of Temporal workers"
    default: "4"

  TEMPORAL_MAX_CONCURRENT_ACTIVITIES:
    description: "Max concurrent activity executions"
    default: "10"

  WORKFLOW_TIMEOUT_HOURS:
    description: "Max workflow execution time"
    default: "24"

  RETRY_MAX_ATTEMPTS:
    description: "Max retry attempts for failed activities"
    default: "3"

  RETRY_INITIAL_INTERVAL:
    description: "Initial retry interval in seconds"
    default: "10"
```

---

## Bronze Service

**Ports:** 8005 (HTTP), 9005 (gRPC)

```yaml
required:
  KAFKA_BROKERS:
    description: "Comma-separated Kafka broker list"

  S3_ENDPOINT:
    description: "S3-compatible storage endpoint"

  S3_BUCKET:
    description: "S3 bucket for Bronze layer"
    example: "platform-bronze"

  S3_ACCESS_KEY:
    secret: true

  S3_SECRET_KEY:
    secret: true

  ICEBERG_CATALOG_URI:
    description: "Iceberg catalog URI"
    example: "thrift://hive-metastore:9083"

optional:
  HTTP_PORT:
    default: "8005"

  GRPC_PORT:
    default: "9005"

  KAFKA_CONSUMER_GROUP:
    default: "bronze-processor"

  BATCH_SIZE:
    description: "Records to batch before write"
    default: "1000"

  FLUSH_INTERVAL_MS:
    description: "Max time before flushing batch"
    default: "5000"

  DEDUP_WINDOW_HOURS:
    description: "Deduplication window"
    default: "24"
```

---

## Silver Service

**Ports:** 8006 (HTTP), 9006 (gRPC)

```yaml
required:
  KAFKA_BROKERS:
    description: "Comma-separated Kafka broker list"

  S3_ENDPOINT:
    description: "S3-compatible storage endpoint"

  S3_BUCKET:
    description: "S3 bucket for Silver layer"
    example: "platform-silver"

  S3_ACCESS_KEY:
    secret: true

  S3_SECRET_KEY:
    secret: true

  ICEBERG_CATALOG_URI:
    description: "Iceberg catalog URI"

optional:
  HTTP_PORT:
    default: "8006"

  GRPC_PORT:
    default: "9006"

  KAFKA_CONSUMER_GROUP:
    default: "silver-processor"

  QUALITY_THRESHOLD:
    description: "Minimum quality score (0-100)"
    default: "70"

  QUARANTINE_ENABLED:
    description: "Send low-quality records to quarantine"
    default: "true"
```

---

## Gold Service

**Ports:** 8007 (HTTP), 9007 (gRPC)

```yaml
required:
  KAFKA_BROKERS:
    description: "Comma-separated Kafka broker list"

  CLICKHOUSE_URL:
    description: "ClickHouse HTTP endpoint"
    example: "http://clickhouse:8123"

  CLICKHOUSE_DATABASE:
    description: "ClickHouse database name"
    default: "gold"

  CLICKHOUSE_USER:
    secret: true

  CLICKHOUSE_PASSWORD:
    secret: true

  S3_ENDPOINT:
    description: "S3 for reading Silver data"

  S3_ACCESS_KEY:
    secret: true

  S3_SECRET_KEY:
    secret: true

  ICEBERG_CATALOG_URI:
    description: "Iceberg catalog for Silver tables"

optional:
  HTTP_PORT:
    default: "8007"

  GRPC_PORT:
    default: "9007"

  KAFKA_CONSUMER_GROUP:
    default: "gold-processor"

  AGGREGATION_PARALLELISM:
    description: "Parallel aggregation workers"
    default: "4"

  MATERIALIZED_VIEW_REFRESH:
    description: "Auto-refresh materialized views"
    default: "true"
```

---

## Calculation Engine

**Ports:** 8008 (HTTP), 9008 (gRPC)

```yaml
required:
  REDIS_URL:
    description: "Redis for formula caching"
    secret: true

optional:
  HTTP_PORT:
    default: "8008"

  GRPC_PORT:
    default: "9008"

  CACHE_TTL_SECONDS:
    description: "Compiled formula cache TTL"
    default: "86400"

  JIT_ENABLED:
    description: "Enable JIT compilation"
    default: "true"

  MAX_FORMULA_LENGTH:
    description: "Maximum formula character length"
    default: "10000"

  EXECUTION_TIMEOUT_MS:
    description: "Max formula execution time"
    default: "5000"
```

---

## Rule Engine

**Ports:** 8009 (HTTP), 9009 (gRPC)

```yaml
required:
  DATABASE_URL:
    description: "PostgreSQL for rule storage"
    secret: true

  KAFKA_BROKERS:
    description: "Comma-separated Kafka broker list"

  AUTH_SERVICE_URL:
    description: "Auth service gRPC address"

  CONFIG_SERVICE_URL:
    description: "Config service gRPC address"

  CALCULATION_SERVICE_URL:
    description: "Calculation engine gRPC address"

  NOTIFICATION_SERVICE_URL:
    description: "Notification service gRPC address"

optional:
  HTTP_PORT:
    default: "8009"

  GRPC_PORT:
    default: "9009"

  KAFKA_CONSUMER_GROUP:
    default: "rule-evaluator"

  EVALUATION_PARALLELISM:
    description: "Parallel rule evaluations"
    default: "10"

  ALERT_COOLDOWN_MINUTES:
    description: "Minimum time between repeat alerts"
    default: "60"
```

---

## Query Service (GraphQL)

**Ports:** 8010 (HTTP)

```yaml
required:
  REDIS_URL:
    description: "Redis for query caching"
    secret: true

  CLICKHOUSE_URL:
    description: "ClickHouse HTTP endpoint"

  CLICKHOUSE_USER:
    secret: true

  CLICKHOUSE_PASSWORD:
    secret: true

  AUTH_SERVICE_URL:
    description: "Auth service gRPC address"

  CONFIG_SERVICE_URL:
    description: "Config service gRPC address"

optional:
  HTTP_PORT:
    default: "8010"

  GRAPHQL_INTROSPECTION:
    description: "Enable GraphQL introspection"
    default: "false"

  GRAPHQL_PLAYGROUND:
    description: "Enable GraphQL playground"
    default: "false"

  QUERY_CACHE_TTL:
    description: "Query result cache TTL in seconds"
    default: "60"

  QUERY_DEPTH_LIMIT:
    description: "Maximum GraphQL query depth"
    default: "10"

  QUERY_COMPLEXITY_LIMIT:
    description: "Maximum query complexity score"
    default: "1000"

  SUBSCRIPTION_ENABLED:
    description: "Enable GraphQL subscriptions"
    default: "true"
```

---

## Notification Service

**Ports:** 8012 (HTTP), 9012 (gRPC)

```yaml
required:
  DATABASE_URL:
    description: "PostgreSQL for notification history"
    secret: true

  REDIS_URL:
    description: "Redis for rate limiting"
    secret: true

  KAFKA_BROKERS:
    description: "Comma-separated Kafka broker list"

  AUTH_SERVICE_URL:
    description: "Auth service gRPC address"

optional:
  HTTP_PORT:
    default: "8012"

  GRPC_PORT:
    default: "9012"

  KAFKA_CONSUMER_GROUP:
    default: "notification-sender"

  # Email Configuration
  SMTP_HOST:
    description: "SMTP server host"
    example: "smtp.sendgrid.net"

  SMTP_PORT:
    description: "SMTP server port"
    default: "587"

  SMTP_USER:
    secret: true

  SMTP_PASSWORD:
    secret: true

  EMAIL_FROM:
    description: "Default from email address"
    example: "alerts@platform.example.com"

  # Slack Configuration
  SLACK_BOT_TOKEN:
    description: "Slack bot OAuth token"
    secret: true

  SLACK_SIGNING_SECRET:
    description: "Slack app signing secret"
    secret: true

  # Webhook Configuration
  WEBHOOK_TIMEOUT_MS:
    description: "Webhook delivery timeout"
    default: "30000"

  WEBHOOK_RETRY_COUNT:
    description: "Webhook retry attempts"
    default: "5"

  # Rate Limiting
  EMAIL_RATE_LIMIT:
    description: "Emails per minute per org"
    default: "100"

  SLACK_RATE_LIMIT:
    description: "Slack messages per minute per org"
    default: "50"
```

---

## Analytics Service

**Ports:** 8011 (HTTP), 9011 (gRPC)

```yaml
required:
  CLICKHOUSE_URL:
    description: "ClickHouse HTTP endpoint"

  CLICKHOUSE_USER:
    secret: true

  CLICKHOUSE_PASSWORD:
    secret: true

  KAFKA_BROKERS:
    description: "Comma-separated Kafka broker list"

  AUTH_SERVICE_URL:
    description: "Auth service gRPC address"

optional:
  HTTP_PORT:
    default: "8011"

  GRPC_PORT:
    default: "9011"

  AGGREGATION_INTERVAL:
    description: "Metrics aggregation interval in seconds"
    default: "60"

  RETENTION_DAYS:
    description: "Metrics retention period"
    default: "90"
```

---

## Navigation

- **Up:** [Development Guide](README.md)
- **Previous:** [Local Development](local-dev.md)
