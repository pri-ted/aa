# API Specifications

> Complete REST and GraphQL API reference.

---

## API Overview

| Type    | Base URL   | Auth       | Format   |
| ------- | ---------- | ---------- | -------- |
| REST    | `/api/v1`  | Bearer JWT | JSON     |
| GraphQL | `/graphql` | Bearer JWT | GraphQL  |
| gRPC    | Internal   | mTLS       | Protobuf |

---

## Authentication APIs

### POST /api/v1/auth/login

**Description:** Authenticate user and get refresh token.

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
  "refresh_token": "eyJ...",
  "user": {
    "id": 123,
    "email": "user@example.com",
    "full_name": "John Doe",
    "organizations": [{ "id": 456, "name": "Acme Corp", "role": "admin" }]
  }
}
```

**Errors:**

| Code | Description         |
| ---- | ------------------- |
| 401  | Invalid credentials |
| 429  | Too many attempts   |

---

### POST /api/v1/auth/select-org

**Description:** Select organization and get access token.

**Headers:**

```code
Authorization: Bearer <refresh_token>
```

**Request:**

```json
{
  "org_id": 456
}
```

**Response (200):**

```json
{
  "access_token": "eyJ...",
  "expires_in": 3600,
  "organization": {
    "id": 456,
    "name": "Acme Corp",
    "enabled_modules": ["pacing", "qa"],
    "connected_dsps": ["DV360", "TTD"]
  },
  "permissions": ["read:campaigns", "write:pipelines"]
}
```

---

### POST /api/v1/auth/refresh

**Description:** Refresh access token.

**Headers:**

```code
Authorization: Bearer <refresh_token>
```

**Response (200):**

```json
{
  "access_token": "eyJ...",
  "expires_in": 3600
}
```

---

## Configuration APIs

### GET /api/v1/config/pipelines

**Description:** List pipelines for current organization.

**Query Parameters:**

| Param  | Type   | Default | Description      |
| ------ | ------ | ------- | ---------------- |
| page   | int    | 1       | Page number      |
| limit  | int    | 20      | Items per page   |
| status | string | -       | Filter by status |

**Response (200):**

```json
{
  "pipelines": [
    {
      "id": "pipe_123",
      "name": "DV360 Daily Reports",
      "connector_type": "DV360",
      "status": "active",
      "schedule": {
        "type": "cron",
        "expression": "0 6 * * *"
      },
      "last_run_at": "2024-12-24T06:00:00Z",
      "next_run_at": "2024-12-25T06:00:00Z"
    }
  ],
  "pagination": {
    "total": 45,
    "page": 1,
    "limit": 20
  }
}
```

---

### POST /api/v1/config/pipelines

**Description:** Create new pipeline.

**Request:**

```json
{
  "name": "DV360 Hourly Refresh",
  "connector_type": "DV360",
  "template_id": "tmpl_dv360_standard",
  "schedule": {
    "type": "cron",
    "expression": "0 * * * *"
  },
  "config": {
    "account_id": "dsp_acc_456",
    "metrics": ["impressions", "clicks"],
    "date_range": "last_7_days"
  }
}
```

**Response (201):**

```json
{
  "id": "pipe_789",
  "message": "Pipeline created successfully",
  "optimization": {
    "type": "similar_pipeline_detected",
    "similarity": 0.92,
    "suggestion": "Consider merging with existing pipeline"
  }
}
```

---

### POST /api/v1/config/pipelines/analyze

**Description:** Analyze pipeline config before creation.

**Request:**

```json
{
  "connector_type": "DV360",
  "schedule": "0 6 * * *",
  "config": {
    "metrics": ["impressions", "clicks"]
  }
}
```

**Response (200):**

```json
{
  "validation": {
    "is_valid": true,
    "warnings": [
      {
        "field": "schedule",
        "message": "Similar pipeline runs at same time",
        "suggestion": "Consider offsetting by 1 hour"
      }
    ]
  },
  "smart_defaults": {
    "confidence": 0.89,
    "learned_from": "47 similar organizations",
    "suggestions": {
      "metrics": ["impressions", "clicks", "conversions", "ctr"]
    }
  },
  "estimated_cost": {
    "monthly": 12.5,
    "currency": "USD"
  }
}
```

---

## Rules APIs

### GET /api/v1/rules

**Description:** List rules for current organization.

**Query Parameters:**

| Param   | Type    | Description                             |
| ------- | ------- | --------------------------------------- |
| module  | string  | Filter by module (alerts, qa, taxonomy) |
| enabled | boolean | Filter by enabled status                |

**Response (200):**

```json
{
  "rules": [
    {
      "id": "rule_123",
      "name": "High Pacing Alert",
      "module": "alerts",
      "enabled": true,
      "conditions": {
        "operator": "AND",
        "conditions": [
          { "field": "pacing_rate", "operator": ">", "value": 120 }
        ]
      },
      "actions": [
        { "type": "alert", "severity": "warning", "channels": ["email"] }
      ]
    }
  ]
}
```

---

### POST /api/v1/rules

**Description:** Create new rule.

**Request:**

```json
{
  "name": "High Pacing Alert",
  "module": "alerts",
  "conditions": {
    "operator": "AND",
    "conditions": [
      { "field": "pacing_rate", "operator": ">", "value": 120 },
      { "field": "days_remaining", "operator": ">", "value": 3 }
    ]
  },
  "actions": [
    {
      "type": "alert",
      "severity": "warning",
      "channels": ["email", "slack"]
    }
  ]
}
```

---

### POST /api/v1/rules/{rule_id}/test

**Description:** Test rule against historical data (dry run).

**Request:**

```json
{
  "date_range": "last_7_days",
  "sample_size": 100
}
```

**Response (200):**

```json
{
  "test_results": {
    "total_evaluated": 450,
    "matches": 23,
    "sample_matches": [
      {
        "campaign_id": "123",
        "campaign_name": "Holiday Campaign",
        "matched_conditions": ["pacing_rate > 120"],
        "would_trigger": ["email_alert"]
      }
    ]
  }
}
```

---

## Permissions APIs

### GET /api/v1/permissions/check

**Description:** Check if current user has permission.

**Query Parameters:**

| Param       | Type   | Required |
| ----------- | ------ | -------- |
| entity_type | string | Yes      |
| entity_id   | string | Yes      |
| permission  | string | Yes      |

**Response (200):**

```json
{
  "has_permission": true,
  "reason": "explicit_grant",
  "details": {
    "granted_by": "user_456",
    "granted_at": "2024-12-20T10:00:00Z"
  }
}
```

---

### POST /api/v1/permissions/grant

**Description:** Grant permission to user.

**Request:**

```json
{
  "user_id": 789,
  "entity_type": "dsp_account",
  "entity_id": "dsp_acc_456",
  "permissions": ["view", "execute"]
}
```

---

## GraphQL Schema

### Queries

```graphql
type Query {
  # Current user
  me: User!

  # Organizations
  organization(id: ID!): Organization

  # Campaigns
  campaigns(
    filters: CampaignFilters
    pagination: Pagination
  ): CampaignConnection!

  campaign(id: ID!): Campaign

  # Pacing
  pacingData(
    entityType: EntityType!
    entityId: ID!
    dateRange: DateRange!
  ): PacingData!

  # Alerts
  alerts(filters: AlertFilters, pagination: Pagination): AlertConnection!
}
```

### Mutations

```graphql
type Mutation {
  # Pipelines
  createPipeline(input: CreatePipelineInput!): Pipeline!
  updatePipeline(id: ID!, input: UpdatePipelineInput!): Pipeline!
  deletePipeline(id: ID!): Boolean!

  # Rules
  createRule(input: CreateRuleInput!): Rule!
  updateRule(id: ID!, input: UpdateRuleInput!): Rule!
  toggleRule(id: ID!, enabled: Boolean!): Rule!

  # DSP Accounts
  connectDSP(input: ConnectDSPInput!): DSPAccount!
  disconnectDSP(id: ID!): Boolean!
}
```

### Subscriptions

```graphql
type Subscription {
  # Real-time alerts
  alertTriggered(ruleIds: [ID!]): Alert!

  # Pipeline status
  pipelineStatusChanged(pipelineId: ID!): PipelineStatus!
}
```

---

## Error Codes

| Code     | HTTP Status | Description              |
| -------- | ----------- | ------------------------ |
| AUTH_001 | 401         | Invalid credentials      |
| AUTH_002 | 401         | Token expired            |
| AUTH_003 | 403         | Insufficient permissions |
| CONF_001 | 400         | Invalid configuration    |
| CONF_002 | 404         | Pipeline not found       |
| CONF_003 | 409         | Duplicate pipeline       |
| RATE_001 | 429         | Rate limit exceeded      |
| INT_001  | 500         | Internal server error    |

---

## Rate Limits

| Tier       | Requests/Minute | Burst |
| ---------- | --------------- | ----- |
| Free       | 100             | 150   |
| Premium    | 1000            | 1500  |
| Enterprise | 10000           | 15000 |

**Headers Returned:**

```code
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 95
X-RateLimit-Reset: 1703419200
```

---

## Navigation

- **Previous:** [Database Schemas](../schemas/README.md)
- **Next:** [Iceberg Lakehouse](../lakehouse/README.md)
