# Authentication

> User authentication flows and token management.

---

## Authentication Methods

### Email/Password

Primary authentication method for all users.
```text
┌─────────────┐     ┌──────────────┐     ┌─────────────┐
│   Client    │ ──▶ │  Auth API    │ ──▶ │  Validate   │
│   Login     │     │  /login      │     │  Password   │
└─────────────┘     └──────────────┘     └─────────────┘
                                               │
                                               ▼
┌─────────────┐     ┌──────────────┐     ┌─────────────┐
│   Store     │ ◀── │   Generate   │ ◀── │   Create    │
│   Session   │     │   Tokens     │     │   Session   │
└─────────────┘     └──────────────┘     └─────────────┘
```

### SSO / SAML (Enterprise)

For enterprise customers with identity providers.

```yaml
sso:
  providers:
    - type: "saml"
      entity_id: "https://platform.example.com"
      sso_url: "https://idp.customer.com/sso"
      certificate: "${SAML_CERT}"
    
    - type: "oidc"
      issuer: "https://login.customer.com"
      client_id: "${OIDC_CLIENT_ID}"
      client_secret: "${OIDC_SECRET}"
```

### API Keys

For programmatic access.

```yaml
api_key:
  format: "pk_live_{org_id}_{random_32}"
  hash_algorithm: "sha256"
  prefix_stored: true  # First 8 chars for lookup
```

---

## Token Types

### Refresh Token

| Property | Value |
| ---------- | ------- |
| TTL | 30 days |
| Storage | HTTP-only cookie + DB |
| Rotation | On use |
| Revocation | Immediate |

### Access Token

| Property | Value |
| ---------- | ------- |
| TTL | 1 hour |
| Storage | Memory only |
| Format | JWT |
| Refresh | Via refresh token |

### JWT Structure

```json
{
  "header": {
    "alg": "RS256",
    "typ": "JWT",
    "kid": "key-2024-01"
  },
  "payload": {
    "sub": "user_123",
    "org_id": 456,
    "role": "admin",
    "permissions": ["read:campaigns", "write:pipelines"],
    "iat": 1703318400,
    "exp": 1703322000,
    "iss": "https://platform.example.com",
    "aud": "platform-api"
  }
}
```

---

## Password Policy

```yaml
password:
  min_length: 12
  require_uppercase: true
  require_lowercase: true
  require_number: true
  require_special: true
  max_age_days: 90
  history_count: 12
  
  # Breach detection
  check_hibp: true
  block_common: true
```

### Password Storage

```python
# Argon2id with secure parameters
hashed = argon2.hash(
    password,
    time_cost=3,
    memory_cost=65536,  # 64MB
    parallelism=4
)
```

---

## Multi-Factor Authentication (MFA)

### Supported Methods

| Method | Status |
| -------- | -------- |
| TOTP (Authenticator App) | Production |
| SMS | Production |
| Email OTP | Production |
| WebAuthn/FIDO2 | Planned |

### TOTP Configuration

```yaml
totp:
  algorithm: "SHA256"
  digits: 6
  period: 30
  window: 1  # Allow 1 period drift
  issuer: "Platform"
```

### MFA Enforcement

| Tier | MFA Required |
| ------ | -------------- |
| Admin | Always |
| Member | Optional (org setting) |
| Viewer | Optional |
| API Key | N/A (key = factor) |

---

## Session Management

### Session Properties

```sql
CREATE TABLE sessions (
    id UUID PRIMARY KEY,
    user_id INT NOT NULL,
    org_id INT,
    refresh_token_hash VARCHAR(255),
    
    -- Security context
    ip_address INET,
    user_agent TEXT,
    device_fingerprint VARCHAR(255),
    
    -- Lifecycle
    created_at TIMESTAMP DEFAULT NOW(),
    last_activity TIMESTAMP DEFAULT NOW(),
    expires_at TIMESTAMP NOT NULL,
    revoked_at TIMESTAMP,
    
    -- MFA status
    mfa_verified BOOLEAN DEFAULT FALSE,
    mfa_verified_at TIMESTAMP
);
```

### Session Limits

| Setting | Value |
| --------- | ------- |
| Max sessions per user | 10 |
| Idle timeout | 30 minutes |
| Absolute timeout | 24 hours |
| Concurrent org sessions | 1 per org |

---

## Login Security

### Rate Limiting

```yaml
rate_limits:
  login:
    attempts: 5
    window: 5m
    lockout: 15m
  
  password_reset:
    attempts: 3
    window: 1h
    lockout: 1h
  
  mfa:
    attempts: 3
    window: 5m
    lockout: 30m
```

### Suspicious Activity Detection

| Signal | Action |
| -------- | -------- |
| New device | Email notification |
| New location | Email notification |
| Multiple failed logins | Account lockout |
| Impossible travel | Block + notify |

---

## OAuth 2.0 (DSP Authentication)

### Supported Flows

| Flow | Use Case |
| ------ | ---------- |
| Authorization Code | User-interactive DSP connection |
| Refresh Token | Background token refresh |

### Token Storage

```yaml
oauth_tokens:
  encryption: "AES-256-GCM"
  key_rotation: "monthly"
  storage: "secrets_manager"
  
  # Never stored
  access_tokens: "memory_only"
```

---

## Navigation

- **Up:** [Security](README.md)
- **Next:** [Permissions](permissions.md)
