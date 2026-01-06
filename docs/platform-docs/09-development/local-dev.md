# Local Development Environment

> Complete local development setup for the Campaign Lifecycle Platform.

---

## Overview

This guide covers setting up a complete local development environment that mirrors production as closely as possible.

---

## Prerequisites

| Tool | Version | Installation |
| ------ | --------- | -------------- |
| Docker | 24+ | [Install Docker](https://docs.docker.com/get-docker/) |
| Docker Compose | 2.20+ | Included with Docker Desktop |
| Go | 1.21+ | `brew install go` |
| Rust | 1.75+ | `curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs \| sh` |
| Node.js | 20+ | `brew install node` or use nvm |
| pnpm | 8+ | `npm install -g pnpm` |
| kubectl | 1.28+ | `brew install kubectl` |
| buf | 1.28+ | `brew install bufbuild/buf/buf` |

---

## Quick Start

```bash
# 1. Clone the repository
git clone git@github.com:org/platform.git
cd platform

# 2. Start infrastructure
make dev-up

# 3. Run database migrations
make migrate

# 4. Start services (in separate terminals)
make run-auth
make run-config
# ... or run all
make run-all

# 5. Access services
open http://localhost:3000      # Frontend
open http://localhost:8080      # Temporal UI
open http://localhost:3001      # Grafana
```

---

## Infrastructure Services

The `docker-compose.dev.yml` provides:

| Service | Port | Purpose |
| --------- | ------ | --------- |
| PostgreSQL | 5432 | Primary OLTP database |
| ClickHouse | 8123/9000 | Analytics database |
| Redis | 6379 | Cache and sessions |
| Kafka | 9092 | Event streaming |
| Zookeeper | 2181 | Kafka coordination |
| MinIO | 9100/9101 | S3-compatible storage |
| Temporal | 7233/8088 | Workflow orchestration |
| Prometheus | 9090 | Metrics collection |
| Grafana | 3001 | Dashboards |

---

## Environment Variables

Create a `.env` file in the project root:

```bash
# Database
DATABASE_URL=postgres://platform:platform_dev@localhost:5432/platform?sslmode=disable
CLICKHOUSE_URL=http://localhost:8123
REDIS_URL=redis://localhost:6379

# Kafka
KAFKA_BROKERS=localhost:9092

# Storage
S3_ENDPOINT=http://localhost:9100
S3_ACCESS_KEY=minioadmin
S3_SECRET_KEY=minioadmin
S3_BUCKET=platform-data

# Temporal
TEMPORAL_ADDRESS=localhost:7233

# Auth
JWT_SECRET=dev-secret-change-in-production-min-32-chars
JWT_ACCESS_TOKEN_TTL=3600
JWT_REFRESH_TOKEN_TTL=604800

# Logging
LOG_LEVEL=debug
LOG_FORMAT=console

# Tracing (optional)
OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4317
```

---

## Service Ports

| Service | HTTP | gRPC | Description |
| --------- | ------ | ------ | ------------- |
| auth-service | 8001 | 9001 | Authentication |
| config-service | 8002 | 9002 | Configuration |
| connector-service | 8003 | 9003 | DSP connectors |
| etl-service | 8004 | 9004 | ETL orchestration |
| bronze-service | 8005 | 9005 | Bronze layer |
| silver-service | 8006 | 9006 | Silver layer |
| gold-service | 8007 | 9007 | Gold layer |
| calculation-service | 8008 | 9008 | Formula engine |
| rule-engine | 8009 | 9009 | Rule evaluation |
| query-service | 8010 | - | GraphQL gateway |
| analytics-service | 8011 | 9011 | Analytics |
| notification-service | 8012 | 9012 | Notifications |
| frontend | 3000 | - | Web UI |

---

## Running Individual Services

### Go Services

```bash
cd services/auth-service
go run main.go

# With hot reload
go install github.com/cosmtrek/air@latest
air
```

### Rust Services

```bash
cd services/config-service
cargo run

# With hot reload
cargo install cargo-watch
cargo watch -x run
```

### TypeScript Services

```bash
cd services/query-service
pnpm install
pnpm dev
```

### Frontend

```bash
cd frontend
pnpm install
pnpm dev
```

---

## Database Management

### Run Migrations

```bash
# All databases
make migrate

# Specific database
make migrate-postgres
make migrate-clickhouse
```

### Reset Database

```bash
# Warning: destroys all data
make db-reset
```

### Seed Data

```bash
# Load test data
make db-seed
```

### Connect to Databases

```bash
# PostgreSQL
psql postgres://platform:platform_dev@localhost:5432/platform

# ClickHouse
clickhouse-client --host localhost --port 9000

# Redis
redis-cli
```

---

## Kafka Management

### View Topics

```bash
docker exec -it platform-kafka kafka-topics --bootstrap-server localhost:9092 --list
```

### Create Topics

```bash
make kafka-create-topics
```

### Consume Messages

```bash
docker exec -it platform-kafka kafka-console-consumer \
  --bootstrap-server localhost:9092 \
  --topic connector.data.raw \
  --from-beginning
```

---

## Testing

### Unit Tests

```bash
# All services
make test

# Specific service
cd services/auth-service && go test ./...
cd services/config-service && cargo test
```

### Integration Tests

```bash
# Start infrastructure
make dev-up

# Run integration tests
make test-integration
```

### E2E Tests

```bash
# Start everything
make run-all

# Run E2E tests
cd e2e && pnpm test
```

---

## Debugging

### View Logs

```bash
# All infrastructure
docker-compose -f docker-compose.dev.yml logs -f

# Specific service
docker-compose -f docker-compose.dev.yml logs -f postgres

# Application logs
tail -f logs/auth-service.log
```

### Connect to Container

```bash
docker exec -it platform-postgres bash
docker exec -it platform-kafka bash
```

### Temporal Web UI

Access at [http://localhost:8088](http://localhost:8088)to:

- View workflow executions
- Inspect workflow state
- Debug failed workflows

---

## Troubleshooting

### Port Conflicts

```bash
# Find what's using a port
lsof -i :5432

# Kill process
kill -9 <PID>
```

### Docker Issues

```bash
# Reset Docker
docker-compose -f docker-compose.dev.yml down -v
docker system prune -a

# Restart
make dev-up
```

### Database Connection Issues

```bash
# Check PostgreSQL is running
docker-compose -f docker-compose.dev.yml ps postgres

# Check logs
docker-compose -f docker-compose.dev.yml logs postgres
```

### Kafka Issues

```bash
# Check broker health
docker exec -it platform-kafka kafka-broker-api-versions --bootstrap-server localhost:9092
```

---

## IDE Setup

### VS Code

Recommended extensions:

- Go (golang.go)
- rust-analyzer
- ESLint
- Prettier
- Docker
- PostgreSQL

### GoLand / IntelliJ

- Install Go plugin
- Import project as Go module
- Configure GOPATH

### Settings

`.vscode/settings.json`:

```json
{
  "go.useLanguageServer": true,
  "go.lintTool": "golangci-lint",
  "rust-analyzer.checkOnSave.command": "clippy",
  "editor.formatOnSave": true
}
```

---

## Navigation

- **Up:** [Development Guide](README.md)
- **Next:** [Docker Compose Reference](docker-compose.dev.yml)
