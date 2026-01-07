# Sample Data ER Diagram
## Campaign Lifecycle Platform - Seed Data Relationships

---

## Sample Data Entity Map

This diagram shows the **actual seed data instances** and how they relate to each other.

```mermaid
erDiagram
    %% Organizations
    ORG_ACME ||--o{ USER_ALICE : "admin"
    ORG_ACME ||--o{ USER_BOB : "developer"
    ORG_ACME ||--o{ USER_CAROL : "analyst"
    ORG_ACME ||--o{ DSP_ACME_DV360 : "owns"
    ORG_ACME ||--o{ DSP_ACME_META : "owns"
    ORG_ACME ||--o{ DSP_ACME_TTD : "owns"
    
    ORG_GLOBEX ||--o{ USER_DAVID : "admin"
    ORG_GLOBEX ||--o{ USER_EVE : "developer"
    ORG_GLOBEX ||--o{ USER_FRANK : "viewer"
    ORG_GLOBEX ||--o{ DSP_GLOBEX_DV360 : "owns"
    ORG_GLOBEX ||--o{ DSP_GLOBEX_GADS : "owns"
    
    ORG_INITECH ||--o{ USER_GRACE : "admin"
    ORG_INITECH ||--o{ USER_HENRY : "analyst"
    ORG_INITECH ||--o{ DSP_INITECH_META : "owns"
    
    %% DSP Accounts to Campaigns
    DSP_ACME_DV360 ||--o{ CAMP_ACME_PROSP : "contains"
    DSP_ACME_DV360 ||--o{ CAMP_ACME_RETARG : "contains"
    DSP_ACME_META ||--o{ CAMP_ACME_HOLIDAY : "contains"
    DSP_GLOBEX_DV360 ||--o{ CAMP_GLOBEX_LAUNCH : "contains"
    DSP_INITECH_META ||--o{ CAMP_INITECH_LEADGEN : "contains"
    
    %% Campaigns to Metrics
    CAMP_ACME_PROSP ||--o{ METRICS_PROSP_7D : "7 days"
    CAMP_ACME_RETARG ||--o{ METRICS_RETARG_7D : "7 days"
    CAMP_GLOBEX_LAUNCH ||--o{ METRICS_LAUNCH_7D : "7 days"
    CAMP_INITECH_LEADGEN ||--o{ METRICS_LEADGEN_7D : "7 days"
    
    %% Templates to Pipelines
    TMPL_DV360_DAILY ||--o{ PIPE_ACME_DV360 : "instantiates"
    TMPL_DV360_DAILY ||--o{ PIPE_GLOBEX_DV360 : "instantiates"
    TMPL_META_INSIGHTS ||--o{ PIPE_ACME_META : "instantiates"
    TMPL_META_INSIGHTS ||--o{ PIPE_INITECH_META : "instantiates"
    
    %% DSP Accounts to Pipelines
    DSP_ACME_DV360 ||--o{ PIPE_ACME_DV360 : "sources"
    DSP_ACME_META ||--o{ PIPE_ACME_META : "sources"
    DSP_ACME_TTD ||--o{ PIPE_ACME_TTD : "sources"
    DSP_GLOBEX_DV360 ||--o{ PIPE_GLOBEX_DV360 : "sources"
    DSP_INITECH_META ||--o{ PIPE_INITECH_META : "sources"
    
    %% Pipelines to Executions
    PIPE_ACME_DV360 ||--o{ EXEC_ACME_SUCCESS : "runs"
    PIPE_ACME_META ||--o{ EXEC_ACME_FAILED : "runs"
    PIPE_GLOBEX_DV360 ||--o{ EXEC_GLOBEX_RUNNING : "runs"
    
    %% Executions to DQ Metrics
    EXEC_ACME_SUCCESS ||--o{ DQ_BRONZE : "measures"
    EXEC_ACME_SUCCESS ||--o{ DQ_SILVER : "measures"
    
    %% Rules
    ORG_ACME ||--o{ RULE_HIGH_PACING : "defines"
    ORG_ACME ||--o{ RULE_LOW_CTR : "defines"
    ORG_ACME ||--o{ RULE_NAMING : "defines"
    ORG_GLOBEX ||--o{ RULE_OVERSPEND : "defines"
    ORG_INITECH ||--o{ RULE_DAILY_SPEND : "defines"
    
    PIPE_ACME_DV360 ||--o{ RULE_HIGH_PACING : "applies"
    PIPE_ACME_DV360 ||--o{ RULE_LOW_CTR : "applies"
    
    %% Notifications
    RULE_HIGH_PACING ||--o{ NOTIF_PACING_SENT : "triggered"
    RULE_LOW_CTR ||--o{ NOTIF_CTR_FAILED : "triggered"
    PIPE_GLOBEX_DV360 ||--o{ NOTIF_PIPELINE_PENDING : "status"
    
    %% Entities (Representative Sample)
    ORG_ACME {
        string name "Acme Corporation"
        string slug "acme-corp"
        string plan "enterprise"
        decimal budget "50000"
    }
    
    ORG_GLOBEX {
        string name "Globex Industries"
        string slug "globex-ind"
        string plan "professional"
        decimal budget "25000"
    }
    
    ORG_INITECH {
        string name "Initech Solutions"
        string slug "initech"
        string plan "free"
        decimal budget "5000"
    }
    
    USER_ALICE {
        string email "admin@acme.com"
        string name "Alice Admin"
        string role "admin"
    }
    
    USER_BOB {
        string email "dev@acme.com"
        string name "Bob Developer"
        string role "developer"
    }
    
    USER_CAROL {
        string email "analyst@acme.com"
        string name "Carol Analyst"
        string role "analyst"
    }
    
    USER_DAVID {
        string email "admin@globex.com"
        string name "David Manager"
        string role "admin"
    }
    
    USER_EVE {
        string email "dev@globex.com"
        string name "Eve Engineer"
        string role "developer"
    }
    
    USER_FRANK {
        string email "viewer@globex.com"
        string name "Frank Viewer"
        string role "viewer"
    }
    
    USER_GRACE {
        string email "owner@initech.com"
        string name "Grace Owner"
        string role "admin"
    }
    
    USER_HENRY {
        string email "analyst@initech.com"
        string name "Henry Analyst"
        string role "analyst"
    }
    
    DSP_ACME_DV360 {
        string dsp_type "dv360"
        string external_id "12345678"
        string name "Acme DV360 Main"
    }
    
    DSP_ACME_META {
        string dsp_type "meta"
        string external_id "act_1234567890"
        string name "Acme Meta Ads"
    }
    
    DSP_ACME_TTD {
        string dsp_type "ttd"
        string external_id "acme-ttd-advertiser"
        string name "Acme TTD"
    }
    
    DSP_GLOBEX_DV360 {
        string dsp_type "dv360"
        string external_id "87654321"
        string name "Globex DV360"
    }
    
    DSP_GLOBEX_GADS {
        string dsp_type "google_ads"
        string external_id "9876543210"
        string name "Globex Google Ads"
    }
    
    DSP_INITECH_META {
        string dsp_type "meta"
        string external_id "act_9876543210"
        string name "Initech Meta"
    }
    
    TMPL_DV360_DAILY {
        string name "DV360 Daily Performance"
        string type "pipeline"
        boolean public "true"
        int usage "156"
    }
    
    TMPL_META_INSIGHTS {
        string name "Meta Campaign Insights"
        string type "pipeline"
        boolean public "true"
        int usage "203"
    }
    
    CAMP_ACME_PROSP {
        string name "ACME_Q1_ECOM_Prospecting"
        decimal budget "50000"
        string status "active"
    }
    
    CAMP_ACME_RETARG {
        string name "ACME_Q1_ECOM_Retargeting"
        decimal budget "30000"
        string status "active"
    }
    
    CAMP_ACME_HOLIDAY {
        string name "ACME_Holiday_FB_Conversions"
        decimal budget "25000"
        string status "paused"
    }
    
    CAMP_GLOBEX_LAUNCH {
        string name "Globex_Tech_Launch_Awareness"
        decimal budget "75000"
        string status "active"
    }
    
    CAMP_INITECH_LEADGEN {
        string name "Initech_Services_LeadGen"
        decimal budget "5000"
        string status "active"
    }
    
    METRICS_PROSP_7D {
        string description "7 days × metrics"
        int records "7"
    }
    
    METRICS_RETARG_7D {
        string description "7 days × metrics"
        int records "7"
    }
    
    METRICS_LAUNCH_7D {
        string description "7 days × metrics"
        int records "7"
    }
    
    METRICS_LEADGEN_7D {
        string description "7 days × metrics"
        int records "7"
    }
    
    PIPE_ACME_DV360 {
        string name "DV360 Daily Sync"
        string schedule "0 6 * * *"
        decimal success_rate "97.8"
    }
    
    PIPE_ACME_META {
        string name "Meta Hourly Refresh"
        string schedule "0 * * * *"
        decimal success_rate "98.7"
    }
    
    PIPE_ACME_TTD {
        string name "TTD Weekly Report"
        string schedule "0 9 * * 1"
        decimal success_rate "100"
    }
    
    PIPE_GLOBEX_DV360 {
        string name "DV360 Daily Reports"
        string schedule "0 7 * * *"
        decimal success_rate "100"
    }
    
    PIPE_INITECH_META {
        string name "Meta Daily Sync"
        string schedule "0 8 * * *"
        decimal success_rate "100"
    }
    
    EXEC_ACME_SUCCESS {
        string status "completed"
        int duration_ms "10900"
        bigint records "124850"
    }
    
    EXEC_ACME_FAILED {
        string status "failed"
        int duration_ms "2800"
        bigint records "0"
    }
    
    EXEC_GLOBEX_RUNNING {
        string status "running"
        string layer "silver"
    }
    
    DQ_BRONZE {
        string layer "bronze"
        string metric "required_fields"
        int fail_count "150"
    }
    
    DQ_SILVER {
        string layer "silver"
        string metric "data_types"
        int fail_count "0"
    }
    
    RULE_HIGH_PACING {
        string name "High Pacing Alert"
        string module "pacing"
        int matches "12"
    }
    
    RULE_LOW_CTR {
        string name "Low CTR Warning"
        string module "qa"
        int matches "8"
    }
    
    RULE_NAMING {
        string name "Naming Convention Check"
        string module "taxonomy"
        int matches "15"
    }
    
    RULE_OVERSPEND {
        string name "Budget Overspend Alert"
        string module "alerts"
        int matches "2"
    }
    
    RULE_DAILY_SPEND {
        string name "Daily Spend Limit"
        string module "alerts"
        int matches "0"
    }
    
    NOTIF_PACING_SENT {
        string type "email"
        string status "sent"
        string subject "High Pacing Alert"
    }
    
    NOTIF_CTR_FAILED {
        string type "email"
        string status "failed"
        string subject "Low CTR Warning"
    }
    
    NOTIF_PIPELINE_PENDING {
        string type "slack"
        string status "pending"
        string channel "#alerts"
    }
```

---

## Data Flow: Acme Corporation

```mermaid
graph TB
    subgraph "Acme Organization"
        A_ORG[Acme Corporation<br/>Enterprise Plan<br/>$50K budget]
        
        subgraph "Users"
            A_ALICE[Alice Admin]
            A_BOB[Bob Developer]
            A_CAROL[Carol Analyst]
        end
        
        subgraph "DSP Accounts"
            A_DV360[DV360<br/>12345678]
            A_META[Meta<br/>act_1234567890]
            A_TTD[TTD<br/>acme-ttd-advertiser]
        end
        
        subgraph "Campaigns"
            A_C1[Q1 Prospecting<br/>$50K Budget<br/>Active]
            A_C2[Q1 Retargeting<br/>$30K Budget<br/>Active]
            A_C3[Holiday FB<br/>$25K Budget<br/>Paused]
        end
        
        subgraph "Pipelines"
            A_P1[DV360 Daily Sync<br/>6 AM ET Daily<br/>97.8% success]
            A_P2[Meta Hourly<br/>Every hour<br/>98.7% success]
            A_P3[TTD Weekly<br/>Mon 9 AM<br/>100% success]
        end
        
        subgraph "Rules"
            A_R1[High Pacing Alert<br/>12 matches]
            A_R2[Low CTR Warning<br/>8 matches]
            A_R3[Naming Convention<br/>15 matches]
        end
        
        subgraph "Executions"
            A_E1[Success<br/>124,850 records<br/>10.9s]
            A_E2[Failed<br/>Silver layer<br/>2.8s]
        end
        
        subgraph "Data Quality"
            A_DQ1[Bronze: 150 missing<br/>creative_id]
            A_DQ2[Silver: 0 errors<br/>All validated]
        end
        
        subgraph "Notifications"
            A_N1[Email Sent<br/>Pacing Alert]
            A_N2[Email Failed<br/>CTR Warning]
        end
        
        subgraph "Metrics"
            A_M1[7 days metrics<br/>C1 Prospecting]
            A_M2[7 days metrics<br/>C2 Retargeting]
        end
    end
    
    A_ORG --> A_ALICE & A_BOB & A_CAROL
    A_ORG --> A_DV360 & A_META & A_TTD
    A_DV360 --> A_C1 & A_C2
    A_META --> A_C3
    A_C1 --> A_M1
    A_C2 --> A_M2
    
    A_DV360 --> A_P1
    A_META --> A_P2
    A_TTD --> A_P3
    
    A_P1 --> A_E1 & A_R1 & A_R2
    A_P2 --> A_E2
    
    A_E1 --> A_DQ1 & A_DQ2
    
    A_R1 --> A_N1
    A_R2 --> A_N2
```

---

## Data Flow: Globex Industries

```mermaid
graph TB
    subgraph "Globex Organization"
        G_ORG[Globex Industries<br/>Professional Plan<br/>$25K budget]
        
        subgraph "Users"
            G_DAVID[David Manager<br/>Admin]
            G_EVE[Eve Engineer<br/>Developer]
            G_FRANK[Frank Viewer<br/>Viewer]
        end
        
        subgraph "DSP Accounts"
            G_DV360[DV360<br/>87654321]
            G_GADS[Google Ads<br/>9876543210]
        end
        
        subgraph "Campaigns"
            G_C1[Tech Launch<br/>$75K Budget<br/>Active]
        end
        
        subgraph "Pipelines"
            G_P1[DV360 Daily<br/>7 AM PT<br/>100% success]
        end
        
        subgraph "Rules"
            G_R1[Budget Overspend<br/>2 matches]
        end
        
        subgraph "Executions"
            G_E1[Running<br/>Silver layer<br/>3 min elapsed]
        end
        
        subgraph "Notifications"
            G_N1[Slack Pending<br/>#alerts]
        end
        
        subgraph "Metrics"
            G_M1[7 days metrics<br/>Tech Launch]
        end
    end
    
    G_ORG --> G_DAVID & G_EVE & G_FRANK
    G_ORG --> G_DV360 & G_GADS
    G_DV360 --> G_C1
    G_C1 --> G_M1
    G_DV360 --> G_P1
    G_P1 --> G_E1 & G_R1
    G_P1 --> G_N1
```

---

## Data Flow: Initech Solutions

```mermaid
graph TB
    subgraph "Initech Organization"
        I_ORG[Initech Solutions<br/>Trial Plan<br/>$5K budget]
        
        subgraph "Users"
            I_GRACE[Grace Owner<br/>Admin]
            I_HENRY[Henry Analyst<br/>Analyst]
        end
        
        subgraph "DSP Accounts"
            I_META[Meta<br/>act_9876543210]
        end
        
        subgraph "Campaigns"
            I_C1[Services LeadGen<br/>$5K Daily<br/>Active]
        end
        
        subgraph "Pipelines"
            I_P1[Meta Daily<br/>8 AM CT<br/>100% success]
        end
        
        subgraph "Rules"
            I_R1[Daily Spend Limit<br/>0 matches]
        end
        
        subgraph "Metrics"
            I_M1[7 days metrics<br/>LeadGen]
        end
    end
    
    I_ORG --> I_GRACE & I_HENRY
    I_ORG --> I_META
    I_META --> I_C1
    I_C1 --> I_M1
    I_META --> I_P1
    I_P1 --> I_R1
```

---

## Template Marketplace Usage

```mermaid
graph LR
    subgraph "Public Templates"
        T1[DV360 Daily Performance<br/>156 uses | 4.7★]
        T2[DV360 Pacing Check<br/>89 uses | 4.5★]
        T3[Meta Campaign Insights<br/>203 uses | 4.8★]
    end
    
    subgraph "Acme Private"
        T4[Custom QA Rules<br/>12 uses]
        T5[Margin Calculator<br/>8 uses]
    end
    
    T1 -.instantiates.-> P1[Acme: DV360 Daily Sync]
    T1 -.instantiates.-> P4[Globex: DV360 Daily Reports]
    
    T3 -.instantiates.-> P2[Acme: Meta Hourly]
    T3 -.instantiates.-> P5[Initech: Meta Daily Sync]
    
    T4 -.used by.-> ACME[Acme Only]
    T5 -.used by.-> ACME
```

---

## Sample Metrics Data Pattern

```mermaid
graph TB
    subgraph "Campaign: ACME_Q1_ECOM_Prospecting"
        C[Campaign ID:<br/>70000000-1111-0001-0000-000000000001]
    end
    
    subgraph "7 Days of Metrics"
        D1[Jan 01<br/>45K imp | 850 clk<br/>$1,800 spend]
        D2[Jan 02<br/>52K imp | 920 clk<br/>$1,950 spend]
        D3[Jan 03<br/>38K imp | 710 clk<br/>$1,600 spend]
        D4[Jan 04<br/>48K imp | 880 clk<br/>$1,850 spend]
        D5[Jan 05<br/>55K imp | 950 clk<br/>$2,100 spend]
        D6[Jan 06<br/>42K imp | 790 clk<br/>$1,700 spend]
        D7[Today<br/>Pending sync]
    end
    
    C --> D1 & D2 & D3 & D4 & D5 & D6 & D7
    
    D1 -.calculated.-> CTR1[CTR: 1.89%<br/>CPC: $2.12]
    D2 -.calculated.-> CTR2[CTR: 1.77%<br/>CPC: $2.12]
    D3 -.calculated.-> CTR3[CTR: 1.87%<br/>CPC: $2.25]
```

---

## ETL Execution Breakdown

```mermaid
graph LR
    subgraph "Execution: DV360 Daily Sync"
        E[Pipeline Triggered<br/>18 hours ago]
    end
    
    subgraph "Bronze Layer"
        B[Status: Completed<br/>125,000 records<br/>45.6 MB<br/>3.2 seconds]
    end
    
    subgraph "Silver Layer"
        S[Status: Completed<br/>124,850 records<br/>150 filtered<br/>5.6 seconds]
    end
    
    subgraph "Gold Layer"
        G[Status: Completed<br/>2 tables updated<br/>campaign_daily<br/>pacing_metrics<br/>2.1 seconds]
    end
    
    subgraph "Data Quality"
        DQ1[Bronze DQ<br/>150 missing creative_id<br/>Warning severity]
        DQ2[Silver DQ<br/>0 errors<br/>All types valid]
    end
    
    E --> B
    B --> S
    S --> G
    B --> DQ1
    S --> DQ2
    
    G -.total duration.-> T[10.9 seconds<br/>124,850 records processed]
```

---

## Notification Flow Example

```mermaid
graph TB
    subgraph "Rule Evaluation"
        R[High Pacing Alert Rule<br/>Priority: 1<br/>Enabled: true]
    end
    
    subgraph "Campaign Check"
        C[ACME_Q1_ECOM_Prospecting<br/>Pacing: 125%<br/>Days remaining: 15]
    end
    
    subgraph "Condition Met"
        COND[pacing_rate > 120<br/>days_remaining > 3<br/>Result: MATCH]
    end
    
    subgraph "Actions Triggered"
        A1[Email Action<br/>To: admin@acme.com<br/>Severity: high]
        A2[Slack Action<br/>Channel: #alerts<br/>Severity: high]
    end
    
    subgraph "Notification Queue"
        N1[Notification Created<br/>Type: email<br/>Status: sent<br/>Sent 2 hours ago]
        N2[Notification Created<br/>Type: slack<br/>Status: sent]
    end
    
    R --> C
    C --> COND
    COND --> A1 & A2
    A1 --> N1
    A2 --> N2
```

---

## Summary Statistics

### Organizations by Plan
```
Enterprise: 1 (Acme) - $50K/month
Professional: 1 (Globex) - $25K/month  
Free/Trial: 1 (Initech) - $5K/month
Total: 3 organizations
```

### Users by Role
```
Admin: 3 (Alice, David, Grace)
Developer: 2 (Bob, Eve)
Analyst: 2 (Carol, Henry)
Viewer: 1 (Frank)
Total: 9 active users
```

### DSP Accounts by Type
```
DV360: 2 (Acme, Globex)
Meta: 2 (Acme, Initech)
TTD: 1 (Acme)
Google Ads: 1 (Globex)
Total: 6 DSP accounts
```

### Campaigns by Status
```
Active: 4 campaigns
Paused: 1 campaign (Acme Holiday)
Total: 5 campaigns
```

### Campaign Metrics
```
Days of data: 7 days
Records per campaign: 7
Total metric records: 35
Active campaigns tracked: 5
```

### Pipelines by Schedule
```
Hourly: 1 (Acme Meta)
Daily: 3 (Acme DV360, Globex DV360, Initech Meta)
Weekly: 1 (Acme TTD)
Total: 5 pipelines
```

### Executions by Status
```
Completed: 1
Failed: 1
Running: 1
Total: 3 recent executions
```

### Rules by Module
```
Pacing: 1 rule
QA: 1 rule
Taxonomy: 1 rule
Alerts: 2 rules
Total: 5 rules
```

### Notifications by Status
```
Sent: 1
Pending: 1
Failed: 1
Total: 3 notifications
```

---

This sample data ER diagram shows exactly how the seed data instances relate to each other, making it easy to understand the test scenarios and data relationships.