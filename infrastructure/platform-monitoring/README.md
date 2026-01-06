# platform-monitoring

Observability stack for Campaign Lifecycle Platform - Grafana dashboards, Prometheus alerts, and runbooks.

## Overview

Complete monitoring solution with:
- **10+ Grafana Dashboards** - Platform, services, data, infrastructure
- **50+ Prometheus Alerts** - Critical, warning, info levels
- **Runbooks** - Step-by-step troubleshooting guides
- **Custom Exporters** - Business metrics exporters

## Repository Structure

```
platform-monitoring/
├── dashboards/                    # Grafana dashboards
│   ├── platform/                  # Platform overview
│   ├── services/                  # Service-specific
│   ├── data/                      # Database dashboards
│   └── infrastructure/            # Infrastructure metrics
├── alerts/                        # Prometheus alert rules
│   ├── critical/                  # Critical alerts (PagerDuty)
│   ├── warning/                   # Warning alerts (Slack)
│   └── info/                      # Info alerts (logging)
├── runbooks/                      # Troubleshooting guides
├── exporters/                     # Custom exporters
├── scripts/                       # Helper scripts
└── docs/                          # Documentation
```

## Dashboards

### Platform Dashboards

| Dashboard | Description | Panels |
|-----------|-------------|--------|
| platform-overview.json | High-level platform metrics | 10 |
| campaign-performance.json | Campaign metrics | 8 |
| etl-pipeline.json | ETL job monitoring | 6 |

### Service Dashboards

| Dashboard | Description |
|-----------|-------------|
| service-auth.json | Authentication metrics |
| service-connector.json | DSP connector health |
| service-etl.json | ETL orchestration |

### Data Dashboards

| Dashboard | Description |
|-----------|-------------|
| postgresql.json | PostgreSQL performance |
| clickhouse.json | ClickHouse analytics |
| redis.json | Redis cache metrics |

## Alerts

### Critical Alerts (PagerDuty)

- ServiceDown - Service unavailable >5min
- DatabaseDown - Database unreachable >2min
- DiskSpaceCritical - Disk <5% free
- HighErrorRate - Error rate >5% for 10min
- APILatencyHigh - P95 latency >2s for 15min

### Warning Alerts (Slack)

- HighMemoryUsage - Memory >80% for 10min
- PodCrashLooping - Frequent restarts
- ETLPipelineLagging - No successful run >1hr
- DSPRateLimitNearExhaustion - Rate limit <20%

### Info Alerts (Logging)

- NewDeployment - Service deployed
- ConfigurationChanged - Config updated
- ScalingEvent - HPA scaled pods

## Quick Start

### Import Dashboards

```bash
# Via Grafana UI
1. Login to Grafana
2. Go to Dashboards → Import
3. Upload JSON file from dashboards/

# Via API
./scripts/import-dashboards.sh
```

### Apply Alerts

```bash
# Apply to Kubernetes
kubectl apply -f alerts/critical/
kubectl apply -f alerts/warning/

# Or use script
./scripts/apply-alerts.sh
```

### View Runbooks

```bash
# Open runbook for specific alert
cat runbooks/ServiceDown.md
```

## Documentation

- [Dashboard Guide](docs/DASHBOARDS.md)
- [Alert Configuration](docs/ALERTS.md)
- [Runbook Template](docs/RUNBOOK_TEMPLATE.md)
- [Custom Exporters](docs/EXPORTERS.md)

## Support

- **Slack:** #platform-monitoring
- **Email:** platform-team@campaign-platform.com
