# platform-helm-charts

Reusable Helm chart templates for Campaign Lifecycle Platform services.

## Overview

This repository contains production-ready Helm chart templates for:
- **service-template**: Generic microservice template (for all 12 services)
- **database-template**: Database StatefulSet template

## Repository Structure

```
platform-helm-charts/
├── charts/
│   ├── service-template/          # Microservice template
│   │   ├── Chart.yaml
│   │   ├── values.yaml
│   │   ├── templates/
│   │   │   ├── deployment.yaml
│   │   │   ├── service.yaml
│   │   │   ├── hpa.yaml
│   │   │   ├── configmap.yaml
│   │   │   ├── secret.yaml
│   │   │   ├── serviceaccount.yaml
│   │   │   └── _helpers.tpl
│   │   └── tests/
│   │       └── test-connection.yaml
│   └── database-template/         # Database template
│       ├── Chart.yaml
│       ├── values.yaml
│       └── templates/
│           ├── statefulset.yaml
│           ├── service.yaml
│           └── pvc.yaml
├── examples/                      # Usage examples
│   ├── service-auth.yaml
│   └── postgres.yaml
└── docs/                          # Documentation
    └── USAGE.md
```

## Quick Start

### Service Template

Deploy any of the 12 microservices:

```bash
helm install service-auth ./charts/service-template \
  --set serviceName=auth \
  --set image.repository=campaign-platform/service-auth \
  --set image.tag=v1.0.0 \
  --set env.DATABASE_URL="postgresql://..." \
  --set env.REDIS_URL="redis://..."
```

### Database Template

Deploy a database:

```bash
helm install postgresql ./charts/database-template \
  --set databaseName=postgres \
  --set image.repository=postgres \
  --set image.tag=15-alpine \
  --set storage.size=50Gi
```

## Service Template

### Features

- ✅ Deployment with configurable replicas
- ✅ ClusterIP Service
- ✅ Horizontal Pod Autoscaler (HPA)
- ✅ ConfigMap & Secret support
- ✅ ServiceAccount with RBAC
- ✅ Resource limits & requests
- ✅ Liveness & readiness probes
- ✅ Pod disruption budget
- ✅ Network policies
- ✅ Security context

### Configuration

See [service-template/values.yaml](charts/service-template/values.yaml) for all options.

**Key configurations:**

```yaml
serviceName: "auth"              # Service name
replicaCount: 3                  # Number of replicas

image:
  repository: "service-auth"
  tag: "v1.0.0"

resources:
  limits:
    cpu: 500m
    memory: 512Mi
  requests:
    cpu: 100m
    memory: 128Mi

autoscaling:
  enabled: true
  minReplicas: 3
  maxReplicas: 10
  targetCPUUtilizationPercentage: 70
  targetMemoryUtilizationPercentage: 80

env:
  DATABASE_URL: "postgresql://..."
  REDIS_URL: "redis://..."
  LOG_LEVEL: "info"
```

## Database Template

### Features

- ✅ StatefulSet for stable storage
- ✅ Persistent Volume Claims
- ✅ Headless Service
- ✅ Init containers
- ✅ Volume snapshots
- ✅ Backup configurations

### Configuration

```yaml
databaseName: "postgres"
replicaCount: 1

storage:
  size: 50Gi
  storageClass: "standard"

resources:
  limits:
    cpu: 2000m
    memory: 4Gi
```

## Examples

### Deploy All 12 Services

```bash
# Auth Service
helm install service-auth ./charts/service-template \
  -f examples/service-auth.yaml

# Config Service  
helm install service-config ./charts/service-template \
  --set serviceName=config \
  --set image.repository=service-config

# Repeat for all 12 services...
```

### Custom Values File

Create `my-values.yaml`:

```yaml
serviceName: custom-service
replicaCount: 5
image:
  repository: my-org/my-service
  tag: v2.0.0
resources:
  limits:
    memory: 1Gi
env:
  CUSTOM_VAR: "value"
```

Deploy:

```bash
helm install my-service ./charts/service-template -f my-values.yaml
```

## Testing

### Lint Charts

```bash
helm lint charts/service-template
helm lint charts/database-template
```

### Dry Run

```bash
helm install --dry-run --debug service-test ./charts/service-template \
  --set serviceName=test \
  --set image.repository=nginx
```

### Template Rendering

```bash
helm template service-test ./charts/service-template \
  --set serviceName=test \
  --set image.repository=nginx
```

## CI/CD

GitHub Actions validates all charts on every PR:
- Helm lint
- Template rendering
- Values validation
- YAML syntax check

## Best Practices

1. **Always set serviceName**: Each service needs unique name
2. **Use specific image tags**: Avoid `latest` in production
3. **Set resource limits**: Prevent resource exhaustion
4. **Enable HPA**: For auto-scaling based on load
5. **Configure probes**: Health checks for reliability
6. **Use secrets**: Never hardcode sensitive data

## Upgrading

```bash
# Upgrade with new values
helm upgrade service-auth ./charts/service-template \
  --set image.tag=v1.1.0

# Rollback if needed
helm rollback service-auth 1
```

## Documentation

- [Usage Guide](docs/USAGE.md) - Detailed usage examples
- [Service Template README](charts/service-template/README.md)
- [Database Template README](charts/database-template/README.md)

## Support

- **Issues:** GitHub Issues
- **Slack:** #platform-helm
- **Email:** platform-team@campaign-platform.com

---

**Chart Version:** 1.0.0  
**Last Updated:** 2026-01-06
