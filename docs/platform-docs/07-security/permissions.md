# Permissions

> Role-based and entity-level access control.

---

## Permission Model

The platform uses a hybrid RBAC + ABAC model:

- **RBAC**: Role-based permissions for broad access
- **ABAC**: Entity-level permissions for granular control

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         PERMISSION RESOLUTION                               │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│   User Request                                                              │
│        │                                                                    │
│        ▼                                                                    │
│   ┌─────────────┐                                                           │
│   │ Is Owner?   │ ─── Yes ──▶ ALLOW                                         │
│   └─────────────┘                                                           │
│        │ No                                                                 │
│        ▼                                                                    │
│   ┌─────────────┐                                                           │
│   │ Is Admin?   │ ─── Yes ──▶ ALLOW                                         │
│   └─────────────┘                                                           │
│        │ No                                                                 │
│        ▼                                                                    │
│   ┌─────────────┐                                                           │
│   │ Has Grant?  │ ─── Yes ──▶ ALLOW                                         │
│   └─────────────┘                                                           │
│        │ No                                                                 │
│        ▼                                                                    │
│   ┌─────────────┐                                                           │
│   │ Inherited?  │ ─── Yes ──▶ ALLOW                                         │
│   └─────────────┘                                                           │
│        │ No                                                                 │
│        ▼                                                                    │
│      DENY                                                                   │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Roles

### Organization Roles

| Role | Description | Auto-Granted Permissions |
| ------ | ------------- | ------------------------- |
| Owner | Organization creator | All permissions |
| Admin | Full administrative access | All except delete org |
| Member | Standard user | Read all, write own |
| Viewer | Read-only access | Read only |

### Role Permissions Matrix

| Permission | Owner | Admin | Member | Viewer |
| ------------ | ------- | ------- | -------- | -------- |
| read:campaigns | ✓ | ✓ | ✓ | ✓ |
| write:campaigns | ✓ | ✓ | Own | ✗ |
| delete:campaigns | ✓ | ✓ | Own | ✗ |
| read:pipelines | ✓ | ✓ | ✓ | ✓ |
| write:pipelines | ✓ | ✓ | Own | ✗ |
| execute:pipelines | ✓ | ✓ | ✓ | ✗ |
| read:rules | ✓ | ✓ | ✓ | ✓ |
| write:rules | ✓ | ✓ | Own | ✗ |
| manage:users | ✓ | ✓ | ✗ | ✗ |
| manage:billing | ✓ | ✗ | ✗ | ✗ |
| manage:org | ✓ | ✗ | ✗ | ✗ |

---

## Entity-Level Permissions

### Entity Types

| Entity | Parent | Inherits From |
| -------- | -------- | --------------- |
| dsp_account | org | - |
| campaign | dsp_account | dsp_account |
| pipeline | org | - |
| rule | org | - |

### Permission Types

| Permission | Description |
| ------------ | ------------- |
| view | Read entity data |
| edit | Modify entity |
| execute | Trigger actions |
| delete | Remove entity |
| grant | Grant permissions to others |

### Grant Examples

```sql
-- Grant view on specific DSP account
INSERT INTO entity_permissions (user_id, org_id, entity_type, entity_id, permission)
VALUES (789, 456, 'dsp_account', 'dsp_acc_123', 'view');

-- Grant execute on specific pipeline
INSERT INTO entity_permissions (user_id, org_id, entity_type, entity_id, permission)
VALUES (789, 456, 'pipeline', 'pipe_456', 'execute');
```

---

## Permission Inheritance

### Hierarchy

```text
Organization
  └── DSP Account (view, edit)
        └── Campaign (inherits DSP Account permissions)
              └── Ad Group (inherits Campaign permissions)
```

### Inheritance Rules

1. Child entities inherit parent permissions
2. Explicit grants override inherited permissions
3. Deny takes precedence over allow
4. Admin role bypasses inheritance

---

## API Permission Checks

### Check Permission Endpoint

```http
GET /api/v1/permissions/check
  ?entity_type=campaign
  &entity_id=camp_123
  &permission=edit
Authorization: Bearer {access_token}
```

**Response:**

```json
{
  "has_permission": true,
  "reason": "granted",
  "granted_by": {
    "user_id": 100,
    "granted_at": "2024-12-20T10:00:00Z"
  }
}
```

### Bulk Check

```http
POST /api/v1/permissions/check-bulk
Authorization: Bearer {access_token}

{
  "checks": [
    {"entity_type": "campaign", "entity_id": "camp_123", "permission": "view"},
    {"entity_type": "campaign", "entity_id": "camp_456", "permission": "edit"}
  ]
}
```

---

## Permission Grants

### Grant Permission

```http
POST /api/v1/permissions/grant
Authorization: Bearer {access_token}

{
  "user_id": 789,
  "entity_type": "dsp_account",
  "entity_id": "dsp_acc_123",
  "permissions": ["view", "execute"],
  "expires_at": "2025-12-31T23:59:59Z"
}
```

### Revoke Permission

```http
DELETE /api/v1/permissions/revoke
Authorization: Bearer {access_token}

{
  "user_id": 789,
  "entity_type": "dsp_account",
  "entity_id": "dsp_acc_123",
  "permissions": ["execute"]
}
```

---

## Feature Flags

### Organization Features

```yaml
features:
  - id: "write_back"
    name: "Campaign Write-Back"
    enabled_for: ["enterprise"]
    
  - id: "advanced_rules"
    name: "Advanced Rule Engine"
    enabled_for: ["enterprise", "growth"]
    
  - id: "api_access"
    name: "API Access"
    enabled_for: ["enterprise"]
```

### Feature Check

```python
def can_use_feature(org_id: int, feature: str) -> bool:
    org = get_org(org_id)
    feature_config = get_feature(feature)
    
    if org.tier in feature_config.enabled_for:
        return True
    
    if feature in org.custom_features:
        return True
    
    return False
```

---

## Audit Trail

### Logged Events

| Event | Data Captured |
| ------- | -------------- |
| permission.granted | Who, to whom, what, when |
| permission.revoked | Who, from whom, what, when |
| permission.denied | Who, what, why, when |
| role.changed | Who, old role, new role, when |

### Audit Query

```sql
SELECT * FROM audit_logs
WHERE action LIKE 'permission.%'
  AND org_id = 456
  AND timestamp >= NOW() - INTERVAL '7 days'
ORDER BY timestamp DESC;
```

---

## Navigation

- **Up:** [Security](README.md)
- **Previous:** [Authentication](authentication.md)
- **Next:** [Encryption](encryption.md)
