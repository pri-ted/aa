# Calculation Engine

> Formula evaluation and JIT compilation.

---

## Service Overview

| Property | Value |
| ---------- | ------- |
| **Language** | Rust |
| **Framework** | Actix-web |
| **Storage** | Redis (cache) |
| **Port** | 8008 |
| **gRPC Port** | 9008 |
| **Replicas** | 3 |
| **Owner** | Platform Team |

---

## Responsibilities

1. **Formula Parsing** - Parse user-defined formulas
2. **JIT Compilation** - Compile formulas for performance
3. **Execution** - Evaluate formulas against data
4. **Caching** - Cache compiled formulas
5. **Validation** - Validate formula syntax

---

## Supported Operations

### Arithmetic

| Operator | Example |
| ---------- | --------- |
| + | `spend + fees` |
| - | `revenue - cost` |
| * | `impressions * cpm / 1000` |
| / | `clicks / impressions` |
| % | `margin % 10` |

### Comparison

| Operator | Example |
| ---------- | --------- |
| > | `pacing_rate > 100` |
| < | `days_remaining < 5` |
| >= | `margin >= 20` |
| <= | `spend <= budget` |
| == | `status == 'active'` |
| != | `dsp != 'DV360'` |

### Logical

| Operator | Example |
| ---------- | --------- |
| AND | `pacing > 100 AND days < 5` |
| OR | `status == 'paused' OR spend == 0` |
| NOT | `NOT is_premium` |

### Functions

| Function | Example |
| ---------- | --------- |
| IF | `IF(pacing > 100, 'over', 'under')` |
| CASE | `CASE WHEN pacing > 120 THEN 'critical' WHEN pacing > 100 THEN 'warning' ELSE 'ok' END` |
| COALESCE | `COALESCE(margin, 0)` |
| ABS | `ABS(variance)` |
| ROUND | `ROUND(ctr, 4)` |
| MIN/MAX | `MAX(spend, budget)` |

---

## API Endpoints

### POST /api/v1/calculate/evaluate

Evaluate formula against data.

**Request:**

```json
{
  "formula": "(delivered / booked) * (total_days / elapsed_days) * 100",
  "variables": {
    "delivered": 50000,
    "booked": 100000,
    "total_days": 30,
    "elapsed_days": 15
  }
}
```

**Response (200):**

```json
{
  "result": 100.0,
  "type": "float",
  "execution_time_us": 45
}
```

---

### POST /api/v1/calculate/validate

Validate formula syntax.

**Request:**

```json
{
  "formula": "(revenue - cost) / revenue * 100",
  "expected_variables": ["revenue", "cost"]
}
```

**Response (200):**

```json
{
  "valid": true,
  "parsed_variables": ["revenue", "cost"],
  "return_type": "float"
}
```

---

### POST /api/v1/calculate/batch

Evaluate formula for multiple rows.

**Request:**

```json
{
  "formula": "impressions * cpm / 1000",
  "data": [
    {"impressions": 100000, "cpm": 5.0},
    {"impressions": 50000, "cpm": 7.5}
  ]
}
```

**Response (200):**

```json
{
  "results": [500.0, 375.0],
  "execution_time_us": 120
}
```

---

## Formula Compilation

```rust
// Parsed AST
Formula {
    expression: BinaryOp {
        left: Variable("revenue"),
        op: Subtract,
        right: Variable("cost")
    }
}

// Compiled to native code using Cranelift
fn compiled_formula(ctx: &Context) -> f64 {
    ctx.get("revenue") - ctx.get("cost")
}
```

---

## Caching Strategy

| Cache | TTL | Purpose |
| ------- | ----- | --------- |
| Compiled formulas | 1 hour | Avoid recompilation |
| Validation results | 5 min | Quick syntax checks |

---

## Configuration

```yaml
calculation:
  cache:
    compiled_ttl: 3600
    validation_ttl: 300
  limits:
    max_formula_length: 10000
    max_variables: 100
    max_nesting_depth: 20
    execution_timeout_ms: 1000
```

---

## Navigation

- **Up:** [Service Catalog](../README.md)
- **Previous:** [Gold Service](../gold/README.md)
- **Next:** [Rule Engine](../rule-engine/README.md)
  