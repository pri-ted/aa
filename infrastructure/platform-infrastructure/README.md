# Platform Infrastructure

> Cloud-agnostic infrastructure as code for the Campaign Lifecycle Platform

## Overview

This repository contains all infrastructure code for deploying the platform across multiple cloud providers and bare-metal environments.

**Supported Platforms:**

- AWS EKS (Primary - Phase 1)
- GCP GKE (Planned)
- Bare Metal Kubernetes (Planned)

## Repository Structure

```
platform-infrastructure/
├── terraform/                      # Infrastructure as Code
│   ├── modules/                    # Reusable Terraform modules
│   │   ├── kubernetes-cluster/     # Cloud-agnostic K8s cluster
│   │   ├── networking/             # VPC, subnets, security groups
│   │   ├── databases/              # PostgreSQL, ClickHouse operators
│   │   ├── vault/                  # HashiCorp Vault setup
│   │   └── monitoring/             # Prometheus, Grafana, Loki
│   ├── environments/               # Environment-specific configs
│   │   ├── dev/
│   │   ├── staging/
│   │   └── production/
│   └── providers/                  # Provider-specific implementations
│       ├── aws/                    # AWS EKS configurations
│       ├── gcp/                    # GCP GKE configurations
│       └── baremetal/              # Bare metal K8s
│
├── kubernetes/                     # Kubernetes manifests
│   ├── base/                       # Base configurations (Kustomize)
│   │   ├── namespaces/
│   │   ├── network-policies/
│   │   └── resource-quotas/
│   ├── platform-system/            # Core platform infrastructure
│   │   ├── argocd/
│   │   ├── vault/
│   │   ├── cert-manager/
│   │   ├── external-secrets/
│   │   ├── ingress-nginx/
│   │   └── sealed-secrets/
│   ├── platform-data/              # Data layer operators
│   │   ├── postgres-operator/
│   │   ├── clickhouse-operator/
│   │   ├── redis-operator/
│   │   ├── kafka/
│   │   └── zookeeper/
│   ├── platform-monitoring/        # Observability stack
│   │   ├── prometheus/
│   │   ├── grafana/
│   │   ├── loki/
│   │   ├── tempo/
│   │   └── alertmanager/
│   └── overlays/                   # Environment overlays
│       ├── dev/
│       ├── staging/
│       └── production/
│
├── argocd/                         # ArgoCD Applications
│   ├── apps/                       # Application definitions
│   ├── projects/                   # ArgoCD Projects
│   └── app-of-apps/                # App-of-apps pattern
│
├── helm/                           # Custom Helm charts
│   └── platform-operators/
│
├── scripts/                        # Automation scripts
│   ├── setup-cluster.sh
│   ├── bootstrap-argocd.sh
│   ├── vault-init.sh
│   └── destroy-cluster.sh
│
├── docs/                           # Documentation
│   ├── setup-guide.md
│   ├── runbooks/
│   └── architecture/
│
├── .github/                        # CI/CD
│   └── workflows/
│       ├── terraform-plan.yml
│       ├── terraform-apply.yml
│       └── k8s-validate.yml
│
├── Makefile                        # Common commands
├── .gitignore
└── .pre-commit-config.yaml
```

## Quick Start

### Prerequisites

- Terraform >= 1.6
- kubectl >= 1.28
- helm >= 3.12
- AWS CLI / gcloud / kubectl (depending on provider)
- ArgoCD CLI
- Vault CLI

### 1. Clone Repository

```bash
git clone https://github.com/AtomicAds/platform-infrastructure.git
cd platform-infrastructure
```

### 2. Configure Cloud Provider

**For AWS (Phase 1):**

```bash
# Export AWS credentials
export AWS_PROFILE=platform-dev
export AWS_REGION=us-east-1

# Initialize Terraform backend
cd terraform/providers/aws/dev
terraform init
```

**For GCP (Future):**

```bash
export GOOGLE_PROJECT=platform-dev
export GOOGLE_REGION=us-central1
```

### 3. Deploy Infrastructure

```bash
# Using Makefile
make deploy-aws-dev

# Or manual Terraform
cd terraform/providers/aws/dev
terraform plan
terraform apply
```

### 4. Bootstrap GitOps

```bash
# Install ArgoCD
./scripts/bootstrap-argocd.sh

# Deploy all platform apps
kubectl apply -f argocd/app-of-apps/
```

### 5. Initialize Vault

```bash
./scripts/vault-init.sh
```

## Environment Strategy

| Environment    | Purpose                   | Cloud | Cluster Size        |
| -------------- | ------------------------- | ----- | ------------------- |
| **dev**        | Development & testing     | AWS   | 3 nodes (t3.large)  |
| **staging**    | Pre-production validation | AWS   | 6 nodes (t3.xlarge) |
| **production** | Production workloads      | AWS   | 18 nodes (mixed)    |

## Cost Estimates

### Development Environment

- EKS Control Plane: ~$73/month
- Worker Nodes (3x t3.large): ~$150/month
- RDS PostgreSQL (db.t3.medium): ~$60/month
- **Total:** ~$283/month

### Production Environment (1000 orgs)

- EKS Control Plane: ~$73/month
- Worker Nodes (18x mixed): ~$3,500/month
- RDS PostgreSQL (r6g.large Multi-AZ): ~$600/month
- ClickHouse (3x r6g.xlarge): ~$1,800/month
- Redis (r6g.large): ~$350/month
- Kafka (3 brokers): ~$900/month
- **Total:** ~$7,223/month

## Cloud Provider Abstractions

We use Terraform modules to abstract cloud provider differences:

```hcl
module "kubernetes_cluster" {
  source = "../../modules/kubernetes-cluster"

  provider_type = "aws"  # or "gcp" or "baremetal"
  cluster_name  = "platform-prod"
  node_pools = {
    system = { count = 3, instance_type = "t3.large" }
    apps   = { count = 9, instance_type = "m5.xlarge" }
    data   = { count = 6, instance_type = "r5.2xlarge" }
  }
}
```

The module internally uses:

- AWS: EKS + EC2
- GCP: GKE + Compute Engine
- Bare Metal: kubeadm + existing VMs

## Deployment Workflow

```
┌─────────────┐       ┌──────────────┐       ┌────────────────┐
│   Terraform │──────▶│  Kubernetes  │──────▶│     ArgoCD     │
│   (Infra)   │       │   (Cluster)  │       │  (Workloads)   │
└─────────────┘       └──────────────┘       └────────────────┘
      │                       │                       │
      ▼                       ▼                       ▼
  VPC, EKS, RDS      Namespaces, RBAC      Services, Apps
```

1. **Terraform**: Provisions cloud resources (VPC, K8s cluster, managed DBs)
2. **Kubernetes**: Configures cluster (namespaces, policies, operators)
3. **ArgoCD**: Deploys and manages applications (GitOps)

## Key Features

### 🌍 Cloud Agnostic

- Abstracted Terraform modules
- Provider-specific implementations
- Consistent interface across clouds

### 🔄 GitOps Ready

- ArgoCD for continuous deployment
- All configs in Git
- Automated sync and self-healing

### 🔒 Security First

- HashiCorp Vault for secrets
- Network policies by default
- mTLS via Istio (optional)

### 📊 Observable

- Prometheus + Grafana
- Loki for logs
- Tempo for distributed tracing

### 💰 Cost Optimized

- ARM-based instances where possible
- Auto-scaling policies
- Reserved instances for production

## Common Commands

```bash
# Deploy full stack to AWS dev
make deploy-aws-dev

# Plan infrastructure changes
make plan-aws-dev

# Bootstrap ArgoCD
make bootstrap-argocd

# Initialize Vault
make vault-init

# Destroy everything (WARNING)
make destroy-aws-dev

# Validate Kubernetes manifests
make validate-k8s

# Update kubeconfig
make get-kubeconfig-aws-dev
```

## Migration Between Clouds

To migrate from AWS to GCP:

1. Deploy GCP infrastructure: `make deploy-gcp-prod`
2. Replicate data to GCP
3. Switch DNS to GCP load balancer
4. Decommission AWS (after validation)

Our abstraction layer ensures applications run identically across providers.

## Monitoring & Alerts

- Prometheus: http://prometheus.platform.internal
- Grafana: http://grafana.platform.internal
- ArgoCD: http://argocd.platform.internal
- Vault: http://vault.platform.internal

## Support & Documentation

- [Setup Guide](docs/setup-guide.md)
- [Runbooks](docs/runbooks/)
- [Architecture Decisions](docs/architecture/)
- [Troubleshooting](docs/troubleshooting.md)

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for development guidelines.

## License

Proprietary - Internal Use Only
