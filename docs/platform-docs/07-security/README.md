# 🔐 Security Architecture

> Authentication, authorization, and security controls.

---

## Section Contents

| Document | Description |
| ---------- | ------------- |
| [Authentication](authentication.md) | Login, tokens, sessions |
| [Permissions](permissions.md) | RBAC and entity-level access |
| [Encryption](encryption.md) | Data protection |
| [Network Security](network.md) | Network isolation and controls |

---

## Security Overview

```text
┌─────────────────────────────────────────────────────────────────────────────┐
│                        SECURITY ARCHITECTURE                                │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│   PERIMETER                                                                 │
│   ┌─────────────────────────────────────────────────────────────────────┐   │
│   │  WAF → DDoS Protection → Load Balancer → TLS Termination            │   │
│   └─────────────────────────────────────────────────────────────────────┘   │
│                                    │                                        │
│                                    ▼                                        │
│   AUTHENTICATION                                                            │
│   ┌─────────────────────────────────────────────────────────────────────┐   │
│   │  JWT Validation → Rate Limiting → Session Management                │   │
│   └─────────────────────────────────────────────────────────────────────┘   │
│                                    │                                        │
│                                    ▼                                        │
│   AUTHORIZATION                                                             │
│   ┌─────────────────────────────────────────────────────────────────────┐   │
│   │  RBAC Check → Entity Permission → Resource Isolation                │   │
│   └─────────────────────────────────────────────────────────────────────┘   │
│                                    │                                        │
│                                    ▼                                        │
│   DATA PROTECTION                                                           │
│   ┌─────────────────────────────────────────────────────────────────────┐   │
│   │  Encryption at Rest → Encryption in Transit → Audit Logging         │   │
│   └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Authentication Summary

### Token Types

| Token | Lifetime | Storage | Purpose |
| ------- | ---------- | --------- | --------- |
| Refresh Token | 30 days | HttpOnly cookie | Get new access tokens |
| Access Token | 1 hour | Memory only | API authorization |
| API Key | Until revoked | Secure vault | Service-to-service |

### Authentication Flow

```text
1. User logs in with email/password
2. System returns refresh token (HttpOnly cookie)
3. User selects organization
4. System returns access token (org-scoped)
5. Access token used for all API calls
6. Auto-refresh at 50 minutes
```

---

## Authorization Model

### Role-Based Access (RBAC)

| Role | Description | Permissions |
| ------ | ------------- | ------------- |
| **Owner** | Organization creator | Full access |
| **Admin** | Administrator | Manage users, all entities |
| **Member** | Standard user | Assigned entities |
| **Viewer** | Read-only | View only |

### Entity-Level Permissions

Beyond roles, specific permissions can be granted:

```text
User A (Member role) + explicit grant:
  └── Can edit Campaign X
  └── Can view DSP Account Y
  └── Cannot access Campaign Z
```

### Permission Resolution

```text
1. Is user the entity owner? → Full access
2. Is user org admin? → Full access
3. Has explicit grant? → Granted permissions
4. Has parent entity access? → Inherited permissions
5. Default → Deny
```

---

## Data Protection

### Encryption at Rest

| Data | Algorithm | Key Management |
| ------ | ----------- | ---------------- |
| User passwords | bcrypt | N/A (hash) |
| DSP credentials | AES-256-GCM | Vault |
| Database | AES-256 | Managed (Cloud) |
| Object storage | AES-256 | Managed (Cloud) |

### Encryption in Transit

| Connection | Protocol | Minimum Version |
| ------------ | ---------- | ----------------- |
| Client → API | TLS | 1.3 |
| Service → Service | mTLS | 1.3 |
| Service → Database | TLS | 1.2 |

---

## Secrets Management

```text
┌─────────────────────────────────────────────────────────────────────────────┐
│                        SECRETS MANAGEMENT                                   │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│   ┌────────────────┐     ┌────────────────┐     ┌────────────────┐          │
│   │    Vault       │     │   External     │     │   Kubernetes   │          │
│   │   (Primary)    │────▶│   Secrets      │────▶│    Secrets     │          │
│   │                │     │   Operator     │     │                │          │
│   └────────────────┘     └────────────────┘     └────────────────┘          │
│                                                         │                   │
│                                                         ▼                   │
│                                                  ┌────────────────┐         │
│                                                  │   Application  │         │
│                                                  │    (env vars)  │         │
│                                                  └────────────────┘         │
│                                                                             │
│   Secret Types:                                                             │
│   • DSP OAuth credentials                                                   │
│   • Database passwords                                                      │
│   • API keys                                                                │
│   • Encryption keys                                                         │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Audit Logging

### What's Logged

| Event | Data Captured |
| ------- | --------------- |
| Login | User, IP, timestamp, success/failure |
| Config change | User, before/after, timestamp |
| Data access | User, resource, query, timestamp |
| Permission change | Grantor, grantee, permission |
| API call | Endpoint, user, response code |

### Retention

| Log Type | Retention | Storage |
| ---------- | ----------- | --------- |
| Security events | 2 years | PostgreSQL |
| Access logs | 90 days | Loki |
| Audit trail | 7 years | Cold storage |

---

## Compliance

### SOC 2 Controls

| Control | Implementation |
| --------- | ---------------- |
| Access control | RBAC + MFA |
| Encryption | AES-256, TLS 1.3 |
| Logging | Immutable audit trail |
| Monitoring | 24/7 alerts |
| Incident response | Documented procedures |

### GDPR Requirements

| Requirement | Implementation |
| ------------- | ---------------- |
| Right to access | Data export API |
| Right to erasure | Data deletion workflow |
| Data portability | Standard export formats |
| Consent | Explicit opt-in |

---

## Navigation

- **Previous:** [Integration Layer](../06-integrations/README.md)
- **Next:** [Infrastructure](../08-infrastructure/README.md)
