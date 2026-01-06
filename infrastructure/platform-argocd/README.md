# platform-argocd

GitOps configuration for Campaign Lifecycle Platform using ArgoCD.

## Overview

This repository contains all ArgoCD Application definitions for deploying the entire Campaign Lifecycle Platform using the **App of Apps** pattern. It follows the platform's architectural principles of metadata-driven automation and self-service deployment.

## Repository Structure

```
platform-argocd/
├── apps/                           # Application definitions (18 total)
│   ├── infrastructure/             # Infrastructure apps (3)
│   │   ├── vault.yaml             # HashiCorp Vault for secrets
│   │   ├── prometheus.yaml        # Metrics collection
│   │   └── grafana.yaml           # Dashboards and visualization
│   ├── data/                       # Data layer apps (3)
│   │   ├── postgresql.yaml        # Primary OLTP database
│   │   ├── clickhouse.yaml        # Analytics OLAP database
│   │   └── redis.yaml             # Cache and sessions
│   └── services/                   # Microservices (12)
│       ├── service-auth.yaml      # Authentication & authorization
│       ├── service-config.yaml    # Configuration management
│       ├── service-connector.yaml # DSP integrations
│       ├── service-etl.yaml       # ETL orchestration
│       ├── service-bronze.yaml    # Bronze data layer (raw)
│       ├── service-silver.yaml    # Silver data layer (cleaned)
│       ├── service-gold.yaml      # Gold data layer (enriched)
│       ├── service-calculation.yaml # Metric calculations
│       ├── service-rules.yaml     # Business rules engine
│       ├── service-analytics.yaml # Analytics engine
│       ├── service-notification.yaml # Notification delivery
│       └── service-query.yaml     # Query service
├── projects/                       # ArgoCD Projects (RBAC)
│   └── projects.yaml              # 3 projects: infra, data, services
├── app-of-apps/                    # Root application
│   ├── root.yaml                  # Root ArgoCD application
│   └── kustomization.yaml         # References all 18 apps
├── envs/                           # Environment-specific configs
│   ├── dev/                       # Development environment
│   ├── staging/                   # Staging environment
│   └── production/                # Production environment
├── docs/                           # Documentation
│   ├── DEPLOYMENT.md              # Deployment guide
│   ├── TROUBLESHOOTING.md         # Common issues
│   └── ARCHITECTURE.md            # ArgoCD architecture
├── scripts/                        # Helper scripts
│   ├── deploy.sh                  # Deploy platform
│   ├── sync-all.sh                # Sync all applications
│   └── rollback.sh                # Rollback applications
└── .github/workflows/              # CI/CD
    └── validate.yaml              # Validate manifests
```

## Quick Start

### Prerequisites

- Kubernetes cluster (1.28+)
- kubectl configured and authenticated
- ArgoCD CLI installed (optional, for CLI operations)

### Installation

#### 1. Install ArgoCD

```bash
# Create ArgoCD namespace
kubectl create namespace argocd

# Install ArgoCD
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for ArgoCD to be ready (2-3 minutes)
kubectl wait --for=condition=available --timeout=300s \
  deployment/argocd-server -n argocd

echo "✅ ArgoCD installed successfully"
```

#### 2. Access ArgoCD UI

```bash
# Get admin password
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d
echo ""

# Port-forward to access UI
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Open browser: https://localhost:8080
# Username: admin
# Password: [from above command]
```

#### 3. Install ArgoCD CLI (Optional)

```bash
# macOS
brew install argocd

# Linux
curl -sSL -o /usr/local/bin/argocd \
  https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
chmod +x /usr/local/bin/argocd

# Login via CLI
argocd login localhost:8080 --insecure
```

#### 4. Deploy ArgoCD Projects

```bash
# Apply the 3 projects (infra, data, services)
kubectl apply -f projects/projects.yaml

# Verify projects created
kubectl get appproject -n argocd

# Expected output:
# NAME                      AGE
# default                   5m
# platform-infrastructure   10s
# platform-data             10s
# platform-services         10s
```

#### 5. Deploy Platform (App of Apps)

```bash
# Apply root application (deploys all 18 apps)
kubectl apply -f app-of-apps/root.yaml

# Watch deployment progress
kubectl get applications -n argocd --watch

# Or via ArgoCD CLI
argocd app list
argocd app sync platform --watch
```

#### 6. Verify Deployment

```bash
# Check all applications
argocd app list

# Expected: 18 applications (1 root + 3 infra + 3 data + 12 services)
# All should show Status: Synced, Health: Healthy

# Check pods in each namespace
kubectl get pods -n platform-system      # Infrastructure
kubectl get pods -n platform-data        # Databases
kubectl get pods -n platform-apps        # Services
kubectl get pods -n platform-monitoring  # Monitoring
```

## Applications

### Infrastructure Layer (3 apps)

| Application | Purpose | Namespace | Sync Wave |
|------------|---------|-----------|-----------|
| **vault** | Secrets management (HashiCorp Vault) | platform-system | 0 |
| **prometheus** | Metrics collection & alerting | platform-monitoring | 0 |
| **grafana** | Dashboards & visualization | platform-monitoring | 0 |

### Data Layer (3 apps)

| Application | Purpose | Namespace | Sync Wave |
|------------|---------|-----------|-----------|
| **postgresql** | Primary OLTP database (multi-tenant) | platform-data | 1 |
| **clickhouse** | Analytics OLAP database | platform-data | 1 |
| **redis** | Cache, sessions, rate limiting | platform-data | 1 |

### Service Layer (12 apps)

| Application | Purpose | Namespace | Sync Wave |
|------------|---------|-----------|-----------|
| **service-auth** | Authentication & authorization (RBAC) | platform-apps | 2 |
| **service-config** | Configuration & template management | platform-apps | 2 |
| **service-connector** | DSP API integrations (DV360, Meta, TTD) | platform-apps | 2 |
| **service-etl** | ETL orchestration & scheduling | platform-apps | 2 |
| **service-bronze** | Bronze layer (raw data ingestion) | platform-apps | 2 |
| **service-silver** | Silver layer (data cleaning) | platform-apps | 2 |
| **service-gold** | Gold layer (data enrichment) | platform-apps | 2 |
| **service-calculation** | Metric calculations & aggregations | platform-apps | 2 |
| **service-rules** | Business rules engine | platform-apps | 2 |
| **service-analytics** | Analytics & reporting | platform-apps | 2 |
| **service-notification** | Notification delivery (email, Slack, webhooks) | platform-apps | 2 |
| **service-query** | Query API for Gold layer | platform-apps | 2 |

## ArgoCD Projects

Projects provide RBAC and security boundaries:

### platform-infrastructure

- **Purpose:** Core infrastructure components
- **Namespaces:** platform-system, platform-monitoring, argocd
- **Source Repos:** platform-kubernetes, public Helm charts
- **Roles:**
  - `admin`: Full access (platform team)
  - `read-only`: View-only access (developers)

### platform-data

- **Purpose:** Data layer services
- **Namespaces:** platform-data
- **Source Repos:** platform-kubernetes, platform-databases, Bitnami charts
- **Roles:**
  - `admin`: Full access (platform team, data team)
  - `read-only`: View-only access (developers)

### platform-services

- **Purpose:** Application microservices
- **Namespaces:** platform-apps
- **Source Repos:** platform-kubernetes, platform-helm-charts
- **Roles:**
  - `admin`: Full access (platform team)
  - `developer`: Deploy & sync (developers)
  - `read-only`: View-only access (viewers)

## App of Apps Pattern

The root application (`app-of-apps/root.yaml`) automatically deploys all other applications:

```
platform (root)
├── Projects (3)
│   ├── platform-infrastructure
│   ├── platform-data
│   └── platform-services
├── Infrastructure Apps (3)
│   ├── vault
│   ├── prometheus
│   └── grafana
├── Data Apps (3)
│   ├── postgresql
│   ├── clickhouse
│   └── redis
└── Service Apps (12)
    ├── service-auth
    ├── service-config
    ├── ... (10 more services)
```

**Benefits:**
- Single command deploys everything
- Easy cluster bootstrap
- Consistent deployment across environments
- Centralized management

## Sync Policies

### Automated Sync

All applications use automated sync:

```yaml
syncPolicy:
  automated:
    prune: true      # Delete resources not in Git
    selfHeal: true   # Automatically fix drift
  syncOptions:
    - CreateNamespace=true
  retry:
    limit: 5
    backoff:
      duration: 5s
      factor: 2
      maxDuration: 3m
```

### Sync Waves

Applications deploy in order using sync waves:

- **Wave 0:** Infrastructure (Vault, Prometheus, Grafana)
- **Wave 1:** Data layer (PostgreSQL, ClickHouse, Redis)
- **Wave 2:** Services (All 12 microservices)

This ensures dependencies are ready before dependent services start.

## Environment Management

### Development

```yaml
Environment: dev
Branch: main
Sync: Automated
Self-Heal: Enabled
Replicas: 1-2 per service
Resources: Minimal (requests only)
```

### Staging

```yaml
Environment: staging
Branch: staging
Sync: Automated
Self-Heal: Enabled
Replicas: 2-3 per service
Resources: Production-like
```

### Production

```yaml
Environment: production
Branch/Tag: v1.0.0 (tagged releases)
Sync: Manual approval initially, then automated
Self-Heal: Enabled (after validation)
Replicas: 3-10 per service (with HPA)
Resources: Full production limits
```

## Common Operations

### Deploy New Service

```bash
# 1. Create application definition
cat > apps/services/service-new.yaml << EOF
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: service-new
  namespace: argocd
  annotations:
    argocd.argoproj.io/sync-wave: "2"
spec:
  project: platform-services
  source:
    repoURL: https://github.com/AtomicAds/platform-kubernetes
    targetRevision: main
    path: services/new/overlays/dev
  destination:
    server: https://kubernetes.default.svc
    namespace: platform-apps
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
EOF

# 2. Add to app-of-apps kustomization
echo "  - ../apps/services/service-new.yaml" >> app-of-apps/kustomization.yaml

# 3. Commit and push
git add .
git commit -m "Add service-new application"
git push

# 4. ArgoCD auto-detects and deploys
argocd app sync platform
```

### Update Service Image

**Note:** Image updates happen in `platform-kubernetes` repo, not here.

This repo only contains ArgoCD app definitions. To update a service:

1. Update image tag in `platform-kubernetes` repo
2. Commit and push
3. ArgoCD auto-syncs the change

### Sync Application

```bash
# Sync single app
argocd app sync service-auth

# Sync with prune
argocd app sync service-auth --prune

# Sync all apps
./scripts/sync-all.sh

# Hard refresh (re-fetch from Git)
argocd app sync service-auth --force
```

### Rollback Application

```bash
# View history
argocd app history service-auth

# Rollback to previous version
argocd app rollback service-auth

# Rollback to specific revision
argocd app rollback service-auth 5

# Or via Git revert
git revert HEAD
git push
```

### Delete Application

```bash
# Delete application (keeps resources in cluster)
argocd app delete service-auth

# Delete application and all resources
argocd app delete service-auth --cascade

# Delete via kubectl
kubectl delete application service-auth -n argocd
```

## Monitoring

### Application Health

ArgoCD automatically monitors health for:

- **Deployments:** All replicas ready
- **StatefulSets:** All replicas ready
- **Services:** Endpoints available
- **Pods:** Running status
- **Jobs:** Completed successfully
- **Custom Resources:** Based on health checks

### Sync Status

- **Synced:** Git matches cluster state
- **OutOfSync:** Git differs from cluster
- **Unknown:** Cannot determine status
- **Progressing:** Sync in progress

### View Status

```bash
# List all applications
argocd app list

# Get app details
argocd app get service-auth

# View sync status
argocd app status service-auth

# Watch sync
argocd app sync service-auth --watch

# View resources
argocd app resources service-auth
```

### Notifications

Configure notifications in `argocd-notifications-cm` ConfigMap:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: argocd-notifications-cm
  namespace: argocd
data:
  service.slack: |
    token: $slack-token
  
  template.app-deployed: |
    message: |
      {{.app.metadata.name}} deployed to {{.app.spec.destination.namespace}}
      Revision: {{.app.status.sync.revision}}
  
  trigger.on-deployed: |
    - send: [app-deployed]
  
  trigger.on-sync-failed: |
    - send: [app-sync-failed]
```

## Troubleshooting

### Application Won't Sync

```bash
# Check sync status
argocd app get service-auth

# Common issues:
# 1. Invalid manifest
kubectl apply --dry-run=client -f apps/services/service-auth.yaml

# 2. RBAC issues
kubectl auth can-i create deployment --namespace platform-apps --as system:serviceaccount:argocd:argocd-application-controller

# 3. Network issues
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-application-controller
```

### Application Stuck OutOfSync

```bash
# Check diff
argocd app diff service-auth

# Force sync
argocd app sync service-auth --force

# Hard refresh
argocd app get service-auth --refresh --hard

# Prune extra resources
argocd app sync service-auth --prune
```

### Sync Fails

```bash
# View sync result
argocd app get service-auth

# Check recent events
kubectl get events -n platform-apps --sort-by='.lastTimestamp'

# View ArgoCD logs
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-application-controller --tail=100

# Check application controller logs
kubectl logs -n argocd deployment/argocd-application-controller
```

### Health Degraded

```bash
# Check pod status
kubectl get pods -n platform-apps -l app=service-auth

# View pod logs
kubectl logs -l app=service-auth -n platform-apps --tail=50

# Describe pod
kubectl describe pod <pod-name> -n platform-apps

# Check events
kubectl get events -n platform-apps --field-selector involvedObject.name=<pod-name>
```

## Best Practices

### 1. Use App of Apps Pattern

✅ **DO:**
- Deploy everything through root app
- Single entry point for platform
- Easy to bootstrap new clusters

❌ **DON'T:**
- Create applications manually
- Deploy apps individually

### 2. Enable Automated Sync

✅ **DO:**
- Use auto-sync for dev/staging
- Enable self-heal to fix drift
- Set retry policies

❌ **DON'T:**
- Disable auto-sync without reason
- Make manual cluster changes

### 3. Use Sync Waves

✅ **DO:**
- Order deployments with waves
- Infrastructure first (wave 0)
- Data layer next (wave 1)
- Services last (wave 2)

❌ **DON'T:**
- Deploy everything simultaneously
- Ignore dependencies

### 4. Tag Production Releases

✅ **DO:**
- Deploy from tags (v1.0.0)
- Use semantic versioning
- Document release notes

❌ **DON'T:**
- Deploy from main/master
- Use floating tags (latest)

### 5. Monitor Sync Status

✅ **DO:**
- Set up notifications
- Watch for OutOfSync
- Alert on sync failures

❌ **DON'T:**
- Ignore sync status
- Assume everything works

### 6. Separate Concerns

✅ **DO:**
- This repo: ArgoCD app definitions
- platform-kubernetes: K8s manifests
- Service repos: Application code

❌ **DON'T:**
- Mix application code here
- Put K8s manifests here

## Security

### RBAC

Projects enforce RBAC at ArgoCD level:

```yaml
# Platform team: Full access
roles:
  - name: admin
    policies:
      - p, proj:platform-*:admin, applications, *, *, allow

# Developers: Limited access
roles:
  - name: developer
    policies:
      - p, proj:platform-services:developer, applications, get, *, allow
      - p, proj:platform-services:developer, applications, sync, *, allow
```

### SSO Integration

Configure SSO in `argocd-cm` ConfigMap:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: argocd-cm
  namespace: argocd
data:
  url: https://argocd.company.com
  
  dex.config: |
    connectors:
    - type: github
      id: github
      name: GitHub
      config:
        clientID: $github-client-id
        clientSecret: $github-client-secret
        orgs:
        - name: AtomicAds
          teams:
          - platform-team
          - developers
```

### Audit Logging

Enable audit logs in ArgoCD:

```yaml
# argocd-cm ConfigMap
data:
  application.resourceTrackingMethod: annotation
  
# View audit logs
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-server | grep audit
```

## Documentation

- [Deployment Guide](docs/DEPLOYMENT.md) - Complete deployment instructions
- [Troubleshooting Guide](docs/TROUBLESHOOTING.md) - Common issues and solutions
- [Architecture](docs/ARCHITECTURE.md) - ArgoCD architecture details
- [ArgoCD Official Docs](https://argo-cd.readthedocs.io/) - Official documentation

## Scripts

- `scripts/deploy.sh` - Deploy platform
- `scripts/sync-all.sh` - Sync all applications
- `scripts/rollback.sh` - Rollback applications
- `scripts/health-check.sh` - Check application health

## CI/CD

GitHub Actions workflow validates all manifests on PR:

```yaml
# .github/workflows/validate.yaml
- Lint YAML files
- Validate ArgoCD applications
- Check for duplicate names
- Verify project references
```

## Support

- **Documentation:** See `docs/` directory
- **Issues:** GitHub Issues in this repository
- **Slack:** #platform-argocd
- **Email:** platform-team@AtomicAds.com

## References

- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [App of Apps Pattern](https://argo-cd.readthedocs.io/en/stable/operator-manual/cluster-bootstrapping/)
- [Sync Waves](https://argo-cd.readthedocs.io/en/stable/user-guide/sync-waves/)
- [Best Practices](https://argo-cd.readthedocs.io/en/stable/user-guide/best_practices/)

---

**Platform Version:** 1.0.0  
**ArgoCD Version:** 2.10+  
**Kubernetes Version:** 1.28+  
**Last Updated:** 2026-01-06
