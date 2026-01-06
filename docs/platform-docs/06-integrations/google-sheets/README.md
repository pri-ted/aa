# Google Sheets Integration

> Import booking/deal data from Google Sheets for organizations without dedicated CRM.

---

## Overview

| Property | Value |
| ---------- | ------- |
| **Connector Type** | GOOGLE_SHEETS |
| **Authentication** | OAuth 2.0 |
| **Sync Frequency** | Hourly (configurable) |
| **Direction** | Read-only (Phase 1), Read-Write (Phase 2) |
| **Use Case** | Small/medium orgs without CRM |

---

## OAuth Configuration

### Required Scopes

```yaml
scopes:
  - https://www.googleapis.com/auth/spreadsheets.readonly
  - https://www.googleapis.com/auth/drive.readonly
```

### OAuth Flow

1. User initiates connection from Settings → Integrations
2. Redirect to Google OAuth consent screen
3. User grants read access to Sheets
4. Callback with authorization code
5. Exchange code for tokens
6. Encrypt and store tokens

---

## Expected Sheet Format

### Sheet Name

Configurable per organization, default: `Bookings`

### Required Columns

| Column | Header | Type | Required | Example |
| -------- | -------- | ------ | ---------- | --------- |
| A | Deal ID | String | Yes | `DEAL-2024-001` |
| B | Client Name | String | Yes | `Acme Corp` |
| C | Campaign Name | String | Yes | `Q1 Brand Campaign` |
| D | DSP | Enum | Yes | `DV360`, `TTD`, `Meta` |
| E | DSP Campaign ID | String | No | `123456789` |
| F | Start Date | Date | Yes | `2024-01-15` |
| G | End Date | Date | Yes | `2024-03-31` |
| H | Booked Amount | Number | Yes | `50000` |
| I | Currency | String | Yes | `USD` |
| J | Buy Model | Enum | Yes | `CPM`, `CPC`, `CPA`, `CPV`, `Fixed` |
| K | Rate | Number | No | `5.50` |
| L | Booked Quantity | Number | No | `9090909` |
| M | Trader | String | No | `John Smith` |
| N | Status | Enum | No | `Active`, `Completed`, `Cancelled` |

### Optional Columns

| Column | Header | Type | Purpose |
| -------- | -------- | ------ | --------- |
| O | Advertiser | String | Advertiser name for matching |
| P | Margin % | Number | Expected margin percentage |
| Q | Notes | String | Free-text notes |

---

## Date Formats

Supported date formats (auto-detected):

```yaml
formats:
  - YYYY-MM-DD     # 2024-01-15 (preferred)
  - MM/DD/YYYY     # 01/15/2024
  - DD/MM/YYYY     # 15/01/2024 (requires locale config)
  - MMMM DD, YYYY  # January 15, 2024
  - DD-MMM-YYYY    # 15-Jan-2024
```

---

## Validation Rules

### Row-Level Validation

```yaml
validations:
  - rule: "end_date >= start_date"
    error: "End date must be on or after start date"
    severity: error
    
  - rule: "booked_amount > 0"
    error: "Booked amount must be positive"
    severity: error
    
  - rule: "dsp in ['DV360', 'TTD', 'Meta', 'Google Ads']"
    error: "Invalid DSP value"
    severity: error
    
  - rule: "buy_model in ['CPM', 'CPC', 'CPA', 'CPV', 'Fixed']"
    error: "Invalid buy model"
    severity: error
    
  - rule: "currency matches /^[A-Z]{3}$/"
    error: "Currency must be 3-letter ISO code"
    severity: error
    
  - rule: "rate > 0 when buy_model != 'Fixed'"
    error: "Rate required for non-fixed deals"
    severity: warning
```

### Sheet-Level Validation

```yaml
validations:
  - rule: "unique(deal_id)"
    error: "Duplicate Deal ID found"
    severity: error
    
  - rule: "header_row_present"
    error: "Missing header row"
    severity: error
    
  - rule: "all_required_columns_present"
    error: "Missing required columns: {columns}"
    severity: error
```

---

## Campaign Matching

### Matching Strategy

```yaml
matching:
  strategy: hierarchical
  
  steps:
    # Step 1: Exact match on DSP Campaign ID
    - name: exact_id_match
      priority: 1
      condition: dsp_campaign_id IS NOT NULL
      match_on: dsp_campaign_id = campaign.external_id
      confidence: 1.0
      
    # Step 2: Exact match on campaign name + date overlap
    - name: exact_name_match
      priority: 2
      match_on:
        - campaign_name = campaign.name
        - dsp = campaign.dsp_type
        - date_ranges_overlap(start_date, end_date, campaign.start_date, campaign.end_date)
      confidence: 0.95
      
    # Step 3: Fuzzy match on campaign name + date overlap
    - name: fuzzy_name_match
      priority: 3
      match_on:
        - levenshtein_distance(campaign_name, campaign.name) <= 3
        - dsp = campaign.dsp_type
        - date_ranges_overlap(...)
      confidence: 0.7
      
    # Step 4: Match by client + date + DSP
    - name: client_date_match
      priority: 4
      match_on:
        - client_name = campaign.advertiser_name
        - dsp = campaign.dsp_type
        - date_ranges_overlap(...)
      confidence: 0.5
      
  unmatched_handling: create_orphan_deal
  min_confidence_threshold: 0.5
```

### Match Review

Matches below 0.9 confidence are flagged for manual review:

```json
{
  "deal_id": "DEAL-2024-001",
  "deal_campaign_name": "Q1 Brand Campaign",
  "matched_campaign": {
    "id": "camp_123",
    "name": "Q1 Brand - DV360",
    "confidence": 0.72,
    "match_reason": "fuzzy_name_match"
  },
  "alternatives": [
    {
      "id": "camp_456",
      "name": "Q1 Branding",
      "confidence": 0.65
    }
  ],
  "requires_review": true
}
```

---

## Sync Process

### Sync Workflow

```text
┌─────────────────────────────────────────────────────────────────────────────┐
│                        GOOGLE SHEETS SYNC FLOW                              │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│   ┌─────────┐    ┌─────────┐    ┌─────────┐    ┌─────────┐    ┌─────────┐.  │
│   │  Fetch  │───▶│ Validate│───▶│  Match  │───▶│ Upsert  │───▶│ Notify  │   │
│   │  Sheet  │    │  Rows   │    │Campaigns│    │  Deals  │    │ Issues  │   │
│   └─────────┘    └─────────┘    └─────────┘    └─────────┘    └─────────┘   │
│       │              │              │              │              │         │
│       ▼              ▼              ▼              ▼              ▼         │
│   Sheets API    Row errors    Match results   DB update    Email/Slack      │
│                 skipped       with confidence               if errors        │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Sync Steps

1. **Fetch Sheet Data**
   - Call Google Sheets API
   - Read all rows from configured sheet
   - Parse headers and detect columns

2. **Validate Rows**
   - Apply validation rules
   - Skip invalid rows (log errors)
   - Continue with valid rows

3. **Match Campaigns**
   - For each deal, attempt campaign matching
   - Calculate match confidence
   - Flag low-confidence matches

4. **Upsert Deals**
   - Insert new deals
   - Update existing deals (by deal_id)
   - Soft-delete removed deals

5. **Notify Issues**
   - Send notification if validation errors
   - Send notification if unmatched deals > threshold

---

## API Endpoints

### GET /api/v1/integrations/google-sheets/status

```json
{
  "connected": true,
  "last_sync_at": "2024-12-26T10:00:00Z",
  "next_sync_at": "2024-12-26T11:00:00Z",
  "spreadsheet": {
    "id": "1BxiMVs0XRA5nFMdKvBdBZjgmUUqptlbs74OgvE2upms",
    "name": "Campaign Bookings 2024",
    "sheet_name": "Bookings"
  },
  "stats": {
    "total_deals": 45,
    "matched_deals": 42,
    "unmatched_deals": 3,
    "validation_errors": 1
  }
}
```

### POST /api/v1/integrations/google-sheets/sync

Trigger manual sync.

```json
{
  "sync_id": "sync_abc123",
  "status": "started",
  "estimated_duration_seconds": 30
}
```

### GET /api/v1/integrations/google-sheets/sync/{sync_id}

```json
{
  "sync_id": "sync_abc123",
  "status": "completed",
  "started_at": "2024-12-26T10:00:00Z",
  "completed_at": "2024-12-26T10:00:28Z",
  "results": {
    "rows_processed": 47,
    "rows_valid": 45,
    "rows_skipped": 2,
    "deals_created": 5,
    "deals_updated": 38,
    "deals_deleted": 2,
    "campaigns_matched": 42
  },
  "errors": [
    {
      "row": 12,
      "deal_id": "DEAL-2024-XXX",
      "error": "Invalid date format in End Date"
    }
  ]
}
```

### POST /api/v1/integrations/google-sheets/match-review

Submit manual match review.

```json
{
  "reviews": [
    {
      "deal_id": "DEAL-2024-001",
      "action": "confirm",
      "campaign_id": "camp_123"
    },
    {
      "deal_id": "DEAL-2024-002",
      "action": "select_alternative",
      "campaign_id": "camp_456"
    },
    {
      "deal_id": "DEAL-2024-003",
      "action": "create_unmatched"
    }
  ]
}
```

---

## Configuration

### Organization Settings

```json
{
  "google_sheets": {
    "enabled": true,
    "spreadsheet_id": "1BxiMVs0XRA5nFMdKvBdBZjgmUUqptlbs74OgvE2upms",
    "sheet_name": "Bookings",
    "sync_frequency_minutes": 60,
    "header_row": 1,
    "data_start_row": 2,
    "column_mapping": {
      "deal_id": "A",
      "client_name": "B",
      "campaign_name": "C",
      "dsp": "D",
      "dsp_campaign_id": "E",
      "start_date": "F",
      "end_date": "G",
      "booked_amount": "H",
      "currency": "I",
      "buy_model": "J",
      "rate": "K",
      "booked_quantity": "L",
      "trader": "M",
      "status": "N"
    },
    "date_format": "auto",
    "locale": "en-US",
    "notifications": {
      "on_sync_error": true,
      "on_unmatched_deals": true,
      "unmatched_threshold": 5
    }
  }
}
```

---

## Error Handling

| Error | Action | Retry |
| ------- | -------- | ------- |
| `401 Unauthorized` | Token refresh | Yes |
| `403 Forbidden` | Notify user to re-auth | No |
| `404 Spreadsheet Not Found` | Disable sync, notify | No |
| `429 Rate Limited` | Exponential backoff | Yes |
| `500 Server Error` | Retry with backoff | Yes (3x) |
| Validation Error | Skip row, log | N/A |

---

## Security

- OAuth tokens encrypted at rest (AES-256-GCM)
- Tokens stored in Vault
- Read-only scope requested
- Refresh tokens rotated on use
- Access revocable by user

---

## Navigation

- **Up:** [Integrations](../README.md)
- **Previous:** [CRM Integration](../crm/README.md)
