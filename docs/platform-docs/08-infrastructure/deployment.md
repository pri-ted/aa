# Deployment Strategy

> CI/CD pipelines, GitOps, and release management.

---

## Deployment Overview

| Component | Tool | Strategy |
| ----------- | ------ | ---------- |
| Source Control | GitHub | Trunk-based |
| CI | GitHub Actions | Build + Test |
| CD | ArgoCD | GitOps |
| Registry | ECR / GCR | Immutable tags |

---

## CI Pipeline

```yaml
name: Build and Test
on:
  push:
    branches: [main]
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Run tests
        run: make test
      - name: Build image
        run: docker build -t platform/service:${GITHUB_SHA} .
      - name: Push to registry
        run: docker push platform/service:${GITHUB_SHA}
```

---

## GitOps with ArgoCD

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: auth-service
  namespace: argocd
spec:
  project: platform
  source:
    repoURL: https://github.com/org/platform-k8s
    path: apps/auth-service
    targetRevision: main
  destination:
    server: https://kubernetes.default.svc
    namespace: platform-apps
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

---

## Deployment Strategies

### Rolling Update (Default)

```yaml
strategy:
  type: RollingUpdate
  rollingUpdate:
    maxSurge: 25%
    maxUnavailable: 0
```

### Canary Deployment

```yaml
# Using Argo Rollouts
apiVersion: argoproj.io/v1alpha1
kind: Rollout
spec:
  strategy:
    canary:
      steps:
        - setWeight: 10
        - pause: {duration: 5m}
        - setWeight: 50
        - pause: {duration: 10m}
        - setWeight: 100
```

---

## Environment Promotion

```text
┌─────────┐     ┌─────────┐     ┌─────────┐
│   Dev   │ ──▶ │ Staging │ ──▶ │  Prod   │
└─────────┘     └─────────┘     └─────────┘
    │               │               │
    ▼               ▼               ▼
 Auto-deploy    Auto-deploy    Manual gate
```

---

## Rollback Procedure

```bash
# Via ArgoCD CLI
argocd app rollback auth-service

# Via kubectl
kubectl rollout undo deployment/auth-service -n platform-apps

# Via Git revert
git revert HEAD
git push origin main
```

---

## Navigation

- **Up:** [Infrastructure](README.md)
- **Previous:** [Kubernetes](kubernetes.md)
- **Next:** [Monitoring](monitoring.md)
