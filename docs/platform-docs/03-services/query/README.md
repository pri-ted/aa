# Query Service (GraphQL Gateway)

> Unified API gateway with GraphQL and subscriptions.

---

## Service Overview

| Property | Value |
| ---------- | ------- |
| **Language** | TypeScript/Node.js |
| **Framework** | Apollo Server 4.x |
| **Database** | ClickHouse (read), PostgreSQL (via services) |
| **Port** | 8010 |
| **WebSocket Port** | 8010 |
| **Replicas** | 5 (scales with query load) |
| **Owner** | Full Stack Team |

---

## Responsibilities

1. **GraphQL Gateway** - Unified query interface
2. **Query Federation** - Aggregate from multiple services
3. **Real-time Subscriptions** - WebSocket updates
4. **Query Optimization** - Caching, batching
5. **Rate Limiting** - Per-org query limits

---

## GraphQL Schema

### Queries

```graphql
type Query {
  # Campaigns
  campaigns(
    filters: CampaignFilters
    pagination: PaginationInput
  ): CampaignConnection!
  
  campaign(id: ID!): Campaign
  
  # Pipelines
  pipelines(status: PipelineStatus): [Pipeline!]!
  pipeline(id: ID!): Pipeline
  
  # Rules
  rules(type: RuleType): [Rule!]!
  rule(id: ID!): Rule
  
  # Analytics
  dashboardMetrics(dateRange: DateRangeInput!): DashboardMetrics!
  pipelineHealth: PipelineHealthSummary!
  costSummary: CostSummary!
}
```

### Mutations

```graphql
type Mutation {
  # Pipelines
  createPipeline(input: CreatePipelineInput!): CreatePipelinePayload!
  updatePipeline(id: ID!, input: UpdatePipelineInput!): Pipeline!
  deletePipeline(id: ID!): DeletePayload!
  triggerPipeline(id: ID!): Execution!
  
  # Rules
  createRule(input: CreateRuleInput!): Rule!
  updateRule(id: ID!, input: UpdateRuleInput!): Rule!
  testRule(id: ID!, input: TestRuleInput!): TestRulePayload!
  toggleRule(id: ID!, enabled: Boolean!): Rule!
  
  # Connectors
  connectDSP(input: ConnectDSPInput!): Connector!
  disconnectDSP(id: ID!): Boolean!
}
```

### Subscriptions

```graphql
type Subscription {
  # Real-time updates
  pipelineExecutionUpdated(pipelineId: ID!): ExecutionUpdate!
  ruleTriggered(ruleId: ID): RuleMatch!
  costAlertTriggered: CostAlert!
  dataRefreshed(entityType: String!): DataRefreshEvent!
}
```

---

## Types

### Campaign

```graphql
type Campaign {
  id: ID!
  name: String!
  status: CampaignStatus!
  dsp: String!
  advertiserId: String!
  advertiserName: String
  budget: Budget
  dateRange: DateRange
  metrics: CampaignMetrics!
  pacing: PacingMetrics
  alerts: [Alert!]!
  createdAt: DateTime!
  updatedAt: DateTime!
}

type CampaignMetrics {
  impressions: BigInt!
  clicks: BigInt!
  conversions: BigInt!
  spend: Float!
  cpm: Float
  ctr: Float
  cvr: Float
}

type PacingMetrics {
  pacingRate: Float!
  deliveredAmount: Float!
  bookedAmount: Float!
  daysElapsed: Int!
  daysRemaining: Int!
  projectedSpend: Float
  status: PacingStatus!
}
```

### Pipeline

```graphql
type Pipeline {
  id: ID!
  name: String!
  connectorType: String!
  status: PipelineStatus!
  schedule: Schedule!
  config: JSON!
  health: PipelineHealth
  lastExecution: Execution
  executions(limit: Int = 10): [Execution!]!
  createdAt: DateTime!
  updatedAt: DateTime!
}

type PipelineHealth {
  status: HealthStatus!
  uptime7d: Float!
  successRate7d: Float!
  avgDurationMs: Int!
  issues: [Issue!]!
  recommendations: [Recommendation!]!
}

type Execution {
  id: ID!
  status: ExecutionStatus!
  progress: Int!
  layers: LayerStatus!
  recordsProcessed: BigInt
  duration: Int
  startedAt: DateTime!
  completedAt: DateTime
  error: String
}
```

### Rule

```graphql
type Rule {
  id: ID!
  name: String!
  type: RuleType!
  enabled: Boolean!
  conditions: JSON!
  actions: [RuleAction!]!
  schedule: String
  executions(limit: Int = 10): [RuleExecution!]!
  statistics: RuleStatistics!
  createdAt: DateTime!
  updatedAt: DateTime!
}

type RuleStatistics {
  totalExecutions: Int!
  totalMatches: Int!
  avgMatchesPerExecution: Float!
  last7Days: RuleStats7d!
}
```

---

## Input Types

```graphql
input CampaignFilters {
  dsp: [String!]
  status: [CampaignStatus!]
  advertiserId: String
  search: String
  dateRange: DateRangeInput
  pacingStatus: [PacingStatus!]
}

input CreatePipelineInput {
  name: String!
  connectorType: String!
  templateId: ID
  schedule: ScheduleInput!
  config: JSON!
}

input CreateRuleInput {
  name: String!
  type: RuleType!
  conditions: JSON!
  actions: [RuleActionInput!]!
  schedule: String
}

input DateRangeInput {
  start: Date!
  end: Date!
}

input PaginationInput {
  first: Int
  after: String
  last: Int
  before: String
}
```

---

## Enums

```graphql
enum PipelineStatus {
  ACTIVE
  PAUSED
  FAILED
}

enum ExecutionStatus {
  PENDING
  RUNNING
  COMPLETED
  FAILED
}

enum RuleType {
  ALERT
  QA_CHECK
  TAXONOMY
}

enum PacingStatus {
  ON_TRACK
  UNDER_PACING
  OVER_PACING
  CRITICAL
}

enum HealthStatus {
  HEALTHY
  DEGRADED
  FAILING
}

enum CampaignStatus {
  ACTIVE
  PAUSED
  COMPLETED
  DELETED
}
```

---

## Query Examples

### Get Campaigns with Pacing

```graphql
query GetCampaigns($filters: CampaignFilters!) {
  campaigns(filters: $filters, pagination: { first: 20 }) {
    edges {
      node {
        id
        name
        status
        metrics {
          impressions
          spend
        }
        pacing {
          pacingRate
          status
          daysRemaining
        }
      }
    }
    pageInfo {
      hasNextPage
      endCursor
    }
  }
}
```

### Subscribe to Pipeline Updates

```graphql
subscription WatchPipeline($pipelineId: ID!) {
  pipelineExecutionUpdated(pipelineId: $pipelineId) {
    executionId
    status
    progress
    currentLayer
    recordsProcessed
  }
}
```

---

## Data Loaders

```typescript
// Batch load campaigns by ID
const campaignLoader = new DataLoader<string, Campaign>(
  async (ids) => {
    const campaigns = await clickhouse.query(
      `SELECT * FROM campaigns WHERE id IN (${ids.join(',')})`
    );
    return ids.map(id => campaigns.find(c => c.id === id));
  }
);

// Batch load pacing metrics
const pacingLoader = new DataLoader<string, PacingMetrics>(
  async (campaignIds) => {
    const pacing = await clickhouse.query(
      `SELECT * FROM pacing_snapshots 
       WHERE campaign_id IN (${campaignIds.join(',')})
       ORDER BY snapshot_time DESC`
    );
    return campaignIds.map(id => pacing.find(p => p.campaign_id === id));
  }
);
```

---

## Configuration

```yaml
query:
  apollo:
    introspection: true
    playground: true
  cache:
    ttl: 60s
    max_size: 1000
  rate_limit:
    queries_per_minute: 100
    complexity_limit: 1000
  subscriptions:
    keep_alive: 30s
    max_connections: 10000
```

---

## Performance

| Metric | Target | Current |
| -------- | -------- | --------- |
| Query latency (p50) | <50ms | 35ms |
| Query latency (p99) | <200ms | 150ms |
| Subscription latency | <100ms | 80ms |
| Cache hit rate | >80% | 85% |

---

## Navigation

- **Up:** [Service Catalog](../README.md)
- **Previous:** [Notification Service](../notification/README.md)
