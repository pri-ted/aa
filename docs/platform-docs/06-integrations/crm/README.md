# CRM & Booking Integration

> Google Sheets and database connectors for booking and CRM data.

---

## Integration Overview

| Property | Value |
| ---------- | ------- |
| **Type** | CRM / Booking Database |
| **Auth** | OAuth 2.0 / Database credentials |
| **Sources** | Google Sheets, PostgreSQL, MySQL, Salesforce |
| **Read Support** | ✓ Production |
| **Write Support** | ✓ Production |
| **Sync Frequency** | Configurable (hourly/daily) |

---

## Supported Sources

| Source | Auth | Status |
| -------- | ------ | -------- |
| Google Sheets | OAuth 2.0 | Production |
| PostgreSQL | Connection string | Production |
| MySQL | Connection string | Production |
| Salesforce | OAuth 2.0 | Planned |
| HubSpot | API Key | Planned |

---

## Google Sheets Integration

### Authentication

```yaml
oauth:
  scopes:
    - "https://www.googleapis.com/auth/spreadsheets.readonly"
    - "https://www.googleapis.com/auth/drive.readonly"
```

### Sheet Configuration

```yaml
sheet:
  spreadsheet_id: "1BxiM..."
  sheet_name: "Bookings"
  header_row: 1
  data_start_row: 2
  
  column_mapping:
    A: "booking_id"
    B: "client_name"
    C: "campaign_name"
    D: "start_date"
    E: "end_date"
    F: "budget"
    G: "impressions_booked"
    H: "media_type"
    I: "dsp"
```

### Data Validation

```yaml
validation:
  booking_id:
    type: "string"
    required: true
    unique: true
  budget:
    type: "decimal"
    min: 0
  start_date:
    type: "date"
    format: "YYYY-MM-DD"
  end_date:
    type: "date"
    after: "start_date"
```

---

## Database Integration

### Connection Configuration

```yaml
database:
  type: "postgresql"
  host: "${DB_HOST}"
  port: 5432
  database: "bookings"
  username: "${DB_USER}"
  password: "${DB_PASSWORD}"
  ssl_mode: "require"
  
  query: |
    SELECT 
      booking_id,
      client_name,
      campaign_name,
      start_date,
      end_date,
      budget,
      impressions_booked,
      media_type,
      dsp_platform
    FROM bookings
    WHERE updated_at >= :last_sync
```

### Connection Pooling

```yaml
pool:
  min_connections: 2
  max_connections: 10
  idle_timeout: 300
  max_lifetime: 3600
```

---

## Data Schema

### Booking Record

```yaml
booking:
  booking_id: "string (PK)"
  client_id: "string (FK)"
  client_name: "string"
  campaign_name: "string"
  campaign_id: "string (nullable)"  # DSP campaign ID
  
  # Flight dates
  start_date: "date"
  end_date: "date"
  
  # Financial
  budget: "decimal"
  currency: "string (default: USD)"
  margin_target: "decimal (nullable)"
  
  # Delivery
  impressions_booked: "bigint (nullable)"
  clicks_booked: "bigint (nullable)"
  conversions_booked: "bigint (nullable)"
  
  # Metadata
  media_type: "enum (display, video, native, audio)"
  dsp_platform: "enum (DV360, TTD, Meta, GoogleAds)"
  
  # Tracking
  created_at: "timestamp"
  updated_at: "timestamp"
  synced_at: "timestamp"
```

### Client Record

```yaml
client:
  client_id: "string (PK)"
  client_name: "string"
  client_code: "string (3 chars)"
  industry: "string"
  tier: "enum (enterprise, growth, starter)"
  account_manager: "string"
  
  # Contacts
  primary_contact_email: "string"
  billing_email: "string"
  
  # Settings
  default_currency: "string"
  timezone: "string"
```

---

## Sync Process

### Sync Flow

```text
┌─────────────┐     ┌──────────────┐     ┌─────────────┐
│   Source    │ ──▶ │   Extract    │ ──▶ │  Validate   │
│ (Sheet/DB)  │     │    Data      │     │   & Clean   │
└─────────────┘     └──────────────┘     └─────────────┘
                                               │
                                               ▼
┌─────────────┐     ┌──────────────┐     ┌─────────────┐
│   Match     │ ◀── │   Dedupe     │ ◀── │  Transform  │
│ to Campaigns│     │              │     │             │
└─────────────┘     └──────────────┘     └─────────────┘
       │
       ▼
┌─────────────┐
│   Store     │
│ (Silver DB) │
└─────────────┘
```

### Sync Modes

| Mode | Description | Use Case |
| ------ | ------------- | ---------- |
| Full | Re-sync all records | Initial load, recovery |
| Incremental | Only changed records | Scheduled sync |
| Real-time | Webhook/trigger | Time-sensitive |

---

## Campaign Matching

### Matching Rules

```yaml
matching:
  strategies:
    - type: "exact_id"
      source: "booking.campaign_id"
      target: "campaign.id"
      priority: 1
    
    - type: "name_match"
      source: "booking.campaign_name"
      target: "campaign.name"
      algorithm: "fuzzy"
      threshold: 0.85
      priority: 2
    
    - type: "composite"
      rules:
        - field: "client_name"
          match: "advertiser_name"
        - field: "start_date"
          tolerance: "7d"
      priority: 3
  
  on_no_match: "create_unmatched_record"
  on_multiple_match: "flag_for_review"
```

### Match Status

| Status | Description |
| -------- | ------------- |
| matched | Exact or confident match |
| probable | Fuzzy match (review) |
| unmatched | No match found |
| multiple | Multiple matches (review) |

---

## Write-Back (Bidirectional Sync)

### Supported Updates

| Field | Direction | Trigger |
| ------- | ----------- | --------- |
| actual_spend | Platform → CRM | Daily |
| pacing_status | Platform → CRM | Hourly |
| campaign_status | CRM ↔ Platform | On change |
| campaign_id | Platform → CRM | On match |

### Write-Back Configuration

```yaml
write_back:
  enabled: true
  
  fields:
    - source: "gold.pacing_snapshots.actual_spend"
      target: "bookings.actual_spend"
      frequency: "daily"
    
    - source: "gold.pacing_snapshots.pacing_rate"
      target: "bookings.pacing_percent"
      frequency: "hourly"
  
  conflict_resolution: "platform_wins"
  audit_trail: true
```

---

## Error Handling

| Error | Cause | Action |
| ------- | ------- | -------- |
| Connection failed | Network/auth | Retry with backoff |
| Schema mismatch | Columns changed | Alert, pause sync |
| Validation failed | Bad data | Log, skip record |
| Rate limited | API limits | Queue requests |

---

## Configuration

```yaml
crm:
  sync:
    schedule: "0 * * * *"  # Hourly
    batch_size: 1000
    timeout: 300
  
  google_sheets:
    credentials: "${GOOGLE_CREDENTIALS}"
    rate_limit: 100  # per 100 seconds
  
  database:
    pool_size: 10
    statement_timeout: 30
  
  matching:
    fuzzy_threshold: 0.85
    max_manual_review: 100
```

---

## Navigation

- **Up:** [Integration Layer](../README.md)
- **Previous:** [Google Ads Integration](../google-ads/README.md)
