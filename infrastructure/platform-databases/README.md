# platform-databases

Database schemas, migrations, and seed data for Campaign Lifecycle Platform.

## Overview

This repository contains all database-related artifacts for the platform:
- PostgreSQL schemas and migrations (OLTP - primary database)
- ClickHouse table definitions (OLAP - analytics)
- Redis data structures and Lua scripts
- Seed data for development/testing
- Database utilities and scripts

## Repository Structure

```
platform-databases/
├── postgresql/                    # PostgreSQL (primary OLTP database)
│   ├── migrations/               # Sequential migration files
│   │   ├── 001_init_schema.sql  # Initial schema (12 tables)
│   │   ├── 002_seed_data.sql    # Development seed data
│   │   └── 003_indexes.sql      # Additional indexes
│   ├── schemas/                  # Table schemas (reference)
│   ├── functions/                # Stored procedures/functions
│   ├── views/                    # Database views
│   ├── seed/                     # Seed data files
│   └── tests/                    # Database tests
├── clickhouse/                    # ClickHouse (analytics OLAP)
│   ├── tables/                   # Table definitions
│   │   ├── campaign_metrics.sql # Campaign performance
│   │   ├── user_events.sql      # User activity
│   │   └── aggregations.sql     # Pre-aggregated data
│   ├── materialized-views/       # Materialized views
│   └── dictionaries/             # ClickHouse dictionaries
├── redis/                         # Redis (cache & sessions)
│   ├── schemas/                  # Data structure definitions
│   └── scripts/                  # Lua scripts
├── scripts/                       # Utility scripts
│   ├── migrate.sh               # Run migrations
│   ├── seed.sh                  # Load seed data
│   ├── backup.sh                # Backup databases
│   └── restore.sh               # Restore from backup
├── docs/                          # Documentation
│   ├── SCHEMA.md                # Schema documentation
│   ├── MIGRATIONS.md            # Migration guide
│   └── MULTI_TENANCY.md         # Multi-tenant design
└── .github/workflows/            # CI/CD
    └── validate.yaml            # Validate SQL syntax
```

## Database Architecture

### PostgreSQL (Primary OLTP Database)

**Purpose:** Transaction processing, configuration, user data

**Tables (12):**

| Table | Purpose | Partitioning |
|-------|---------|--------------|
| `organizations` | Tenant organizations | - |
| `users` | User accounts | By org_id |
| `user_roles` | RBAC role assignments | By org_id |
| `permissions` | Permission definitions | - |
| `role_permissions` | Role→Permission mapping | - |
| `auth_tokens` | Access/refresh tokens | By org_id |
| `dsp_connectors` | DSP integrations | By org_id |
| `campaigns` | Campaign configurations | By org_id |
| `campaign_metrics` | Daily aggregated metrics | By org_id + date |
| `etl_jobs` | ETL job tracking | By org_id |
| `notifications` | Notification queue | By org_id |
| `audit_logs` | Audit trail | By org_id + date |

**Key Features:**
- Multi-tenant with `org_id` partitioning
- Row-level security
- Automatic `updated_at` triggers
- Comprehensive indexes
- Foreign key relationships

### ClickHouse (Analytics OLAP Database)

**Purpose:** High-performance analytics, time-series data

**Tables:**
- `campaign_metrics_raw` - Raw metrics from DSPs
- `campaign_metrics_hourly` - Hourly aggregations
- `campaign_metrics_daily` - Daily aggregations
- `user_events` - User activity tracking
- `api_logs` - API request logs

**Key Features:**
- Column-oriented storage
- Time-series optimized
- Automatic data retention
- Distributed tables support
- Materialized views for aggregations

### Redis (Cache & Sessions)

**Purpose:** Caching, sessions, rate limiting

**Data Structures:**
- `session:{user_id}` - User sessions (Hash)
- `cache:{key}` - General cache (String)
- `ratelimit:{org_id}:{dsp}` - Rate limits (Sorted Set)
- `queue:{job_type}` - Job queues (List)

**Key Features:**
- TTL-based expiration
- Lua scripts for atomic operations
- Pub/sub for real-time events

## Quick Start

### Prerequisites

- PostgreSQL 15+
- ClickHouse 23+
- Redis 7+
- psql CLI
- clickhouse-client

### Run Migrations

```bash
# PostgreSQL
./scripts/migrate.sh up

# Or manually
psql -h localhost -U platform -d platform_dev -f postgresql/migrations/001_init_schema.sql
psql -h localhost -U platform -d platform_dev -f postgresql/migrations/002_seed_data.sql
```

### Load Seed Data

```bash
# Load development seed data
./scripts/seed.sh

# Or manually
psql -h localhost -U platform -d platform_dev -f postgresql/seed/test_data.sql
```

### Verify Schema

```bash
# Connect to database
psql -h localhost -U platform -d platform_dev

# List tables
\dt

# Describe table
\d users

# Check seed data
SELECT * FROM organizations;
```

## Multi-Tenancy

All tables include `org_id` for tenant isolation:

```sql
-- Example: campaigns table
CREATE TABLE campaigns (
    id UUID PRIMARY KEY,
    org_id UUID NOT NULL,  -- Tenant identifier
    name VARCHAR(255),
    ...
    CONSTRAINT fk_org FOREIGN KEY (org_id) REFERENCES organizations(id)
);

CREATE INDEX idx_campaigns_org_id ON campaigns(org_id);

-- All queries MUST filter by org_id
SELECT * FROM campaigns WHERE org_id = '...' AND id = '...';
```

**Benefits:**
- Data isolation per organization
- Easy to scale (can shard by org_id)
- Security boundary
- Cost tracking per org

## Migrations

### Migration Files

Migrations are sequential and idempotent:

```
001_init_schema.sql      - Initial schema creation
002_seed_data.sql        - Development seed data
003_indexes.sql          - Performance indexes
004_add_column_*.sql     - Schema changes
005_backfill_*.sql       - Data backfills
```

### Naming Convention

```
{number}_{description}.sql

Examples:
001_init_schema.sql
002_seed_data.sql
003_add_campaign_status.sql
004_create_reports_table.sql
```

### Migration Guidelines

1. **Always idempotent**: Use `IF NOT EXISTS`, `IF EXISTS`
2. **Sequential numbering**: Never skip numbers
3. **One-way only**: Never edit existing migrations
4. **Test rollback**: Provide DOWN migrations when possible
5. **Document changes**: Add comments explaining WHY

### Running Migrations

```bash
# Run all pending migrations
./scripts/migrate.sh up

# Run specific migration
./scripts/migrate.sh run 001

# Check migration status
./scripts/migrate.sh status

# Rollback last migration
./scripts/migrate.sh down
```

## Seed Data

### Development Seed Data

Located in `postgresql/seed/`:
- `test_data.sql` - Basic test data (1 org, 2 users, 1 campaign)
- `demo_data.sql` - Demo data for presentations
- `load_data.sql` - Large dataset for load testing

### Loading Seed Data

```bash
# Load test data
psql -h localhost -U platform -d platform_dev -f postgresql/seed/test_data.sql

# Or via script
./scripts/seed.sh test

# Load demo data
./scripts/seed.sh demo
```

### Seed Data Contents

**Test Data:**
- 1 organization: "Test Organization"
- 2 users: admin@test.com, user@test.com
- 1 DSP connector: Test DV360
- 1 campaign: "Test Campaign Q1 2026"
- Default permissions and roles

## Schema Documentation

### Core Tables

#### organizations

Tenant organizations in the platform.

```sql
CREATE TABLE organizations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    slug VARCHAR(100) UNIQUE NOT NULL,
    status VARCHAR(50) DEFAULT 'active',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
```

**Indexes:**
- Primary: `id`
- Unique: `slug`
- Regular: `status`

#### users

User accounts with multi-tenant support.

```sql
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    org_id UUID NOT NULL REFERENCES organizations(id),
    email VARCHAR(255) NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    name VARCHAR(255) NOT NULL,
    status VARCHAR(50) DEFAULT 'active',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(org_id, email)
);
```

**Indexes:**
- Primary: `id`
- Unique: `(org_id, email)`
- Regular: `org_id`, `email`, `status`

See [SCHEMA.md](docs/SCHEMA.md) for complete documentation.

## ClickHouse Tables

### campaign_metrics_raw

Raw metrics from DSP APIs.

```sql
CREATE TABLE campaign_metrics_raw (
    timestamp DateTime,
    org_id String,
    campaign_id String,
    dsp_type String,
    impressions UInt64,
    clicks UInt64,
    conversions UInt64,
    spend Decimal(15, 2),
    revenue Decimal(15, 2)
) ENGINE = MergeTree()
PARTITION BY toYYYYMM(timestamp)
ORDER BY (org_id, campaign_id, timestamp);
```

**Features:**
- Partitioned by month
- Ordered by org_id, campaign_id
- Automatic data retention (90 days)

See [ClickHouse documentation](docs/CLICKHOUSE.md) for more.

## Redis Data Structures

### Sessions

```redis
# User session
HSET session:user_123 user_id "123" org_id "org_456" created_at "2026-01-06"
EXPIRE session:user_123 3600

# Get session
HGETALL session:user_123
```

### Rate Limiting

```redis
# Rate limit per org per DSP
ZADD ratelimit:org_456:dv360 1704556800 "request_1"
ZCOUNT ratelimit:org_456:dv360 1704556800 1704560400
```

### Caching

```redis
# Cache campaign data
SET cache:campaign:123 '{"id":"123","name":"Campaign"}' EX 300

# Get cached data
GET cache:campaign:123
```

## Scripts

### migrate.sh

Run database migrations.

```bash
./scripts/migrate.sh up         # Run all pending
./scripts/migrate.sh down       # Rollback last
./scripts/migrate.sh status     # Check status
./scripts/migrate.sh run 001    # Run specific
```

### seed.sh

Load seed data.

```bash
./scripts/seed.sh test          # Load test data
./scripts/seed.sh demo          # Load demo data
./scripts/seed.sh clear         # Clear all data
```

### backup.sh

Backup databases.

```bash
./scripts/backup.sh postgresql  # Backup PostgreSQL
./scripts/backup.sh clickhouse  # Backup ClickHouse
./scripts/backup.sh all         # Backup all
```

### restore.sh

Restore from backup.

```bash
./scripts/restore.sh postgresql backup-2026-01-06.sql
./scripts/restore.sh clickhouse backup-2026-01-06.tar
```

## Testing

### Unit Tests

Test individual functions and procedures.

```bash
# Run PostgreSQL tests
psql -h localhost -U platform -d platform_test -f postgresql/tests/test_users.sql
```

### Integration Tests

Test complete workflows.

```bash
# Run all tests
./scripts/test.sh

# Run specific test suite
./scripts/test.sh postgresql
./scripts/test.sh clickhouse
```

## CI/CD

GitHub Actions workflow validates SQL on every PR:

```yaml
- Lint SQL files
- Validate syntax
- Check for SQL injection patterns
- Verify migration order
- Run tests
```

## Security

### Passwords

- Never store passwords in plain text
- Always use `password_hash` with bcrypt
- Minimum 8 characters, complexity required

### SQL Injection

- Use parameterized queries
- Never concatenate user input
- Validate all inputs

### Access Control

- Separate database users for each service
- Grant minimum required permissions
- Use row-level security for multi-tenancy

### Audit Logging

All data modifications are logged in `audit_logs`:

```sql
INSERT INTO audit_logs (org_id, user_id, action, resource_type, resource_id)
VALUES ('org_456', 'user_123', 'UPDATE', 'campaigns', 'campaign_789');
```

## Performance

### Indexes

All foreign keys are indexed:
- `org_id` on every table
- `user_id` where applicable
- `created_at` for time-based queries

### Query Optimization

```sql
-- ✅ Good: Uses org_id index
SELECT * FROM campaigns WHERE org_id = '...' AND id = '...';

-- ❌ Bad: Full table scan
SELECT * FROM campaigns WHERE name LIKE '%test%';

-- ✅ Better: Add text search index
CREATE INDEX idx_campaigns_name_gin ON campaigns USING gin(to_tsvector('english', name));
```

### Connection Pooling

Use connection pooling to avoid connection overhead:
- PgBouncer for PostgreSQL
- ClickHouse HTTP interface (built-in pooling)
- Redis connection pool

## Backup & Recovery

### PostgreSQL

```bash
# Full backup
pg_dump -h localhost -U platform platform_dev > backup.sql

# Restore
psql -h localhost -U platform -d platform_dev < backup.sql
```

### ClickHouse

```bash
# Backup
clickhouse-client --query="BACKUP DATABASE platform TO Disk('backups')"

# Restore
clickhouse-client --query="RESTORE DATABASE platform FROM Disk('backups')"
```

### Redis

```bash
# Save snapshot
redis-cli SAVE

# Backup RDB file
cp /var/lib/redis/dump.rdb backup-$(date +%Y%m%d).rdb
```

## Monitoring

### Key Metrics

**PostgreSQL:**
- Connection count
- Query latency
- Table sizes
- Index hit ratio
- Replication lag

**ClickHouse:**
- Query execution time
- Merge performance
- Disk usage
- Memory usage

**Redis:**
- Memory usage
- Hit/miss ratio
- Command latency
- Eviction count

### Health Checks

```bash
# PostgreSQL
psql -h localhost -U platform -d platform_dev -c "SELECT 1"

# ClickHouse
clickhouse-client --query="SELECT 1"

# Redis
redis-cli PING
```

## Documentation

- [Schema Documentation](docs/SCHEMA.md) - Complete schema reference
- [Migration Guide](docs/MIGRATIONS.md) - How to create migrations
- [Multi-Tenancy](docs/MULTI_TENANCY.md) - Multi-tenant design
- [ClickHouse Guide](docs/CLICKHOUSE.md) - ClickHouse specifics
- [Performance Tuning](docs/PERFORMANCE.md) - Optimization tips

## Support

- **Documentation:** See `docs/` directory
- **Issues:** GitHub Issues
- **Slack:** #platform-databases
- **Email:** platform-team@campaign-platform.com

## References

- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [ClickHouse Documentation](https://clickhouse.com/docs/)
- [Redis Documentation](https://redis.io/documentation)
- [Database Best Practices](https://www.postgresql.org/docs/current/best-practices.html)

---

**Database Version:** PostgreSQL 15+, ClickHouse 23+, Redis 7+  
**Schema Version:** 1.0.0  
**Last Updated:** 2026-01-06
