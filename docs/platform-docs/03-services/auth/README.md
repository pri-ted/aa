# Auth Service

> Authentication, authorization, and session management.

---

## Service Overview

| Property | Value |
| ---------- | ------- |
| **Language** | Go 1.21+ |
| **Framework** | Gin |
| **Database** | PostgreSQL 16 + Redis 7 |
| **Port** | 8001 |
| **gRPC Port** | 9001 |
| **Replicas** | 3 (HA) |
| **Owner** | Platform Team |

---

## Responsibilities

1. **User Authentication** - Email/password login, OAuth 2.0
2. **Organization Management** - Multi-tenant org handling
3. **Session Management** - JWT tokens, refresh flow
4. **Role-Based Access Control (RBAC)** - Admin, member, viewer roles
5. **Entity-Level Permissions** - Granular access to specific resources
6. **Audit Logging** - Security events tracking

---

## Architecture

```text
┌─────────────────────────────────────────────────────────────────────────────┐
│                          AUTH SERVICE                                       │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│   ┌───────────────────────────────────────────────────────────────────┐     │
│   │                      API Layer (Gin)                              │     │
│   │   /auth/login  /auth/select-org  /auth/refresh  /permissions/*    │     │
│   └───────────────────────────────────────────────────────────────────┘     │
│                                   │                                         │
│                                   ▼                                         │
│   ┌───────────────────────────────────────────────────────────────────┐     │
│   │                      Business Logic                               │     │
│   │   AuthHandler  SessionManager  PermissionChecker  AuditLogger     │     │
│   └───────────────────────────────────────────────────────────────────┘     │
│                                   │                                         │
│                 ┌─────────────────┼─────────────────┐                       │
│                 ▼                 ▼                 ▼                       │
│   ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐             │
│   │   PostgreSQL    │  │     Redis       │  │    Kafka        │             │
│   │   users, orgs   │  │   sessions,     │  │   audit.events  │             │
│   │   permissions   │  │   rate limits   │  │                 │             │
│   └─────────────────┘  └─────────────────┘  └─────────────────┘             │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## API Endpoints

### POST /api/v1/auth/login

Authenticate user with email and password.

**Request:**

```json
{
  "email": "user@example.com",
  "password": "string"
}
```

**Response (200):**

```json
{
  "refresh_token": "eyJhbGciOiJIUzI1NiIs...",
  "user": {
    "id": 123,
    "email": "user@example.com",
    "full_name": "John Doe",
    "organizations": [
      {
        "id": 456,
        "name": "Acme Corp",
        "role": "admin",
        "is_premium": true
      }
    ]
  }
}
```

**Errors:**

| Code | Error | Description |
| ------ | ------- | ------------- |
| 401 | INVALID_CREDENTIALS | Wrong email or password |
| 403 | ACCOUNT_LOCKED | Too many failed attempts |
| 429 | TOO_MANY_REQUESTS | Rate limit exceeded |

---

### POST /api/v1/auth/select-org

Select organization and get access token.

**Headers:** `Authorization: Bearer <refresh_token>`

**Request:**

```json
{
  "org_id": 456
}
```

**Response (200):**

```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIs...",
  "expires_in": 3600,
  "organization": {
    "id": 456,
    "name": "Acme Corp",
    "settings": {
      "timezone": "America/New_York",
      "currency": "USD"
    },
    "enabled_modules": ["pacing", "qa", "taxonomy"],
    "connected_dsps": ["DV360", "TTD"],
    "is_premium": true
  },
  "permissions": [
    "read:campaigns",
    "write:pipelines",
    "manage:users"
  ]
}
```

---

### POST /api/v1/auth/refresh

Refresh access token using refresh token.

**Headers:** `Authorization: Bearer <refresh_token>`

**Response (200):**

```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIs...",
  "expires_in": 3600
}
```

---

### POST /api/v1/auth/logout

Invalidate current session.

**Headers:** `Authorization: Bearer <access_token>`

**Response (200):**

```json
{
  "message": "Logged out successfully"
}
```

---

### POST /api/v1/permissions/grant

Grant permissions to a user on an entity.

**Request:**

```json
{
  "user_id": 789,
  "entity_type": "dsp_account",
  "entity_id": "dsp_acc_456",
  "permissions": ["view", "execute"]
}
```

**Response (200):**

```json
{
  "message": "Permissions granted",
  "grants": [
    {
      "user_id": 789,
      "entity_type": "dsp_account",
      "entity_id": "dsp_acc_456",
      "permission": "view"
    }
  ]
}
```

---

### GET /api/v1/permissions/check

Check if current user has permission on entity.

**Query Params:** `entity_type`, `entity_id`, `permission`

**Response (200):**

```json
{
  "has_permission": true,
  "reason": "owner"
}
```

---

## Database Schemas

### users

```sql
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    full_name VARCHAR(255),
    email_verified BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);
```

### organizations

```sql
CREATE TABLE organizations (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    slug VARCHAR(255) UNIQUE NOT NULL,
    is_premium BOOLEAN DEFAULT FALSE,
    timezone VARCHAR(50) DEFAULT 'UTC',
    currency VARCHAR(3) DEFAULT 'USD',
    enabled_modules JSONB DEFAULT '[]',
    settings JSONB DEFAULT '{}',
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);
```

### org_memberships

```sql
CREATE TABLE org_memberships (
    user_id INT REFERENCES users(id) ON DELETE CASCADE,
    org_id INT REFERENCES organizations(id) ON DELETE CASCADE,
    role VARCHAR(50) NOT NULL,
    invited_by INT REFERENCES users(id),
    joined_at TIMESTAMP DEFAULT NOW(),
    PRIMARY KEY (user_id, org_id)
);
```

### sessions

```sql
CREATE TABLE sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id INT REFERENCES users(id) ON DELETE CASCADE,
    org_id INT REFERENCES organizations(id) ON DELETE CASCADE,
    refresh_token_hash VARCHAR(255) UNIQUE,
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMP DEFAULT NOW(),
    expires_at TIMESTAMP NOT NULL,
    last_activity TIMESTAMP DEFAULT NOW()
);
```

### entity_permissions

```sql
CREATE TABLE entity_permissions (
    id SERIAL PRIMARY KEY,
    user_id INT REFERENCES users(id) ON DELETE CASCADE,
    org_id INT REFERENCES organizations(id) ON DELETE CASCADE,
    entity_type VARCHAR(100) NOT NULL,
    entity_id VARCHAR(255) NOT NULL,
    permission VARCHAR(100) NOT NULL,
    granted_by INT REFERENCES users(id),
    granted_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(user_id, org_id, entity_type, entity_id, permission)
);
```

---

## Token Structure

### Refresh Token (30 days)

```json
{
  "sub": 123,
  "type": "refresh",
  "iat": 1703318400,
  "exp": 1705910400,
  "jti": "session_uuid"
}
```

### Access Token (1 hour)

```json
{
  "sub": 123,
  "type": "access",
  "org_id": 456,
  "role": "admin",
  "permissions": ["read:campaigns", "write:pipelines"],
  "iat": 1703318400,
  "exp": 1703322000
}
```

---

## Permission Resolution

**Priority Order:**

1. Owner → Full access
2. Explicit Grant → Specific permission
3. Role-Based → Admin gets all
4. Inherited → From parent entity

---

## Configuration

```yaml
auth:
  jwt:
    access_token_ttl: 3600
    refresh_token_ttl: 2592000
    secret: ${JWT_SECRET}
  session:
    max_per_user: 10
    idle_timeout: 3600
  rate_limit:
    login_attempts: 5
    lockout_duration: 900
```

---

## Events Published

| Topic | Event |
| ------- | ------- |
| `auth.events` | `user.logged_in`, `user.logged_out` |
| `auth.events` | `session.created`, `permission.granted` |
| `audit.events` | All security events |

---

## Navigation

- **Up:** [Service Catalog](../README.md)
- **Next:** [Config Service](../config/README.md)
