# Development Guide

> How to set up and contribute to the platform.

---

## Prerequisites

| Tool | Version | Purpose |
| ------ | --------- | --------- |
| Docker | 24+ | Containers |
| kubectl | 1.28+ | K8s CLI |
| Go | 1.21+ | Go services |
| Rust | 1.75+ | Rust services |
| Node.js | 20+ | Frontend & GraphQL |
| pnpm | 8+ | Package manager |

---

## Local Development Setup

### 1. Clone Repositories

```bash
git clone git@github.com:org/platform-services.git
git clone git@github.com:org/platform-frontend.git
git clone git@github.com:org/platform-k8s.git
```

### 2. Start Dependencies

```bash
# Start local services (Postgres, Redis, Kafka, ClickHouse)
docker-compose -f docker-compose.dev.yml up -d

# Verify services
docker-compose ps
```

### 3. Configure Environment

```bash
# Copy example env
cp .env.example .env

# Edit with local settings
vim .env
```

### 4. Run Services

```bash
# Go service
cd auth-service
go run main.go

# Rust service
cd config-service
cargo run

# Node.js service
cd query-service
pnpm install
pnpm dev
```

---

## Project Structure

```text
platform-services/
├── auth-service/          # Go - Authentication
├── config-service/        # Rust - Configuration
├── connector-service/     # Go - DSP connectors
├── etl-service/          # Go - ETL orchestration
├── bronze-service/       # Rust - Bronze layer
├── silver-service/       # Rust - Silver layer
├── gold-service/         # Rust - Gold layer
├── calculation-service/  # Rust - Formula engine
├── rule-engine/          # Rust - Rule evaluation
├── analytics-service/    # Go - Health & costs
├── notification-service/ # Go - Alerts
├── query-service/        # TypeScript - GraphQL
└── shared/
    ├── proto/            # gRPC definitions
    ├── events/           # Kafka schemas
    └── libs/             # Shared libraries
```

---

## Code Standards

### Go

```go
// Use standard project layout
// - cmd/          Main applications
// - internal/     Private code
// - pkg/          Public libraries

// Error handling
if err != nil {
    return fmt.Errorf("operation failed: %w", err)
}

// Logging
log.Info().
    Str("user_id", userID).
    Int("org_id", orgID).
    Msg("User logged in")
```

### Rust

```rust
// Use Result for error handling
fn process_data(input: &str) -> Result<Output, Error> {
    let data = parse(input)?;
    Ok(transform(data))
}

// Use tracing for logging
tracing::info!(user_id = %user_id, "Processing request");
```

### TypeScript

```typescript
// Use strict TypeScript
// tsconfig: "strict": true

// Use functional components
const Component: React.FC<Props> = ({ data }) => {
  return <div>{data.name}</div>;
};

// Use async/await
async function fetchData(): Promise<Data> {
  const response = await fetch('/api/data');
  return response.json();
}
```

---

## Testing

### Unit Tests

```bash
# Go
go test ./...

# Rust
cargo test

# TypeScript
pnpm test
```

### Integration Tests

```bash
# Start test environment
docker-compose -f docker-compose.test.yml up -d

# Run integration tests
make test-integration

# Cleanup
docker-compose -f docker-compose.test.yml down
```

### E2E Tests

```bash
# Start full environment
make dev-up

# Run E2E tests
cd e2e
pnpm test

# With UI
pnpm test:ui
```

---

## Database Migrations

### Create Migration

```bash
# Go (golang-migrate)
migrate create -ext sql -dir migrations -seq add_users_table

# Edit migration
vim migrations/000001_add_users_table.up.sql
vim migrations/000001_add_users_table.down.sql
```

### Run Migrations

```bash
# Apply
migrate -path migrations -database "postgres://..." up

# Rollback
migrate -path migrations -database "postgres://..." down 1
```

---

## Pull Request Process

### 1. Create Branch

```bash
git checkout -b feature/add-new-feature
```

### 2. Make Changes

- Write code
- Add tests
- Update docs

### 3. Pre-commit Checks

```bash
# Run linters
make lint

# Run tests
make test

# Check formatting
make fmt-check
```

### 4. Submit PR

- Use conventional commits
- Reference issue number
- Request reviewers

### 5. Review & Merge

- Address feedback
- Get 2 approvals
- Squash and merge

---

## Commit Messages

```text
feat: add user authentication
fix: resolve login timeout issue
docs: update API documentation
refactor: simplify rule evaluation
test: add integration tests for auth
chore: update dependencies
```

---

## Navigation

- **Up:** [Development](README.md)
- **Previous:** [Migration Strategy](migration.md)
