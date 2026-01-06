# Platform Infrastructure Setup Guide

> Step-by-step guide to deploy the Campaign Lifecycle Platform infrastructure on AWS EKS

---

## Prerequisites

### Required Tools

Install these tools before starting:

```bash
# Terraform
brew install terraform  # macOS
# or download from https://www.terraform.io/downloads

# kubectl
brew install kubectl

# AWS CLI
brew install awscli

# Helm
brew install helm

# ArgoCD CLI
brew install argocd

# Vault CLI
brew install vault

# jq (JSON processor)
brew install jq
```

### AWS Setup

1. **AWS Account Access**

   ```bash
   aws configure
   # Enter your AWS Access Key ID
   # Enter your AWS Secret Access Key
   # Default region: us-east-1
   # Default output format: json
   ```

2. **Verify AWS Access**

   ```bash
   aws sts get-caller-identity
   ```

3. **Create S3 Bucket for Terraform State** (One-time setup)

   ```bash
   aws s3api create-bucket \
     --bucket platform-terraform-state-dev \
     --region us-east-1

   aws s3api put-bucket-versioning \
     --bucket platform-terraform-state-dev \
     --versioning-configuration Status=Enabled

   aws s3api put-bucket-encryption \
     --bucket platform-terraform-state-dev \
     --server-side-encryption-configuration '{
       "Rules": [{
         "ApplyServerSideEncryptionByDefault": {
           "SSEAlgorithm": "AES256"
         }
       }]
     }'
   ```

4. **Create DynamoDB Table for State Locking**
   ```bash
   aws dynamodb create-table \
     --table-name platform-terraform-locks \
     --attribute-definitions AttributeName=LockID,AttributeType=S \
     --key-schema AttributeName=LockID,KeyType=HASH \
     --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 \
     --region us-east-1
   ```

---

## Deployment Steps

### Phase 1: Infrastructure Provisioning (Week 1)

#### Step 1: Clone Repository

```bash
git clone https://github.com/AtomicAds/platform-infrastructure.git
cd platform-infrastructure
```

#### Step 2: Deploy EKS Cluster

```bash
# Option A: Using Makefile (Recommended)
make deploy-aws-dev

# Option B: Manual Terraform
cd terraform/providers/aws/dev
terraform init
terraform plan
terraform apply
```

**Expected Duration:** 15-20 minutes

**Output:**

```
cluster_id = "platform-dev"
cluster_endpoint = "https://XXXXX.gr7.us-east-1.eks.amazonaws.com"
kubeconfig_command = "aws eks update-kubeconfig --name platform-dev --region us-east-1"
```

#### Step 3: Configure kubectl

```bash
# Update kubeconfig
aws eks update-kubeconfig --name platform-dev --region us-east-1

# Verify cluster access
kubectl get nodes
kubectl get namespaces
```

**Expected Output:**

```
NAME                                          STATUS   ROLES    AGE
ip-10-0-1-100.us-east-1.compute.internal      Ready    <none>   5m
ip-10-0-2-100.us-east-1.compute.internal      Ready    <none>   5m
ip-10-0-3-100.us-east-1.compute.internal      Ready    <none>   5m
```

#### Step 4: Bootstrap ArgoCD

```bash
make bootstrap-argocd-aws-dev
```

**Expected Duration:** 5 minutes

**Important:** Save the ArgoCD admin password shown in the output!

#### Step 5: Access ArgoCD UI

```bash
# Port forward ArgoCD (in a separate terminal)
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Open browser
open https://localhost:8080

# Login
Username: admin
Password: <from bootstrap output>
```

#### Step 6: Initialize Vault

```bash
make vault-init
```

**Expected Duration:** 3 minutes

**CRITICAL:** Securely save the unseal keys and root token!

```
Unseal Keys:
  Key 1: xxxxx
  Key 2: xxxxx
  Key 3: xxxxx
  Key 4: xxxxx
  Key 5: xxxxx

Root Token: s.xxxxxxxxxxxxx
```

**Store these in a password manager immediately!**

---

### Phase 2: Platform Services (Week 2)

#### Step 7: Deploy Database Operators

```bash
# Deploy all database operators
make deploy-postgres-operator
make deploy-clickhouse-operator
make deploy-redis-operator
```

**Verify:**

```bash
kubectl get pods -n platform-data
```

#### Step 8: Deploy Monitoring Stack

```bash
make deploy-monitoring
```

**Access Grafana:**

```bash
kubectl port-forward svc/grafana -n platform-monitoring 3000:80
```

Open: http://localhost:3000

- Username: admin
- Password: Check secret `kubectl get secret -n platform-monitoring grafana -o jsonpath="{.data.admin-password}" | base64 -d`

#### Step 9: Deploy Platform Applications via ArgoCD

```bash
make deploy-apps
```

This deploys:

- All platform infrastructure apps
- All platform data layer apps
- All monitoring apps

**Monitor deployment:**

```bash
# Watch ArgoCD sync
argocd app list

# Or use UI
open https://localhost:8080
```

---

## Validation & Testing

### Infrastructure Validation

```bash
# Check all nodes are ready
kubectl get nodes

# Check all namespaces exist
kubectl get namespaces

# Check resource quotas
kubectl get resourcequotas --all-namespaces

# Check network policies
kubectl get networkpolicies --all-namespaces
```

### Service Validation

```bash
# Check ArgoCD
kubectl get pods -n argocd

# Check Vault
kubectl exec -n platform-system vault-0 -- vault status

# Check monitoring
kubectl get pods -n platform-monitoring

# Check data layer
kubectl get pods -n platform-data
```

### Cost Validation

```bash
# Check node instance types
kubectl get nodes -o custom-columns=NAME:.metadata.name,INSTANCE:.metadata.labels."node\\.kubernetes\\.io/instance-type",POOL:.metadata.labels.pool

# Expected output for dev:
# - 3x t3.large (system)
# - 3x t3.xlarge (apps)
# - 2x r6g.large (data)
```

**Expected Monthly Cost:** ~$350-400 for dev environment

---

## Troubleshooting

### Issue: EKS Cluster Creation Fails

```bash
# Check AWS limits
aws service-quotas list-service-quotas --service-code eks

# Check VPC limits
aws service-quotas list-service-quotas --service-code vpc
```

### Issue: ArgoCD Not Syncing

```bash
# Check ArgoCD logs
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-application-controller

# Force sync
argocd app sync <app-name>
```

### Issue: Vault Sealed

```bash
# Unseal Vault
kubectl exec -n platform-system vault-0 -- vault operator unseal <unseal-key-1>
kubectl exec -n platform-system vault-0 -- vault operator unseal <unseal-key-2>
kubectl exec -n platform-system vault-0 -- vault operator unseal <unseal-key-3>
```

### Issue: Pods in CrashLoopBackOff

```bash
# Check pod logs
kubectl logs <pod-name> -n <namespace>

# Describe pod for events
kubectl describe pod <pod-name> -n <namespace>

# Check resource quotas
kubectl describe resourcequota -n <namespace>
```

---

## Cleanup (Development Only)

**WARNING:** This destroys everything!

```bash
# Destroy via Makefile
make destroy-aws-dev

# Or manual
cd terraform/providers/aws/dev
terraform destroy
```

---

## Next Steps

After infrastructure is deployed:

1. **Configure Secrets in Vault**

   ```bash
   # Port forward Vault
   kubectl port-forward svc/vault -n platform-system 8200:8200

   # Login
   export VAULT_ADDR='http://127.0.0.1:8200'
   vault login <root-token>

   # Add secrets
   vault kv put secret/platform/postgres password=<strong-password>
   vault kv put secret/platform/dv360 client_id=<client-id> client_secret=<secret>
   ```

2. **Deploy Application Services**

   - Move to `platform-services-go` repository
   - Deploy Auth Service
   - Deploy Config Service
   - Deploy Connector Service

3. **Setup CI/CD**

   - Configure GitHub Actions secrets
   - Set up OIDC provider for AWS
   - Enable branch protection

4. **Configure DNS**
   - Point domain to LoadBalancer
   - Setup SSL certificates
   - Configure Ingress rules

---

## Architecture Overview

```
┌────────────────────────────────────────────────────────┐
│                     AWS Account                        │
│  ┌──────────────────────────────────────────────────┐  │
│  │              VPC (10.0.0.0/16)                   │  │
│  │  ┌────────────────────────────────────────────┐  │  │
│  │  │           EKS Cluster                      │  │  │
│  │  │                                            │  │  │
│  │  │  ┌──────────┐  ┌──────────┐  ┌──────────┐  │  │  │
│  │  │  │  System  │  │   Apps   │  │   Data   │  │  │  │
│  │  │  │   Pool   │  │   Pool   │  │   Pool   │  │  │  │
│  │  │  │ (3 nodes)│  │ (3 nodes)│  │ (2 nodes)│  │  │  │
│  │  │  └──────────┘  └──────────┘  └──────────┘  │  │  │
│  │  │                                            │  │  │
│  │  │  Namespaces:                               │  │  │
│  │  │  - platform-system (ArgoCD, Vault)         │  │  │
│  │  │  - platform-apps (Services)                │  │  │
│  │  │  - platform-data (Databases)               │  │  │
│  │  │  - platform-monitoring (Observability)     │  │  │
│  │  └────────────────────────────────────────────┘  │  │
│  └──────────────────────────────────────────────────┘  │
└────────────────────────────────────────────────────────┘
```

---

## Support

For issues or questions:

- Slack: #platform-infrastructure
- Email: platform-team@company.com
- Docs: https://docs.platform.internal
