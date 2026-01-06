# Monitoring & Observability

> Metrics, logs, traces, and alerting.

---

## Observability Stack

| Component | Tool | Purpose |
| ----------- | ------ | --------- |
| Metrics | Prometheus | Time-series metrics |
| Visualization | Grafana | Dashboards |
| Logs | Loki | Log aggregation |
| Traces | Tempo | Distributed tracing |
| Alerting | PagerDuty | On-call management |

---

## Metrics (Prometheus)

### Key Metrics

**Application Metrics**

| Metric | Type | Description |
| -------- | ------ | ------------- |
| http_requests_total | Counter | Total HTTP requests |
| http_request_duration_seconds | Histogram | Request latency |
| http_requests_in_flight | Gauge | Active requests |

**Business Metrics**

| Metric | Type | Description |
| -------- | ------ | ------------- |
| pipelines_executed_total | Counter | Pipeline executions |
| etl_records_processed | Counter | Records processed |
| rules_evaluated_total | Counter | Rule evaluations |

### ServiceMonitor

```yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: auth-service
spec:
  selector:
    matchLabels:
      app: auth-service
  endpoints:
    - port: http
      path: /metrics
      interval: 15s
```

---

## Logging (Loki)

### Log Format

```json
{
  "timestamp": "2024-12-23T10:00:00Z",
  "level": "info",
  "service": "auth-service",
  "trace_id": "abc123",
  "user_id": 456,
  "org_id": 789,
  "message": "User logged in",
  "duration_ms": 45
}
```

### Log Queries (LogQL)

```logql
# Error logs for auth-service
{app="auth-service"} |= "error"

# Slow requests (>1s)
{app="query-service"} | json | duration_ms > 1000

# Login failures
{app="auth-service"} |= "login_failed" | json | count_over_time([1h])
```

---

## Tracing (Tempo)

### Trace Context

```go
// Propagate trace context
ctx := otel.GetTextMapPropagator().Extract(
    context.Background(),
    propagation.HeaderCarrier(r.Header),
)

// Start span
ctx, span := tracer.Start(ctx, "auth.login")
defer span.End()

// Add attributes
span.SetAttributes(
    attribute.String("user.email", email),
    attribute.Int("org.id", orgID),
)
```

### Trace Queries

```text
# Find slow traces
duration > 1s

# Find error traces
status = error

# Find specific user
resource.user_id = 123
```

---

## Dashboards

### Platform Overview

- Total requests/second
- Error rate (%)
- P50/P95/P99 latency
- Active pipelines
- DSP connection health

### Service Health

- CPU/Memory utilization
- Request rate per service
- Error rate per service
- Pod count and status

### Data Pipeline

- Records ingested (Bronze)
- Records processed (Silver)
- Records aggregated (Gold)
- Data quality score
- Pipeline success rate

---

## Alerting

### Alert Rules

```yaml
groups:
  - name: platform-alerts
    rules:
      - alert: HighErrorRate
        expr: |
          sum(rate(http_requests_total{status=~"5.."}[5m])) 
          / sum(rate(http_requests_total[5m])) > 0.01
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "High error rate detected"
          
      - alert: PodCrashLooping
        expr: |
          rate(kube_pod_container_status_restarts_total[15m]) > 0
        for: 5m
        labels:
          severity: warning
```

### PagerDuty Integration

```yaml
receivers:
  - name: pagerduty-critical
    pagerduty_configs:
      - service_key: ${PAGERDUTY_KEY}
        severity: critical

route:
  receiver: pagerduty-critical
  routes:
    - match:
        severity: critical
      receiver: pagerduty-critical
```

---

## SLOs

| Service | SLI | Target |
| --------- | ----- | --------| 
| API Gateway | Availability | 99.9% |
| Auth Service | Login latency P99 | < 500ms |
| Query Service | Query latency P95 | < 200ms |
| ETL Pipeline | Success rate | 99.5% |

---

## Navigation

- **Up:** [Infrastructure](README.md)
- **Previous:** [Deployment](deployment.md)
- **Next:** [Disaster Recovery](disaster-recovery.md)
