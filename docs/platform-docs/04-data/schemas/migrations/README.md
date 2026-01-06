# Database Migrations

> PostgreSQL schema migrations for the Campaign Lifecycle Platform.

---

## Overview

We use [golang-migrate](https://github.com/golang-migrate/migrate) for database migrations. Migrations are versioned, sequential SQL files that can be applied forward or rolled back.

---

## Directory Structure

```
migrations/
├── README.md                    # This file
├── 000001_create_users.up.sql
├── 000001_create_users.down.sql
├── 000002_create_organizations.up.sql
├── 000002_create_organizations.down.sql
├── 000003_create_org_memberships.up.sql
├── 000003_create_org_memberships.down.sql
├── 000004_create_dsp_accounts.up.sql
├── 000004_create_dsp_accounts.down.sql
├── 000005_create_pipelines.up.sql
├── 000005_create_pipelines.down.sql
├── 000006_create_rules.up.sql
├── 000006_create_rules.down.sql
├── 000007_create_entity_permissions.up.sql
├── 000007_create_entity_permissions.down.sql
├── 000008_create_audit_logs.up.sql
├── 000008_create_audit_logs.down.sql
├── 000009_create_notifications.up.sql
├── 000009_create_notifications.down.sql
├── 000010_create_deals.up.sql
├── 000010_create_deals.down.sql
└── seed/
    ├── 001_default_templates.sql
    ├── 002_system_roles.sql
    └── 003_qa_rules.sql
```

---

## Naming Convention

```
{version}_{description}.{direction}.sql

- version: 6-digit zero-padded number (000001, 000002, ...)
- description: snake_case description
- direction: "up" for apply, "down" for rollback
```

---

## Running Migrations

### Prerequisites

```bash
# Install migrate CLI
brew install golang-migrate

# Or via Go
go install -tags 'postgres' github.com/golang-migrate/migrate/v4/cmd/migrate@latest
```

### Commands

```bash
# Apply all pending migrations
migrate -path ./migrations -database "$DATABASE_URL" up

# Apply N migrations
migrate -path ./migrations -database "$DATABASE_URL" up 3

# Rollback last migration
migrate -path ./migrations -database "$DATABASE_URL" down 1

# Rollback all migrations
migrate -path ./migrations -database "$DATABASE_URL" down

# Go to specific version
migrate -path ./migrations -database "$DATABASE_URL" goto 5

# Check current version
migrate -path ./migrations -database "$DATABASE_URL" version

# Force version (use with caution)
migrate -path ./migrations -database "$DATABASE_URL" force 5
```

### Using Makefile

```bash
make migrate          # Apply all pending migrations
make migrate-down     # Rollback last migration
make migrate-reset    # Rollback all and reapply
make migrate-status   # Show current version
```

---

## Writing Migrations

### Best Practices

1. **Atomic**: Each migration should be self-contained
2. **Reversible**: Always write a `down` migration
3. **Safe**: Avoid breaking changes, use additive migrations
4. **Tested**: Test both up and down migrations locally

### Example

```sql
-- 000001_create_users.up.sql
CREATE TABLE IF NOT EXISTS users (
    id BIGSERIAL PRIMARY KEY,
    email VARCHAR(255) NOT NULL UNIQUE,
    ...
);

CREATE INDEX idx_users_email ON users(email);
```

```sql
-- 000001_create_users.down.sql
DROP INDEX IF EXISTS idx_users_email;
DROP TABLE IF EXISTS users;
```

---

## Multi-Tenant Considerations

All tables must include `org_id` for tenant isolation:

```sql
-- Every table follows this pattern
CREATE TABLE campaigns (
    id UUID PRIMARY KEY,
    org_id BIGINT NOT NULL REFERENCES organizations(id),
    ...
);

-- Index on org_id for every table
CREATE INDEX idx_campaigns_org_id ON campaigns(org_id);

-- Row Level Security (optional, for extra safety)
ALTER TABLE campaigns ENABLE ROW LEVEL SECURITY;
```

---

## Navigation

- **Up:** [Database Schemas](../README.md)
- **Next:** [Complete Schema](../postgresql-complete.sql)
