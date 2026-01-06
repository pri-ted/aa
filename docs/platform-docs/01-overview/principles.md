# Architectural Principles

> 12 non-negotiable principles that guide all design decisions.

---

## Core Principles (P1-P8)

### P1: Metadata-Driven Everything

**What:** All configuration stored as data, never as code.

**Why:** Enables self-service; eliminates code deploys for customer changes.

**Enforcement:**

- Config Service owns all org-specific behavior
- No `if org_id == X` in code
- All business rules in database

**Example - BAD:**

```python
if org.name == "Acme":
    margin_formula = "revenue - cost"
elif org.name == "Globex":
    margin_formula = "(revenue - cost) / revenue * 100"
```

**Example - GOOD:**

```python
formula = config_service.get_formula(org_id, "margin")
result = calculation_engine.evaluate(formula, data)
```

---

### P2: Self-Service by Default

**What:** Every user action must be achievable through UI without engineering.

**Why:** Eliminates engineering bottleneck; enables scale.

**Enforcement:**

- No feature ships without corresponding UI
- All configuration has validation and preview
- Help text for every field

**Checklist for new features:**

- [ ] Can user configure without code?
- [ ] Can user preview changes?
- [ ] Can user rollback if wrong?
- [ ] Is there help documentation?

---

### P3: Fail Gracefully, Never Silently

**What:** Circuit breakers, auto-retry, clear error states, stale data fallback.

**Why:** Maintains user trust; enables debugging.

**Enforcement:**

- All external calls wrapped in circuit breakers
- All failures logged with context
- User sees clear error messages

**Pattern:**

```text
┌─────────────────────────────────────────────────┐
│              FAILURE HANDLING                   │
├─────────────────────────────────────────────────┤
│                                                 │
│  Request ──▶ Circuit Breaker                    │
│                   │                             │
│         ┌────────┴────────┐                     │
│         │                 │                     │
│      CLOSED            OPEN                     │
│         │                 │                     │
│         ▼                 ▼                     │
│     Try Request      Return Cached              │
│         │                 │                     │
│    ┌────┴────┐            │                     │
│    │         │            │                     │
│ Success   Failure         │                     │
│    │         │            │                     │
│    ▼         ▼            │                     │
│  Return   Retry (3x)      │                     │
│    │         │            │                     │
│    │    Still Fail?       │                     │
│    │         │            │                     │
│    │         ▼            │                     │
│    │    OPEN Circuit      │                     │
│    │         │            │                     │
│    └─────────┴────────────┘                     │
│                                                 │
└─────────────────────────────────────────────────┘
```

---

### P4: Org Isolation as First-Class

**What:** Complete data and resource isolation between organizations.

**Why:** Security; prevents noisy neighbor; enables per-org billing.

**Enforcement:**

- `org_id` required on every query, event, and API call
- Partition all tables by `org_id`
- Rate limits per org

**Example - Every query:**

```sql
SELECT * FROM campaigns
WHERE org_id = $1  -- Always required
  AND campaign_id = $2
```

---

### P5: Progressive Enablement

**What:** Modules work with partial dependencies; more data = more features.

**Why:** Reduces time to value; allows incremental adoption.

**Enforcement:**

- Module framework handles capability detection
- UI shows available vs locked features
- Clear path to unlock more

**Example:**

```text
DSP Connection Only:
  ✓ Basic Pacing
  ✓ Spend Tracking
  ✗ Margin Calculation (needs Booking)
  ✗ Variance Analysis (needs CRM)

DSP + Booking:
  ✓ Basic Pacing
  ✓ Spend Tracking
  ✓ Margin Calculation
  ✗ Variance Analysis (needs CRM)
```

---

### P6: Smart Defaults from Similar Orgs

**What:** New organizations inherit intelligent defaults based on industry, size, DSP mix.

**Why:** Reduces configuration time; leverages collective knowledge.

**Enforcement:**

- Recommendation engine on onboarding
- Template library maintained
- Usage analytics inform defaults

**Default Selection:**

```text
New Org: Agency, 10 campaigns, DV360 only
         │
         ▼
    Template Match: "DV360 Standard Agency"
         │
         ▼
    Pre-configured:
    • Daily pacing checks at 6 AM
    • Standard QA rule set (32 rules)
    • Margin calculation formula
    • Alert thresholds (±20% pacing)
```

---

### P7: Audit Everything

**What:** Every configuration change, user action, and system event logged immutably.

**Why:** Compliance; debugging; rollback capability.

**Enforcement:**

- Event sourcing for all configuration
- Append-only audit logs
- Retention per compliance requirements

**Audit Log Entry:**

```json
{
  "timestamp": "2024-12-24T10:00:00Z",
  "org_id": 456,
  "user_id": 123,
  "action": "rule.updated",
  "resource": {
    "type": "alert_rule",
    "id": "rule_789"
  },
  "before": { "threshold": 100 },
  "after": { "threshold": 120 },
  "ip_address": "192.168.1.1",
  "user_agent": "Mozilla/5.0..."
}
```

---

### P8: Cloud-Agnostic Core

**What:** Kubernetes-native; no cloud-specific services in core logic.

**Why:** Deployment flexibility; vendor independence.

**Enforcement:**

- All cloud services abstracted behind interfaces
- Tested on AWS, GCP, and local (kind)
- Infrastructure as Code for all clouds

**Abstraction Example:**

```go
// Interface - cloud agnostic
type ObjectStorage interface {
    Put(key string, data []byte) error
    Get(key string) ([]byte, error)
    Delete(key string) error
}

// Implementations
type S3Storage struct { ... }      // AWS
type GCSStorage struct { ... }     // GCP
type MinIOStorage struct { ... }   // On-prem
```

---

## Write-Back Principles (P9-P12)

### P9: Bi-Directional by Design

**What:** Every read path has a corresponding write path designed (even if not implemented).

**Why:** Ensures architecture supports future campaign management.

**Enforcement:**

- Connector interface includes both read and write methods
- Entity model supports platform → DSP sync
- Audit trail for all write operations

---

### P10: DSP-Agnostic Entity Model

**What:** Internal entities are unified; translation happens at adapter layer.

**Why:** Enables cross-DSP operations and reporting.

**Enforcement:**

- All business logic operates on platform entities
- Adapters handle DSP-specific translation
- Unified reporting across DSPs

**Entity Mapping:**

```text
Platform Entity     DV360              TTD
───────────────     ─────              ───
Campaign         →  Campaign        →  Campaign
IO/AdGroup       →  Insertion Order →  Ad Group
LineItem/Ad      →  Line Item       →  Ad Group
Creative         →  Creative        →  Creative
```

---

### P11: Safe Write-Back

**What:** All writes must be idempotent, reversible, audited, and permissioned.

**Why:** Prevents data corruption; enables rollback; maintains compliance.

**Enforcement:**

- Idempotency keys on all write operations
- Audit log before execution
- Permission check before write
- Rollback procedure documented

---

### P12: Conflict Resolution Strategy

**What:** Platform state vs DSP state conflicts handled explicitly.

**Why:** DSPs are source of truth for their data; platform must reconcile.

**Enforcement:**

- Periodic sync jobs detect drift
- Conflict alerts to users
- Resolution workflow defined

**Conflict Types:**

| Type           | Example                  | Resolution                     |
| -------------- | ------------------------ | ------------------------------ |
| Value Drift    | Budget changed in DSP UI | Alert user, offer sync options |
| State Drift    | Campaign paused in DSP   | Update platform state          |
| Missing Entity | Campaign deleted in DSP  | Mark as archived in platform   |

---

## Trade-offs Accepted

| Trade-off                      | Accepted Because                               |
| ------------------------------ | ---------------------------------------------- |
| Go over Rust for most services | Team velocity > marginal performance gain      |
| PostgreSQL before sharding     | Sufficient for <200 orgs; Citus when needed    |
| Self-hosted ClickHouse         | 4x cost savings vs managed; team has expertise |
| Batch over real-time           | 15-minute freshness sufficient for use cases   |
| Read-first, write later        | De-risks Phase 1; validates architecture       |

---

## Navigation

- **Previous:** [Vision & Goals](vision-and-goals.md)
- **Next:** [Glossary](glossary.md)
