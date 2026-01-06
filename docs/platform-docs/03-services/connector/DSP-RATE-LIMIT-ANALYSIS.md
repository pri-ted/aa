# DSP OAuth Multi-Tenancy & Rate Limiting Architecture

> Hierarchical rate limiting strategy for scaling to 1000+ organizations


## Executive Summary

DSP APIs (DV360, Meta, TTD, Google Ads) enforce **two-tier rate limits**:
1. **Global limits** at the OAuth app/service account level (shared across all organizations)
2. **Per-account limits** at the client's advertiser/ad-account level

Current architecture docs only address global limits. This creates a **critical scaling constraint** that will block multi-tenancy beyond 100-200 organizations.

**Impact**: Without proper implementation, one organization's high usage exhausts the global quota and blocks all other clients.

**Solution**: Implement hierarchical rate limiting with intelligent request scheduling, batching, and eventual multi-app sharding.

---

## Rate Limit Research Findings

### DV360 (Google Display & Video 360)

**Architecture**: OAuth 2.0 via Google Cloud Project

**Two-Tier Limits**:

| Level | Scope | Limits |
|-------|-------|--------|
| **Project-Level** (Global) | Our OAuth app | • 1,500 requests/min<br>• 700 write requests/min<br>• 86,400 requests/day |
| **Advertiser-Level** (Per Client) | Each client's advertiser_id | • 300 requests/min<br>• 150 write requests/min |

**Source**: [DV360 API Usage Limits](https://developers.google.com/display-video/api/limits)

**Key Implications**:
- All 1000 organizations share the 1,500/min global limit
- Each organization's advertiser has additional 300/min cap
- Write-intensive operations (bulkEdit, SDF) count as 5× requests

---

### Meta Ads (Facebook/Instagram)

**Architecture**: OAuth 2.0 via Meta Developer App

**Two-Tier Limits**:

| Level | Scope | Formula |
|-------|-------|---------|
| **App-Level** (Global) | Our Meta app | • Standard tier: 9,000 points<br>• Dev tier: 60 points<br>• 1 point per read, 3 per write<br>• 5-min sliding window |
| **Ad-Account-Level** (Per Client) | Each ad account | `(190,000 if Standard) + (400 × Active Ads) - (0.001 × User Errors)` |

**Source**: [Meta Marketing API Rate Limits](https://developers.facebook.com/docs/marketing-api/overview/rate-limiting)

**Key Implications**:
- App-level quota is dynamically calculated: `200 calls/hour × number of app users`
- Ad account limits scale with active ad count
- Insights API has separate, stricter limits (100/hour)

---

### The Trade Desk

**Architecture**: API Key authentication (not OAuth)

**Documented Limits**:

| Endpoint | Limit | Window |
|----------|-------|--------|
| Authentication | 10 | per minute |
| Campaign Read | 100 | per minute |
| Report Query | 20 | per minute |
| Bulk Operations | 50 | per minute |

**Status**: Partner-level limits confirmed. Per-advertiser limits **not publicly documented**.

**Action Required**: Contact TTD account manager to confirm per-advertiser limits exist.

---

### Google Ads

**Architecture**: OAuth 2.0 via Google Cloud Project

**Limits**:

| Level | Scope | Limits |
|-------|-------|--------|
| **Developer Token** (Global) | Our app | • 15,000 operations/day<br>• Different tiers (Test, Basic, Standard, Premium) |
| **Customer-Level** (Per Client) | Each customer_id | Not explicitly documented but observed in practice |

**Key Implications**:
- Must apply for Standard/Premium access for production scale
- Operations (not HTTP requests) are counted
- Batch operations count as single operation

---

## Scaling Constraint Analysis

### Single OAuth App Capacity

**DV360 Example** (Most restrictive):

```
Global Budget: 1,500 requests/min = 90,000 requests/hour

Scenario 1: Conservative Usage (1000 orgs)
  - Each org syncs campaigns once/hour
  - Average 5 API calls per sync
  - Total: 1000 × 5 = 5,000 calls/hour
  - Utilization: 5.5% ✓ SAFE

Scenario 2: Moderate Usage (1000 orgs)
  - Each org syncs 10 campaigns/hour
  - Average 15 API calls per sync  
  - Total: 1000 × 15 = 15,000 calls/hour
  - Utilization: 16.6% ✓ SAFE

Scenario 3: High Usage (1000 orgs)
  - 100 orgs trigger manual refresh simultaneously
  - Average 50 API calls per refresh
  - Spike: 100 × 50 = 5,000 calls in ~5 minutes
  - Peak rate: ~1,000 requests/min
  - Utilization: 66% ⚠ APPROACHING LIMIT

Scenario 4: Burst Usage
  - 500 premium orgs sync at top of hour
  - Average 30 calls per sync
  - Spike: 500 × 30 = 15,000 calls in 10 minutes
  - Peak rate: ~1,500 requests/min
  - Utilization: 100% ✗ LIMIT EXCEEDED
```

**Conclusion**: Single OAuth app is viable for 1000 orgs with proper request scheduling and batching. Multi-app sharding needed for >1500 orgs or high-frequency sync requirements.

---

## Architecture Design

### 1. Hierarchical Rate Limiter

**Implementation**:

```go
package ratelimit

import (
    "sync"
    "time"
)

// Two-tier rate limiter
type HierarchicalRateLimiter struct {
    // Global level (OAuth app/project)
    globalLimiter *TokenBucket
    
    // Per-account level (advertiser/ad-account)
    accountLimiters map[string]*TokenBucket
    mu              sync.RWMutex
    
    config RateLimitConfig
}

type RateLimitConfig struct {
    DSP              string
    GlobalLimit      int    // requests per minute
    GlobalWriteLimit int    // write requests per minute
    AccountLimit     int    // per account requests per minute
    AccountWriteLimit int   // per account write requests per minute
}

func NewHierarchicalRateLimiter(config RateLimitConfig) *HierarchicalRateLimiter {
    return &HierarchicalRateLimiter{
        globalLimiter: NewTokenBucket(config.GlobalLimit, time.Minute),
        accountLimiters: make(map[string]*TokenBucket),
        config: config,
    }
}

// Check if request is allowed at BOTH levels
func (h *HierarchicalRateLimiter) AllowRequest(accountID string, isWrite bool) (allowed bool, reason string) {
    // Check global limit first
    cost := 1
    if isWrite {
        cost = 3 // Meta counts writes as 3×
    }
    
    if !h.globalLimiter.Allow(cost) {
        return false, "global_rate_limit_exceeded"
    }
    
    // Check account-specific limit
    h.mu.RLock()
    accountLimiter, exists := h.accountLimiters[accountID]
    h.mu.RUnlock()
    
    if !exists {
        h.mu.Lock()
        accountLimiter = NewTokenBucket(h.config.AccountLimit, time.Minute)
        h.accountLimiters[accountID] = accountLimiter
        h.mu.Unlock()
    }
    
    if !accountLimiter.Allow(cost) {
        return false, fmt.Sprintf("account_rate_limit_exceeded:%s", accountID)
    }
    
    return true, ""
}

// Get current usage stats
func (h *HierarchicalRateLimiter) GetUsageStats(accountID string) UsageStats {
    globalUsage := h.globalLimiter.CurrentUsage()
    
    h.mu.RLock()
    accountLimiter := h.accountLimiters[accountID]
    h.mu.RUnlock()
    
    accountUsage := 0
    if accountLimiter != nil {
        accountUsage = accountLimiter.CurrentUsage()
    }
    
    return UsageStats{
        GlobalUsage:   globalUsage,
        GlobalLimit:   h.config.GlobalLimit,
        AccountUsage:  accountUsage,
        AccountLimit:  h.config.AccountLimit,
    }
}
```

**Token Bucket Implementation**:

```go
type TokenBucket struct {
    capacity    int
    tokens      int
    refillRate  int           // tokens per duration
    refillEvery time.Duration
    lastRefill  time.Time
    mu          sync.Mutex
}

func NewTokenBucket(capacity int, duration time.Duration) *TokenBucket {
    return &TokenBucket{
        capacity:    capacity,
        tokens:      capacity,
        refillRate:  capacity,
        refillEvery: duration,
        lastRefill:  time.Now(),
    }
}

func (tb *TokenBucket) Allow(cost int) bool {
    tb.mu.Lock()
    defer tb.mu.Unlock()
    
    // Refill tokens based on elapsed time
    tb.refill()
    
    if tb.tokens >= cost {
        tb.tokens -= cost
        return true
    }
    
    return false
}

func (tb *TokenBucket) refill() {
    now := time.Now()
    elapsed := now.Sub(tb.lastRefill)
    
    if elapsed >= tb.refillEvery {
        tb.tokens = tb.capacity
        tb.lastRefill = now
    }
}

func (tb *TokenBucket) CurrentUsage() int {
    tb.mu.Lock()
    defer tb.mu.Unlock()
    tb.refill()
    return tb.capacity - tb.tokens
}
```

---

### 2. Database Schema

**OAuth Apps Table** (Multi-app support):

```sql
CREATE TABLE oauth_apps (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    provider VARCHAR(50) NOT NULL,  -- 'dv360', 'google_ads', 'meta', 'ttd'
    app_name VARCHAR(255) NOT NULL,
    
    -- Provider-specific IDs
    project_id VARCHAR(255),        -- Google Cloud Project ID
    client_id VARCHAR(255) NOT NULL,
    client_secret_encrypted BYTEA NOT NULL,
    
    -- Rate limit configuration
    rate_limit_per_min INT NOT NULL,
    rate_limit_per_day INT,
    write_limit_per_min INT,
    
    -- Current usage tracking (in-memory cache, DB for audit)
    current_usage_min INT DEFAULT 0,
    current_usage_day INT DEFAULT 0,
    window_start TIMESTAMP,
    
    -- Management
    status VARCHAR(50) DEFAULT 'active',
    shard_index INT,                -- For round-robin assignment
    max_orgs INT,                   -- Max orgs per app
    current_org_count INT DEFAULT 0,
    
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    
    UNIQUE(provider, project_id),
    UNIQUE(provider, client_id)
);

CREATE INDEX idx_oauth_apps_provider_status 
ON oauth_apps(provider, status);
```

**Organization OAuth Credentials**:

```sql
CREATE TABLE org_oauth_credentials (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    org_id UUID NOT NULL REFERENCES organizations(id),
    oauth_app_id UUID NOT NULL REFERENCES oauth_apps(id),
    provider VARCHAR(50) NOT NULL,
    
    -- OAuth tokens
    access_token_encrypted BYTEA,
    refresh_token_encrypted BYTEA NOT NULL,
    token_expires_at TIMESTAMP,
    
    -- External account identifiers
    external_account_id VARCHAR(255) NOT NULL,  -- advertiser_id, ad_account_id, customer_id
    external_account_name VARCHAR(255),
    
    -- Permissions
    scopes TEXT[] NOT NULL,
    
    -- Health tracking
    last_successful_auth TIMESTAMP,
    last_failed_auth TIMESTAMP,
    consecutive_failures INT DEFAULT 0,
    
    status VARCHAR(50) DEFAULT 'active',
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    
    UNIQUE(org_id, provider, external_account_id)
);

CREATE INDEX idx_org_oauth_provider 
ON org_oauth_credentials(provider, status);

CREATE INDEX idx_org_oauth_app 
ON org_oauth_credentials(oauth_app_id, status);
```

**Per-Account Rate Limit Tracking**:

```sql
CREATE TABLE dsp_account_rate_limits (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    oauth_app_id UUID NOT NULL REFERENCES oauth_apps(id),
    external_account_id VARCHAR(255) NOT NULL,
    provider VARCHAR(50) NOT NULL,
    
    -- Sliding window tracking
    window_start TIMESTAMP NOT NULL,
    window_duration INTERVAL DEFAULT '1 minute',
    
    -- Usage counters
    total_requests INT DEFAULT 0,
    write_requests INT DEFAULT 0,
    failed_requests INT DEFAULT 0,
    
    -- Limits (cached from provider config)
    max_requests INT NOT NULL,
    max_writes INT,
    
    -- For cleanup
    expires_at TIMESTAMP NOT NULL,
    
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    
    UNIQUE(oauth_app_id, external_account_id, window_start)
);

CREATE INDEX idx_rate_limit_window 
ON dsp_account_rate_limits(oauth_app_id, external_account_id, window_start)
WHERE expires_at > NOW();

-- Auto-cleanup old windows
CREATE INDEX idx_rate_limit_cleanup 
ON dsp_account_rate_limits(expires_at) 
WHERE expires_at <= NOW();
```

---

### 3. Request Queue with Account-Level Fairness

**Priority Queue Enhancement**:

```go
package queue

type RequestQueue struct {
    // Priority levels
    priority1 *FairQueue  // Premium manual triggers
    priority2 *FairQueue  // Standard manual triggers
    priority3 *FairQueue  // Scheduled syncs
    priority4 *FairQueue  // Retry queue
    
    rateLimiter *HierarchicalRateLimiter
    mu          sync.RWMutex
}

// Fair queue ensures no single account monopolizes quota
type FairQueue struct {
    queue            []*FetchRequest
    accountLastUsed  map[string]time.Time
    accountPending   map[string]int  // Count pending per account
    mu               sync.RWMutex
}

type FetchRequest struct {
    ID              string
    OrgID           UUID
    DSP             string
    OAuthAppID      UUID
    ExternalAccountID string  // advertiser_id, ad_account_id
    
    RequestType     string    // "campaigns", "reports", "insights"
    IsWrite         bool
    Priority        int
    
    QueuedAt        time.Time
    EstimatedCost   int       // Number of API calls
    
    // Retry tracking
    Attempts        int
    MaxAttempts     int
    LastError       string
}

func (q *RequestQueue) Enqueue(req *FetchRequest) error {
    // Check rate limits before queuing
    allowed, reason := q.rateLimiter.AllowRequest(req.ExternalAccountID, req.IsWrite)
    
    if !allowed {
        // Calculate backoff time
        backoffDuration := q.calculateBackoff(reason, req)
        
        // Schedule for later
        return q.scheduleDeferred(req, backoffDuration)
    }
    
    // Add to appropriate priority queue
    queue := q.getQueueByPriority(req.Priority)
    queue.Add(req)
    
    return nil
}

func (q *RequestQueue) Dequeue() *FetchRequest {
    // Try each priority level in order
    for _, queue := range []*FairQueue{q.priority1, q.priority2, q.priority3, q.priority4} {
        req := queue.GetNext(q.rateLimiter)
        if req != nil {
            return req
        }
    }
    
    return nil
}

// Get next request with account-level fairness
func (fq *FairQueue) GetNext(limiter *HierarchicalRateLimiter) *FetchRequest {
    fq.mu.Lock()
    defer fq.mu.Unlock()
    
    if len(fq.queue) == 0 {
        return nil
    }
    
    // Find request from least recently used account
    var selectedIdx int = -1
    var oldestUsage time.Time = time.Now()
    
    for i, req := range fq.queue {
        // Skip if rate limit exceeded
        allowed, _ := limiter.AllowRequest(req.ExternalAccountID, req.IsWrite)
        if !allowed {
            continue
        }
        
        lastUsed := fq.accountLastUsed[req.ExternalAccountID]
        if lastUsed.IsZero() || lastUsed.Before(oldestUsage) {
            oldestUsage = lastUsed
            selectedIdx = i
        }
    }
    
    if selectedIdx == -1 {
        return nil  // All accounts rate limited
    }
    
    // Remove and return
    req := fq.queue[selectedIdx]
    fq.queue = append(fq.queue[:selectedIdx], fq.queue[selectedIdx+1:]...)
    fq.accountLastUsed[req.ExternalAccountID] = time.Now()
    fq.accountPending[req.ExternalAccountID]--
    
    return req
}
```

---

### 4. Request Batching & Coalescing

**Batch Similar Requests**:

```go
package batching

type RequestBatcher struct {
    windows     map[string]*BatchWindow
    windowSize  time.Duration
    mu          sync.RWMutex
}

type BatchWindow struct {
    DSP             string
    RequestType     string
    ExternalAccountID string
    
    Requests        []*FetchRequest
    WindowStart     time.Time
    WindowEnd       time.Time
    
    Executed        bool
}

func NewRequestBatcher(windowSize time.Duration) *RequestBatcher {
    return &RequestBatcher{
        windows:    make(map[string]*BatchWindow),
        windowSize: windowSize,
    }
}

func (b *RequestBatcher) Add(req *FetchRequest) {
    b.mu.Lock()
    defer b.mu.Unlock()
    
    key := b.getWindowKey(req)
    window, exists := b.windows[key]
    
    if !exists || time.Now().After(window.WindowEnd) {
        // Create new window
        window = &BatchWindow{
            DSP:               req.DSP,
            RequestType:       req.RequestType,
            ExternalAccountID: req.ExternalAccountID,
            Requests:          []*FetchRequest{},
            WindowStart:       time.Now(),
            WindowEnd:         time.Now().Add(b.windowSize),
        }
        b.windows[key] = window
    }
    
    window.Requests = append(window.Requests, req)
}

func (b *RequestBatcher) ExecuteReadyBatches() []*BatchWindow {
    b.mu.Lock()
    defer b.mu.Unlock()
    
    ready := []*BatchWindow{}
    now := time.Now()
    
    for key, window := range b.windows {
        if !window.Executed && now.After(window.WindowEnd) {
            window.Executed = true
            ready = append(ready, window)
            delete(b.windows, key)
        }
    }
    
    return ready
}

func (b *RequestBatcher) getWindowKey(req *FetchRequest) string {
    return fmt.Sprintf("%s:%s:%s", req.DSP, req.RequestType, req.ExternalAccountID)
}
```

---

### 5. Intelligent Scheduler

**Distribute Syncs Across Time**:

```go
package scheduler

type SyncScheduler struct {
    db          *sql.DB
    orgSchedules map[UUID]OrgSchedule
    mu          sync.RWMutex
}

type OrgSchedule struct {
    OrgID           UUID
    DSP             string
    
    // Scheduled offsets (minutes past the hour)
    HourlyOffset    int
    DailyOffset     int
    
    // Frequency
    SyncFrequency   string  // "hourly", "daily", "manual"
    
    // Last sync
    LastSync        time.Time
    NextSync        time.Time
}

func (s *SyncScheduler) ScheduleOrg(orgID UUID, dsp string, frequency string) error {
    // Calculate offset to distribute load
    offset := s.calculateOffset(orgID, dsp)
    
    schedule := OrgSchedule{
        OrgID:         orgID,
        DSP:           dsp,
        HourlyOffset:  offset % 60,
        DailyOffset:   offset % 1440,  // Minutes in day
        SyncFrequency: frequency,
        NextSync:      s.calculateNextSync(offset, frequency),
    }
    
    s.mu.Lock()
    s.orgSchedules[orgID] = schedule
    s.mu.Unlock()
    
    return s.persistSchedule(schedule)
}

func (s *SyncScheduler) calculateOffset(orgID UUID, dsp string) int {
    // Hash-based distribution ensures consistent scheduling
    h := sha256.New()
    h.Write([]byte(fmt.Sprintf("%s:%s", orgID, dsp)))
    hash := h.Sum(nil)
    
    // Convert to int
    offset := int(binary.BigEndian.Uint64(hash[:8]))
    return offset
}

func (s *SyncScheduler) GetDueOrgs(now time.Time) []OrgSchedule {
    s.mu.RLock()
    defer s.mu.RUnlock()
    
    due := []OrgSchedule{}
    for _, schedule := range s.orgSchedules {
        if now.After(schedule.NextSync) {
            due = append(due, schedule)
        }
    }
    
    return due
}
```

**Example Distribution** (1000 orgs, hourly sync):

```
:00-:05  →  83 orgs
:05-:10  →  84 orgs
:10-:15  →  83 orgs
...
:55-:60  →  84 orgs

Peak rate: 84 orgs × 10 calls/sync ÷ 5 min = 168 requests/min
Utilization: 168/1500 = 11.2% ✓
```

---

### 6. Multi-App OAuth Router

**Shard Organizations Across Multiple OAuth Apps**:

```go
package oauth

type OAuthRouter struct {
    apps        map[UUID]*OAuthApp
    provider    string
    strategy    string  // "round_robin", "least_loaded", "hash_based"
    mu          sync.RWMutex
}

type OAuthApp struct {
    ID              UUID
    Provider        string
    ProjectID       string
    ClientID        string
    ClientSecret    string
    
    RateLimiter     *HierarchicalRateLimiter
    CurrentOrgCount int
    MaxOrgCount     int
    Status          string
}

func (r *OAuthRouter) GetAppForOrg(orgID UUID) (*OAuthApp, error) {
    r.mu.RLock()
    defer r.mu.RUnlock()
    
    // Check if org already assigned
    app, exists := r.getExistingAssignment(orgID)
    if exists {
        return app, nil
    }
    
    // Assign new org to app
    return r.assignOrgToApp(orgID)
}

func (r *OAuthRouter) assignOrgToApp(orgID UUID) (*OAuthApp, error) {
    switch r.strategy {
    case "round_robin":
        return r.roundRobinAssign(orgID)
    case "least_loaded":
        return r.leastLoadedAssign(orgID)
    case "hash_based":
        return r.hashBasedAssign(orgID)
    default:
        return nil, errors.New("unknown routing strategy")
    }
}

func (r *OAuthRouter) hashBasedAssign(orgID UUID) (*OAuthApp, error) {
    // Consistent hashing for stable assignment
    activeApps := r.getActiveApps()
    if len(activeApps) == 0 {
        return nil, errors.New("no active OAuth apps")
    }
    
    h := sha256.New()
    h.Write([]byte(orgID.String()))
    hash := h.Sum(nil)
    
    idx := int(binary.BigEndian.Uint64(hash[:8])) % len(activeApps)
    return activeApps[idx], nil
}

func (r *OAuthRouter) leastLoadedAssign(orgID UUID) (*OAuthApp, error) {
    activeApps := r.getActiveApps()
    
    var selectedApp *OAuthApp
    minLoad := int(^uint(0) >> 1)  // Max int
    
    for _, app := range activeApps {
        if app.CurrentOrgCount < app.MaxOrgCount && app.CurrentOrgCount < minLoad {
            minLoad = app.CurrentOrgCount
            selectedApp = app
        }
    }
    
    if selectedApp == nil {
        return nil, errors.New("all OAuth apps at capacity")
    }
    
    selectedApp.CurrentOrgCount++
    return selectedApp, nil
}
```

**Multi-App Configuration**:

```yaml
# config/oauth-apps.yaml
oauth_apps:
  dv360:
    - name: "campaign-platform-dv360-1"
      project_id: "cp-dv360-prod-1"
      client_id: "..."
      max_orgs: 333
      rate_limit: 1500
      status: "active"
      
    - name: "campaign-platform-dv360-2"
      project_id: "cp-dv360-prod-2"
      client_id: "..."
      max_orgs: 333
      rate_limit: 1500
      status: "active"
      
    - name: "campaign-platform-dv360-3"
      project_id: "cp-dv360-prod-3"
      client_id: "..."
      max_orgs: 334
      rate_limit: 1500
      status: "active"

  meta:
    - name: "campaign-platform-meta-1"
      app_id: "..."
      client_id: "..."
      max_orgs: 500
      rate_limit: 9000
      status: "active"
```

---

### 7. Configuration Updates

**Update `06-integrations/connector-framework.md`**:

```yaml
# Rate Limiting Configuration

rate_limiting:
  strategy: "hierarchical"  # two-tier: global + per-account
  
  dv360:
    # OAuth app level (Google Cloud Project)
    global:
      total: 1500          # requests per minute
      writes: 700          # write requests per minute  
      daily: 86400         # requests per day
      
    # Per-advertiser level
    per_account:
      total: 300           # requests per minute
      writes: 150          # write requests per minute
      
    # Write-intensive methods (count as 5×)
    write_intensive:
      - "bulkEdit"
      - "sdfdownload.create"
      
  meta:
    # App-level limits
    global:
      standard_tier: 9000  # points per 5 minutes
      dev_tier: 60         # points per 5 minutes
      read_cost: 1         # points per read
      write_cost: 3        # points per write
      
    # Ad account limits (dynamic formula)
    per_account:
      formula: "(190000 + 400*active_ads - 0.001*errors)"
      
    # Special limits
    insights:
      limit: 100           # requests per hour
      
  ttd:
    global:
      total: 100           # requests per minute
      authentication: 10   # requests per minute
      reports: 20          # requests per minute
      bulk: 50             # requests per minute
      
    # Per-advertiser (TBD - needs TTD confirmation)
    per_account:
      total: null          # Not documented
      
  google_ads:
    global:
      daily: 15000         # operations per day
      tier: "standard"     # test, basic, standard, premium
      
    per_account:
      total: null          # Not explicitly documented

# Request Batching
batching:
  enabled: true
  window_size: "5m"
  max_batch_size: 50
  
# Scheduling
scheduling:
  distribution: "hash_based"  # Distribute syncs across time
  default_frequency: "hourly"
  max_concurrent: 100          # Max concurrent syncs

# Multi-App Strategy  
multi_app:
  enabled: false               # Start with single app
  trigger_threshold: 0.7       # Shard when 70% utilization
  routing_strategy: "least_loaded"
  max_orgs_per_app: 333
```

---

### 8. Observability & Monitoring

**Metrics to Track**:

```go
// Prometheus metrics
var (
    // Global rate limit usage
    rateLimitUsageGlobal = prometheus.NewGaugeVec(
        prometheus.GaugeOpts{
            Name: "dsp_rate_limit_usage_global",
            Help: "Current global rate limit usage",
        },
        []string{"dsp", "oauth_app_id"},
    )
    
    // Per-account rate limit usage
    rateLimitUsageAccount = prometheus.NewGaugeVec(
        prometheus.GaugeOpts{
            Name: "dsp_rate_limit_usage_account",
            Help: "Current account-level rate limit usage",
        },
        []string{"dsp", "external_account_id"},
    )
    
    // Rate limit hits
    rateLimitHitsTotal = prometheus.NewCounterVec(
        prometheus.CounterOpts{
            Name: "dsp_rate_limit_hits_total",
            Help: "Total rate limit hits",
        },
        []string{"dsp", "level", "reason"},  // level: global|account
    )
    
    // Queue depth
    queueDepth = prometheus.NewGaugeVec(
        prometheus.GaugeOpts{
            Name: "dsp_queue_depth",
            Help: "Number of requests in queue",
        },
        []string{"priority", "dsp"},
    )
    
    // Request latency
    requestLatency = prometheus.NewHistogramVec(
        prometheus.HistogramOpts{
            Name: "dsp_request_duration_seconds",
            Help: "Time from queue to completion",
            Buckets: []float64{1, 5, 10, 30, 60, 120, 300},
        },
        []string{"dsp", "request_type"},
    )
)
```

**Grafana Dashboard Panels**:

1. **Global Rate Limit Utilization** (Gauge)
   - Target: Keep < 70% average, < 90% peak
   - Alert: > 85% for 5 minutes

2. **Per-Account Top 10** (Table)
   - Show accounts with highest usage
   - Identify outliers

3. **Rate Limit Hits Over Time** (Graph)
   - Track frequency of limits being hit
   - Correlate with incidents

4. **Queue Depth by Priority** (Stacked Area)
   - Monitor backlog
   - Alert on P1/P2 queue depth > 100

5. **Request Processing Time** (Histogram)
   - p50, p95, p99 latencies
   - Target: p95 < 60s

---

## Implementation Phases

### Phase 1: Foundation (Week 1-2)

**Goal**: Basic two-tier rate limiting

**Tasks**:
- [ ] Implement `HierarchicalRateLimiter` with token bucket
- [ ] Create database schema for `oauth_apps`, `org_oauth_credentials`, `dsp_account_rate_limits`
- [ ] Update connector service to check both limits before API calls
- [ ] Add basic metrics (global & account usage)

**Success Criteria**:
- Rate limiter correctly blocks when limits exceeded
- Both global and per-account limits enforced
- Usage visible in Grafana

---

### Phase 2: Smart Scheduling (Week 3-4)

**Goal**: Distribute load over time

**Tasks**:
- [ ] Implement `SyncScheduler` with hash-based distribution
- [ ] Migrate existing org syncs to scheduled offsets
- [ ] Add request batching for similar requests (5-min window)
- [ ] Implement account-level fairness in queue

**Success Criteria**:
- No spike at top of hour (requests evenly distributed)
- Peak utilization < 50% with 100 orgs
- No single account monopolizes quota

---

### Phase 3: Advanced Queue (Week 5-6)

**Goal**: Priority-based processing with intelligent deferral

**Tasks**:
- [ ] Implement 4-tier priority queue
- [ ] Add deferred queue with exponential backoff
- [ ] Implement request coalescing (merge duplicate requests)
- [ ] Add circuit breaker for failing accounts

**Success Criteria**:
- Premium manual triggers complete within 30s
- Failed requests auto-retry with backoff
- System gracefully handles DSP outages

---

### Phase 4: Multi-App Preparation (Week 7-8)

**Goal**: Infrastructure for sharding across multiple OAuth apps

**Tasks**:
- [ ] Implement `OAuthRouter` with multiple strategies
- [ ] Create admin tooling for OAuth app management
- [ ] Add org migration between OAuth apps
- [ ] Test with 2 DV360 OAuth apps

**Success Criteria**:
- Can route orgs to different OAuth apps
- Can migrate orgs without downtime
- Total capacity = sum of all apps

---

### Phase 5: Scale Testing (Week 9-10)

**Goal**: Validate 1000-org capacity

**Tasks**:
- [ ] Load test with 1000 simulated orgs
- [ ] Stress test with burst traffic
- [ ] Chaos engineering (random DSP failures)
- [ ] Performance optimization

**Success Criteria**:
- System handles 1000 orgs with single OAuth app
- Peak utilization < 70% under normal load
- p95 latency < 60s for manual triggers

---

## Decision Framework

### When to Add Second OAuth App?

**Triggers**:
- Global rate limit utilization > 70% sustained for 1 week
- Frequent rate limit hits (> 10/hour)
- Org count approaching 500 (50% of target capacity)
- Premium orgs experiencing delays > 30s

**Process**:
1. Create new Google Cloud Project
2. Set up OAuth app credentials
3. Add to `oauth_apps` table
4. Enable multi-app routing
5. Migrate 50% of orgs using `least_loaded` strategy
6. Monitor for 1 week
7. Adjust routing if needed

---

### Quota Allocation Strategy

**Organization Tiers**:

| Tier | Sync Frequency | Manual Triggers | Quota Share |
|------|---------------|-----------------|-------------|
| **Free** | Daily | 5/day | 0.5× base |
| **Standard** | Hourly | 20/day | 1.0× base |
| **Premium** | Hourly + On-Demand | Unlimited | 3.0× base |

**Base Quota Calculation**:

```
Total global quota: 1,500 req/min = 90,000 req/hour

Reserved for manual triggers: 30,000 req/hour (33%)
Available for scheduled syncs: 60,000 req/hour (67%)

Example with 1000 orgs (500 Standard, 400 Free, 100 Premium):
  - Weighted org count: (500×1.0) + (400×0.5) + (100×3.0) = 1,000
  - Base quota: 60,000 / 1,000 = 60 req/hour per weighted org
  - Free: 60 × 0.5 = 30 req/hour
  - Standard: 60 × 1.0 = 60 req/hour  
  - Premium: 60 × 3.0 = 180 req/hour
```

---

## Cost Analysis

### Single vs Multi-App Strategy

**Google Cloud Costs** (DV360/Google Ads):

| Item | Single App | 3 Apps (Sharded) |
|------|-----------|------------------|
| API Calls | Free (within quota) | Free (within quota) |
| Cloud Monitoring | $0 (basic) | $0 (basic) |
| Cloud KMS (token encryption) | $5/month | $15/month |
| **Total/month** | **$5** | **$15** |

**Meta Costs**:
- No direct costs for OAuth apps
- Same API quotas regardless of app count

**Recommendation**: Start with single app. Additional apps cost $10/month each, negligible compared to infrastructure savings from efficient scaling.

---

## Migration Plan

### Existing Organizations

**Current State**: Organizations may have existing OAuth tokens from old system.

**Migration Steps**:

1. **Token Migration**:
```sql
INSERT INTO org_oauth_credentials (
    org_id,
    oauth_app_id,
    provider,
    refresh_token_encrypted,
    external_account_id,
    scopes
)
SELECT 
    o.id,
    (SELECT id FROM oauth_apps WHERE provider = 'dv360' AND status = 'active' LIMIT 1),
    'dv360',
    o.dv360_refresh_token_encrypted,
    o.dv360_advertiser_id,
    ARRAY['https://www.googleapis.com/auth/display-video']
FROM old_organizations o
WHERE o.dv360_connected = true;
```

2. **Verify Tokens**:
```go
for _, org := range migratedOrgs {
    client := buildOAuthClient(org.Credentials)
    if err := client.TestConnection(); err != nil {
        org.Status = "requires_reauth"
        notifyOrgForReauth(org)
    }
}
```

3. **Schedule Initial Syncs**:
```go
scheduler := NewSyncScheduler(db)
for _, org := range migratedOrgs {
    scheduler.ScheduleOrg(org.ID, "dv360", "hourly")
}
```

---

## Security Considerations

### Token Storage

**Encryption at Rest**:
```go
import (
    "cloud.google.com/go/kms/apiv1"
    "google.golang.org/api/option"
)

func encryptToken(plaintext string) ([]byte, error) {
    ctx := context.Background()
    client, _ := kms.NewKeyManagementClient(ctx)
    
    req := &kmspb.EncryptRequest{
        Name:      "projects/PROJECT/locations/LOCATION/keyRings/RING/cryptoKeys/KEY",
        Plaintext: []byte(plaintext),
    }
    
    result, _ := client.Encrypt(ctx, req)
    return result.Ciphertext, nil
}
```

**Token Rotation**:
- Refresh tokens before expiry (Meta: 60 days, Google: no expiry)
- Automatic re-auth flow if refresh fails
- Notify org admins on auth issues

### Access Control

**Service Account Permissions**:
```yaml
# Google Cloud IAM
roles:
  - roles/displayvideo.admin        # DV360 access
  - roles/adwords.admin              # Google Ads access
  - roles/cloudkms.cryptoKeyEncrypterDecrypter  # Token encryption
```

**Database Row-Level Security**:
```sql
-- Only connector service can access tokens
CREATE POLICY connector_service_access ON org_oauth_credentials
    FOR ALL
    TO connector_service_role
    USING (true);

REVOKE ALL ON org_oauth_credentials FROM PUBLIC;
```

---

## Risk Assessment

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| **Single OAuth app capacity** | High | Medium | Multi-app sharding ready, monitor utilization |
| **DSP API changes** | Medium | Low | Version management, connector abstraction layer |
| **Token expiry/revocation** | Medium | Medium | Auto-refresh, user notification, graceful degradation |
| **Rate limit miscalculation** | Medium | Low | Conservative defaults, real-time monitoring |
| **Quota exhaustion attack** | High | Low | Per-org limits, anomaly detection, circuit breaker |
| **DSP outage** | Low | Medium | Circuit breaker, retry with backoff, status page |

---

## Acceptance Criteria

### Phase 1 (Foundation)
- [ ] Both global and per-account rate limits enforced
- [ ] Zero rate limit violations in logs
- [ ] Usage metrics visible in Grafana

### Phase 2 (Scheduling)
- [ ] 100 orgs with evenly distributed syncs
- [ ] No spike at top of hour (< 20% variance)
- [ ] Peak utilization < 50%

### Phase 3 (Queue)
- [ ] Premium triggers complete < 30s (p95)
- [ ] Failed requests auto-retry
- [ ] System survives 10-min DSP outage

### Phase 4 (Multi-App)
- [ ] Can add/remove OAuth apps without downtime
- [ ] Orgs migrate between apps seamlessly
- [ ] Total capacity = sum of apps

### Phase 5 (Scale)
- [ ] 1000 orgs supported on single OAuth app
- [ ] p95 latency < 60s
- [ ] No rate limit hits under normal load

---

## Open Questions

1. **TTD Per-Advertiser Limits**: Contact TTD to confirm if per-advertiser limits exist
2. **Google Ads Tier**: Apply for Standard/Premium access tier
3. **Meta App Review**: Timeline for production app approval
4. **Retry Strategy**: Max retry attempts per request type
5. **Cache Strategy**: Should we cache campaign/account metadata?

---

## References

- [DV360 API Rate Limits](https://developers.google.com/display-video/api/limits)
- [Meta Marketing API Rate Limits](https://developers.facebook.com/docs/marketing-api/overview/rate-limiting)
- [Google Ads API Limits](https://developers.google.com/google-ads/api/docs/best-practices/rate-limits)
- [The Trade Desk API Docs](https://partner.thetradedesk.com/v3/portal/api/doc/)

---

## Appendix A: Rate Limit Comparison

| DSP | Global Limit | Per-Account Limit | Window | Notes |
|-----|-------------|-------------------|--------|-------|
| **DV360** | 1,500/min<br>700 writes/min | 300/min<br>150 writes/min | 1 minute | Write-intensive = 5× |
| **Meta** | 9,000 points | Dynamic formula | 5 minutes | Read=1pt, Write=3pt |
| **TTD** | 100/min | Unknown | 1 minute | Different limits per endpoint |
| **Google Ads** | 15,000/day | Unknown | 1 day | Tiered (Dev/Standard/Premium) |

---

## Appendix B: Example Scenarios

### Scenario 1: Morning Rush

```
8:00 AM: 200 premium orgs trigger manual refresh
- Each refresh: 30 API calls
- Total: 200 × 30 = 6,000 calls
- Time window: ~5 minutes
- Peak rate: 1,200 req/min

System behavior:
1. Priority queue accepts all 200 requests
2. Rate limiter allows first 1,500/min (125 orgs)
3. Remaining 75 orgs queued
4. Processed over next 3 minutes
5. All complete within 8 minutes
```

### Scenario 2: New Org Onboarding

```
Org connects DV360 account with 500 active campaigns

Initial sync:
1. Fetch account metadata: 2 calls
2. Fetch 500 campaigns (batch of 100): 5 calls
3. Fetch reports for all campaigns: 5 calls
4. Total: 12 calls

Rate limit check:
- Global: 1,500/min → 12 calls OK ✓
- Account: 300/min → 12 calls OK ✓
- Queue position: P2 (standard manual)
- Estimated completion: < 2 minutes
```

### Scenario 3: System Recovery After Outage

```
DV360 API down for 30 minutes

During outage:
- 500 orgs scheduled to sync
- All requests queued in P4 (retry queue)

After recovery:
1. Circuit breaker moves to half-open
2. Retry queue begins processing
3. Rate limiter throttles to avoid re-saturating DSP
4. 500 requests spread over 20 minutes
5. System returns to normal schedule
```

