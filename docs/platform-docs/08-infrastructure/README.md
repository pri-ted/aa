# ☁️ Infrastructure

> Kubernetes, deployment, and operations.

---

## Section Contents

| Document | Description |
| ---------- | ------------- |
| [Kubernetes Architecture](kubernetes.md) | Cluster design |
| [Deployment Strategy](deployment.md) | CI/CD and rollout |
| [Monitoring & Observability](monitoring.md) | Metrics, logs, traces |
| [Disaster Recovery](disaster-recovery.md) | Backup and recovery |

---

## Infrastructure Overview

```text
┌─────────────────────────────────────────────────────────────────────────────┐
│                       INFRASTRUCTURE OVERVIEW                               │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│   CLOUD PROVIDER (AWS / GCP / Azure)                                        │
│   ┌─────────────────────────────────────────────────────────────────────┐   │
│   │                                                                     │   │
│   │   ┌─────────────────────────────────────────────────────────────┐   │   │
│   │   │                   KUBERNETES CLUSTER                        │   │   │
│   │   │                                                             │   │   │
│   │   │   ┌────────────┐  ┌────────────┐  ┌────────────┐            │   │   │
│   │   │   │  Control   │  │  Worker    │  │  Worker    │            │   │   │
│   │   │   │  Plane     │  │  Pool 1    │  │  Pool 2    │            │   │   │
│   │   │   │  (3 nodes) │  │  (10 nodes)│  │  (5 nodes) │            │   │   │
│   │   │   └────────────┘  └────────────┘  └────────────┘            │   │   │
│   │   │                                                             │   │   │
│   │   └─────────────────────────────────────────────────────────────┘   │   │
│   │                                                                     │   │
│   │   ┌─────────────────────────────────────────────────────────────┐   │   │
│   │   │                   MANAGED SERVICES                          │   │   │
│   │   │   PostgreSQL │ Redis │ Object Storage │ DNS │ CDN           │   │   │
│   │   └─────────────────────────────────────────────────────────────┘   │   │
│   │                                                                     │   │
│   └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Kubernetes Namespaces

| Namespace | Purpose | Services |
| ----------- | --------- | ---------- |
| `platform-system` | Infrastructure | ArgoCD, Cert-Manager, Ingress |
| `platform-apps` | Application services | Auth, Config, Connector, etc. |
| `platform-data` | Data stores | PostgreSQL, ClickHouse, Redis, Kafka |
| `platform-monitoring` | Observability | Prometheus, Grafana, Loki, Tempo |

---

## Resource Requirements

### Production Cluster (1000 orgs)

| Component | Nodes | vCPU | Memory | Storage |
| ----------- | ------- | ------ | -------- | --------- |
| Control Plane | 3 | 4 | 16GB | 100GB |
| Worker Pool (Apps) | 10 | 8 | 32GB | 200GB |
| Worker Pool (Data) | 5 | 16 | 64GB | 2TB |
| **Total** | **18** | **148** | **464GB** | **12TB** |

### Cost Estimate (Monthly)

| Provider | Configuration | Cost |
| ---------- | --------------- | ------ |
| AWS (EKS) | us-east-1 | ~$12,000 |
| GCP (GKE) | us-central1 | ~$11,500 |
| Azure (AKS) | eastus | ~$12,500 |

---

## Deployment Pipeline

```text
┌─────────────────────────────────────────────────────────────────────────────┐
│                        DEPLOYMENT PIPELINE                                  │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│   ┌─────────┐    ┌─────────┐    ┌─────────┐    ┌─────────┐    ┌─────────┐   │
│   │  Code   │───▶│  Build  │───▶│  Test   │───▶│  Stage  │───▶│  Prod   │   │
│   │  Push   │    │  & Scan │    │  Suite  │    │ Deploy  │    │ Deploy  │   │
│   └─────────┘    └─────────┘    └─────────┘    └─────────┘    └─────────┘   │
│       │              │              │              │              │         │
│       ▼              ▼              ▼              ▼              ▼         │
│   GitHub         Container       Unit +         Canary        Progressive   │
│   Actions        Security        Integration    (10%)         Rollout       │
│                  Scan            Tests                                      │
│                                                                             │
│   Time:          ~5 min          ~10 min        ~15 min       ~30 min       │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## GitOps with ArgoCD

```yaml
# ArgoCD Application
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: platform-apps
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/org/platform-infra.git
    targetRevision: main
    path: kubernetes/apps
  destination:
    server: https://kubernetes.default.svc
    namespace: platform-apps
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

---

## Scaling Strategy

| Component | Type | Trigger | Min | Max |
| ----------- | ------ | --------- | ----- | ----- |
| Frontend | HPA | CPU > 70% | 3 | 10 |
| API Gateway | HPA | RPS > 1000 | 3 | 15 |
| App Services | HPA | CPU > 70% | 3 | 10 |
| Data Workers | KEDA | Queue depth | 3 | 20 |
| PostgreSQL | Manual | Monitoring | 1 | 3 |
| ClickHouse | Manual | Storage | 3 | 9 |

---

## Observability Stack

| Tool | Purpose | Retention |
| ------ | --------- | ----------- |
| **Prometheus** | Metrics | 15 days |
| **Grafana** | Dashboards | - |
| **Loki** | Logs | 30 days |
| **Tempo** | Traces | 7 days |
| **PagerDuty** | Alerting | - |

### Key Dashboards

- Platform Health Overview
- Service Performance (per service)
- Pipeline Execution Status
- Cost Tracking
- User Activity

---

## High Availability

| Component | Strategy | RTO | RPO |
| ----------- | ---------- | ----- | ----- |
| API Services | Multi-replica | 0 | 0 |
| PostgreSQL | Primary + 2 replicas | 5 min | 0 |
| ClickHouse | 3-node cluster | 10 min | 1 min |
| Redis | 3-node cluster | 1 min | 0 |
| Kafka | 3 brokers, RF=3 | 5 min | 0 |

---

## Disaster Recovery

### Backup Schedule

| Data | Frequency | Retention | Location |
| ------ | ----------- | ----------- | ---------- |
| PostgreSQL | Hourly | 30 days | Cross-region |
| ClickHouse | Daily | 90 days | Cross-region |
| Iceberg | Continuous | 1 year | Multi-region |
| Configs | Real-time | Forever | Git |

### Recovery Procedures

1. **Service failure** → Auto-restart via K8s
2. **Node failure** → Auto-replace via ASG
3. **Zone failure** → Failover to other zones
4. **Region failure** → Manual failover (RTO: 4h)

---

## Navigation

- **Previous:** [Security Architecture](../07-security/README.md)
- **Next:** [Development](../09-development/README.md)
