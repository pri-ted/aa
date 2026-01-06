# Taxonomy Module

> Naming convention validation and standardization.

---

## Module Overview

| Property | Value |
|----------|-------|
| **Module ID** | taxonomy |
| **Phase** | 1 (Read-Only) |
| **Required Dependencies** | DSP Connection |
| **Optional Dependencies** | None |

---

## Purpose

The Taxonomy module enforces consistent naming conventions across campaigns, ad groups, and creatives. It validates names against organizational patterns, extracts metadata from structured names, and identifies inconsistencies.

---

## Naming Pattern Definition

### Pattern Syntax
```
{client}_{campaign_type}_{geo}_{channel}_{date}_{version}

Where:
  {client}        = 3-letter client code (e.g., ACM)
  {campaign_type} = awareness|consideration|conversion
  {geo}           = 2-letter country code (e.g., US, UK)
  {channel}       = display|video|native|audio
  {date}          = YYYYMM format
  {version}       = v1, v2, etc.

Example: ACM_awareness_US_display_202412_v1
```

### Pattern Configuration
```yaml
taxonomy:
  name: "Campaign Naming Convention"
  entity_type: "campaign"
  
  pattern: "{client}_{type}_{geo}_{channel}_{date}_{version}"
  
  components:
    client:
      type: "code"
      length: 3
      case: "upper"
      source: "organization.client_codes"
      required: true
    
    type:
      type: "enum"
      values: ["awareness", "consideration", "conversion", "retargeting"]
      required: true
    
    geo:
      type: "code"
      length: 2
      case: "upper"
      validation: "iso_3166_alpha2"
      required: true
    
    channel:
      type: "enum"
      values: ["display", "video", "native", "audio", "ctv"]
      required: true
    
    date:
      type: "date"
      format: "YYYYMM"
      required: true
    
    version:
      type: "version"
      pattern: "v[0-9]+"
      required: false
      default: "v1"
  
  separator: "_"
  case_sensitive: false
```

---

## Validation Rules

### Validation Checks
| Check | Description | Severity |
|-------|-------------|----------|
| Pattern Match | Name matches defined pattern | Error |
| Component Valid | Each component is valid | Error |
| Case Consistency | Correct casing used | Warning |
| Separator Consistent | Correct separator used | Warning |
| No Special Chars | No invalid characters | Error |
| Length Limits | Within min/max length | Warning |

### Validation Response
```json
{
  "name": "ACM_awareness_US_display_202412",
  "valid": true,
  "score": 95,
  "parsed": {
    "client": "ACM",
    "type": "awareness",
    "geo": "US",
    "channel": "display",
    "date": "202412",
    "version": null
  },
  "warnings": [
    {
      "type": "missing_version",
      "message": "Version component missing, defaulting to v1",
      "suggestion": "ACM_awareness_US_display_202412_v1"
    }
  ],
  "errors": []
}
```

---

## Auto-Correction

### Correction Rules
```yaml
auto_correct:
  enabled: true
  
  rules:
    - type: "case_fix"
      description: "Fix component casing"
      example: "acm_Awareness_us → ACM_awareness_US"
    
    - type: "separator_fix"
      description: "Standardize separators"
      example: "ACM-awareness-US → ACM_awareness_US"
    
    - type: "whitespace_fix"
      description: "Remove extra whitespace"
      example: "ACM _ awareness → ACM_awareness"
    
    - type: "component_expand"
      description: "Expand abbreviations"
      example: "disp → display"
  
  confidence_threshold: 0.9
  require_approval: true
```

### Suggestion API
```json
{
  "original": "acme awareness US display dec24",
  "suggestions": [
    {
      "corrected": "ACM_awareness_US_display_202412_v1",
      "confidence": 0.92,
      "changes": [
        "Mapped 'acme' to client code 'ACM'",
        "Lowercased 'awareness'",
        "Converted 'dec24' to '202412'",
        "Added separator '_'",
        "Added default version 'v1'"
      ]
    }
  ]
}
```

---

## Metadata Extraction

Extract structured data from validated names:

```yaml
# Input: ACM_conversion_UK_video_202412_v2

extracted:
  client_code: "ACM"
  client_name: "Acme Corporation"  # Looked up from org config
  campaign_type: "conversion"
  objective: "lower_funnel"        # Derived from type
  country: "UK"
  country_name: "United Kingdom"
  region: "EMEA"                   # Derived from country
  channel: "video"
  media_type: "digital_video"      # Derived from channel
  flight_month: "2024-12"
  flight_quarter: "Q4 2024"
  version: 2
```

---

## Entity Hierarchies

### Cascading Patterns
```yaml
hierarchies:
  campaign:
    pattern: "{client}_{type}_{geo}_{channel}_{date}_{version}"
  
  insertion_order:
    pattern: "{campaign}_{tactic}_{audience}"
    inherits_from: "campaign"
  
  line_item:
    pattern: "{insertion_order}_{creative_type}_{size}"
    inherits_from: "insertion_order"
  
  creative:
    pattern: "{line_item}_{creative_id}"
    inherits_from: "line_item"
```

### Example Hierarchy
```
Campaign:       ACM_awareness_US_display_202412_v1
  └─ IO:        ACM_awareness_US_display_202412_v1_prospecting_inmarket
      └─ LI:    ACM_awareness_US_display_202412_v1_prospecting_inmarket_static_300x250
          └─ Creative: ACM_awareness_US_display_202412_v1_prospecting_inmarket_static_300x250_001
```

---

## Bulk Validation

### Batch Validation Request
```json
{
  "entity_type": "campaign",
  "names": [
    "ACM_awareness_US_display_202412_v1",
    "acme brand campaign",
    "XYZ_conversion_UK_video"
  ]
}
```

### Batch Validation Response
```json
{
  "summary": {
    "total": 3,
    "valid": 1,
    "invalid": 1,
    "correctable": 1
  },
  "results": [
    {
      "name": "ACM_awareness_US_display_202412_v1",
      "status": "valid",
      "score": 100
    },
    {
      "name": "acme brand campaign",
      "status": "invalid",
      "score": 15,
      "errors": ["Does not match pattern"]
    },
    {
      "name": "XYZ_conversion_UK_video",
      "status": "correctable",
      "score": 75,
      "suggestion": "XYZ_conversion_UK_video_202412_v1"
    }
  ]
}
```

---

## Reports

### Taxonomy Compliance Report
| Metric | Value |
|--------|-------|
| Total Entities | 1,250 |
| Compliant | 1,100 (88%) |
| Non-Compliant | 150 (12%) |
| Auto-Correctable | 120 |
| Manual Review | 30 |

### Common Issues
| Issue | Count | % |
|-------|-------|---|
| Missing version | 45 | 30% |
| Wrong case | 38 | 25% |
| Invalid date format | 32 | 21% |
| Unknown client code | 20 | 13% |
| Invalid separator | 15 | 10% |

---

## Navigation

- **Up:** [Module System](../README.md)
- **Previous:** [QA Module](../qa/README.md)
