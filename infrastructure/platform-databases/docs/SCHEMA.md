# Database Schema Documentation

## Core Tables

### organizations
Tenant organizations in the platform.

**Columns:**
- `id` (UUID, PK): Unique identifier
- `name` (VARCHAR): Organization name
- `slug` (VARCHAR, UNIQUE): URL-safe identifier
- `status` (VARCHAR): active, inactive, suspended
- `settings` (JSONB): Organization settings
- `created_at`, `updated_at` (TIMESTAMP)

**Indexes:**
- Primary key on `id`
- Unique index on `slug`
- Index on `status`

### users
User accounts with multi-tenant support.

**Columns:**
- `id` (UUID, PK): Unique identifier
- `org_id` (UUID, FK): Organization
- `email` (VARCHAR): Email address
- `password_hash` (VARCHAR): Bcrypt password hash
- `name` (VARCHAR): Full name
- `status` (VARCHAR): active, inactive, suspended
- `last_login_at` (TIMESTAMP): Last login time
- `created_at`, `updated_at` (TIMESTAMP)

**Indexes:**
- Primary key on `id`
- Unique index on `(org_id, email)`
- Index on `org_id`
- Index on `status`

See README.md for complete schema documentation.
