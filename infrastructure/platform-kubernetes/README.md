# platform-kubernetes

Kubernetes deployment manifests for AtomicAds Platform.

## Structure

```
platform-kubernetes/
├── base/                  # Base configurations (namespaces, policies, quotas)
├── overlays/                  # Base configurations Customization overlays (local, dev, staging, production)
├── platform-apps/              # All 12 service deployments
├── platform-data/             # Database deployments
├── platform-operators/             # Database operators deployments
├── platform-systems/        # Platform infrastructure (Vault, ArgoCD)
├── platform-monitoring/        # Platform monitoring infrastructure (Grafana, Loki, Tempo, Prometheus)
└── ingress/              # Ingress configurations
```

## Services

Each service follows this structure:

```
platform-apps/<service-name>/
├── base/                  # Base Kubernetes manifests
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── configmap.yaml
│   └── kustomization.yaml
└── overlays/              # Environment-specific configs
    ├── dev/
    ├── staging/
    └── production/
```

## Deployment Process

### Developer Workflow (Code)

1. Developer writes code in `service-auth` repo
2. Developer builds Docker image
3. Developer pushes image to registry
4. Developer creates PR to update image tag here

### Platform Team Workflow (Deployment)

1. Review PR with new image tag
2. Merge PR
3. ArgoCD automatically deploys

## Using Kustomize

```bash
# View dev manifests
kubectl kustomize platform-apps/auth/overlays/dev

# Apply dev manifests
kubectl apply -k platform-apps/auth/overlays/dev

# Apply production manifests
kubectl apply -k platform-apps/auth/overlays/production
```

## Using ArgoCD

```bash
# Create ArgoCD application
kubectl apply -f infrastructure/argocd/app-auth.yaml

# Sync application
argocd app sync service-auth

# Check status
argocd app get service-auth
```

## Environment Variables

Each service can be configured via:

- ConfigMaps (in `base/configmap.yaml`)
- Secrets (managed by Vault or sealed-secrets)
- Environment overlays (in `overlays/*/kustomization.yaml`)

## Adding New Service

1. Create directory structure:

```bash
   mkdir -p platform-apps/new-service/{base,overlays/{dev,staging,production}}
```

2. Copy from existing service:

```bash
   cp -r platform-apps/auth/base/* services/new-service/base/
```

3. Update names and configurations

4. Create ArgoCD application:

```bash
   cp platform-systems/argocd/app-auth.yaml infrastructure/argocd/app-new-service.yaml
   # Edit with new service name and path
```

## Repository Separation

**THIS repo (platform-kubernetes):**

- ALL Kubernetes manifests
- Deployment configurations
- Environment overlays
- Controlled by Platform Team

**Service repos (e.g., service-auth):**

- Application code ONLY
- Dockerfiles
- CI/CD for building
- Controlled by Developers

**Developers NEVER touch this repo's manifests directly.**
**Platform team reviews and merges all deployment changes.**

## Multi-Tenancy

All services use `org_id` for data partitioning:

- Database queries filter by `org_id`
- No service-level isolation needed
- Single deployment serves all organizations

## Monitoring

- Prometheus scrapes metrics from all services
- Grafana dashboards in `platform-monitoring` Repository
- AlertManager rules in `platform-monitoring` Repository

## Security

- Network policies enforce namespace isolation
- Secrets managed by Vault
- Resource quotas prevent resource exhaustion
- RBAC configured per namespace

## Scaling

- HPA configured for each service
- Min replicas: 2 (production), 1 (dev)
- Max replicas: 5 (production), 2 (dev)
- Scale based on CPU/memory

## Contact

Platform Team: platform-team@atomicads.ai
