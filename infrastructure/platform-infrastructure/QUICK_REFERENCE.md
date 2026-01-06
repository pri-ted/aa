# Quick Reference Card

> Common commands for platform infrastructure operations

---

## 🚀 Initial Setup (One-Time)

```bash
# 1. Prerequisites
brew install terraform kubectl helm awscli argocd vault jq

# 2. AWS Setup
aws configure
aws s3 mb s3://platform-terraform-state-dev --region us-east-1

# 3. Deploy Everything
git clone <repo-url>
cd platform-infrastructure
make deploy-aws-dev

# 4. Get Access
make get-kubeconfig-aws-dev
make bootstrap-argocd-aws-dev
make vault-init
```

---

## 📋 Daily Operations

### Cluster Access

```bash
# Update kubeconfig
make get-kubeconfig-aws-dev

# Check cluster
kubectl cluster-info
kubectl get nodes
```

### ArgoCD

```bash
# Port-forward UI
kubectl port-forward svc/argocd-server -n argocd 8080:443
# Open: https://localhost:8080

# CLI login
argocd login localhost:8080 --insecure

# Sync all apps
argocd app sync -l app.kubernetes.io/instance=platform

# Check app status
argocd app list
argocd app get <app-name>
```

### Vault

```bash
# Port-forward UI
kubectl port-forward svc/vault -n platform-system 8200:8200
# Open: http://localhost:8200

# CLI access
export VAULT_ADDR='http://127.0.0.1:8200'
vault login <root-token>

# Add secret
vault kv put secret/platform/postgres password=<pass>

# Read secret
vault kv get secret/platform/postgres

# Unseal (if sealed)
make vault-unseal
```

### Terraform

```bash
# Plan changes
make plan-aws-dev

# Apply changes
make deploy-aws-dev

# Show current state
cd terraform/providers/aws/dev
terraform show

# List resources
terraform state list
```

---

## 🔍 Monitoring

### Cluster Health

```bash
# All nodes
kubectl get nodes

# All pods
kubectl get pods --all-namespaces

# Resource usage
kubectl top nodes
kubectl top pods --all-namespaces

# Events
kubectl get events --all-namespaces --sort-by='.lastTimestamp'
```

### Logs

```bash
# Service logs
kubectl logs -n platform-apps -l app=auth-service --tail=100 -f

# ArgoCD logs
make logs-argocd

# Vault logs
make logs-vault
```

### Metrics

```bash
# Port-forward Grafana
make port-forward-grafana
# Open: http://localhost:3000

# Port-forward Prometheus
make port-forward-prometheus
# Open: http://localhost:9090
```

---

## 🗄️ Database Access

### PostgreSQL

```bash
# Shell access
make shell-postgres

# Or manually
kubectl exec -it -n platform-data postgres-0 -- psql -U platform

# Backup
kubectl exec -n platform-data postgres-0 -- pg_dump platform > backup.sql

# Restore
cat backup.sql | kubectl exec -i -n platform-data postgres-0 -- psql platform
```

### ClickHouse

```bash
# Shell access
make shell-clickhouse

# Or manually
kubectl exec -it -n platform-data clickhouse-0 -- clickhouse-client

# Query
kubectl exec -n platform-data clickhouse-0 -- clickhouse-client --query="SELECT version()"
```

### Redis

```bash
# Shell access
make shell-redis

# Or manually
kubectl exec -it -n platform-data redis-0 -- redis-cli

# Check keys
kubectl exec -n platform-data redis-0 -- redis-cli KEYS '*'
```

---

## 🔧 Troubleshooting

### Pod Issues

```bash
# Check pod status
kubectl get pods -n <namespace>

# Describe pod
kubectl describe pod <pod-name> -n <namespace>

# Logs
kubectl logs <pod-name> -n <namespace> --tail=100

# Previous logs (if crashed)
kubectl logs <pod-name> -n <namespace> --previous

# Execute into pod
kubectl exec -it <pod-name> -n <namespace> -- /bin/sh
```

### Service Issues

```bash
# Check service
kubectl get svc -n <namespace>

# Check endpoints
kubectl get endpoints -n <namespace>

# Port-forward for testing
kubectl port-forward svc/<service-name> -n <namespace> 8080:80
```

### Network Issues

```bash
# Check network policies
kubectl get networkpolicies --all-namespaces

# Test connectivity (from debug pod)
kubectl run test-pod --rm -it --image=nicolaka/netshoot -- /bin/bash
# Then: curl http://service-name.namespace:port
```

### Resource Issues

```bash
# Check quotas
kubectl describe resourcequota -n <namespace>

# Check limits
kubectl describe limitrange -n <namespace>

# Check actual usage
kubectl top pods -n <namespace>
kubectl top nodes
```

---

## 🚨 Emergency Procedures

### Cluster Unresponsive

```bash
# Check control plane
aws eks describe-cluster --name platform-dev

# Check nodes
kubectl get nodes
aws ec2 describe-instances --filters "Name=tag:eks:cluster-name,Values=platform-dev"

# Restart kubelet on nodes (if accessible)
aws ssm send-command \
  --document-name "AWS-RunShellScript" \
  --targets "Key=tag:eks:cluster-name,Values=platform-dev" \
  --parameters 'commands=["sudo systemctl restart kubelet"]'
```

### Vault Sealed

```bash
# Check status
kubectl exec -n platform-system vault-0 -- vault status

# Unseal (need 3 of 5 keys)
kubectl exec -n platform-system vault-0 -- vault operator unseal <key1>
kubectl exec -n platform-system vault-0 -- vault operator unseal <key2>
kubectl exec -n platform-system vault-0 -- vault operator unseal <key3>
```

### ArgoCD Out of Sync

```bash
# Force sync all
argocd app sync --force -l app.kubernetes.io/instance=platform

# Hard refresh
argocd app sync --force --replace --prune <app-name>

# Restart ArgoCD
kubectl rollout restart deployment -n argocd
```

### Database Down

```bash
# Check pod
kubectl get pod -n platform-data

# Check PVC
kubectl get pvc -n platform-data

# Check operator logs
kubectl logs -n platform-data -l app.kubernetes.io/name=postgres-operator

# Force restart
kubectl delete pod <db-pod> -n platform-data
```

---

## 🔐 Security

### Rotate Secrets

```bash
# Generate new secret
NEW_SECRET=$(openssl rand -base64 32)

# Update in Vault
vault kv put secret/platform/postgres password=$NEW_SECRET

# Restart pods to pick up new secret
kubectl rollout restart deployment -n platform-apps
```

### Check Security

```bash
# Pod security standards
kubectl get pods --all-namespaces -o json | \
  jq -r '.items[] | select(.metadata.labels."pod-security.kubernetes.io/enforce"!="restricted") | .metadata.name'

# Network policies
kubectl get networkpolicies --all-namespaces

# RBAC
kubectl get rolebindings,clusterrolebindings --all-namespaces
```

---

## 📊 Cost Tracking

### View Costs

```bash
# EC2 instances
aws ec2 describe-instances --query 'Reservations[*].Instances[*].[InstanceId,InstanceType,State.Name,Tags[?Key==`Name`].Value|[0]]' --output table

# Cost Explorer (via AWS Console)
open https://console.aws.amazon.com/cost-management/home

# Infracost (local)
infracost breakdown --path=terraform/providers/aws/dev
```

---

## 🧹 Cleanup

### Delete Specific Resources

```bash
# Delete application
argocd app delete <app-name>

# Delete namespace (careful!)
kubectl delete namespace <namespace>

# Delete Terraform resources
cd terraform/providers/aws/dev
terraform destroy -target=<resource>
```

### Full Cleanup (WARNING: Destructive)

```bash
# Destroy everything
make destroy-aws-dev

# Or manually
cd terraform/providers/aws/dev
terraform destroy
```

---

## 📝 Common Workflows

### Deploy New Service

```bash
# 1. Create ArgoCD application
cat <<EOF | kubectl apply -f -
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: new-service
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/org/repo
    path: k8s/new-service
    targetRevision: main
  destination:
    server: https://kubernetes.default.svc
    namespace: platform-apps
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
EOF

# 2. Watch deployment
argocd app get new-service --watch

# 3. Verify
kubectl get pods -n platform-apps -l app=new-service
```

### Update Configuration

```bash
# 1. Edit code in Git
git commit -am "Update config"
git push

# 2. ArgoCD auto-syncs (wait ~3 minutes)
# Or force sync:
argocd app sync <app-name>

# 3. Verify
kubectl get pods -n <namespace>
```

### Scale Application

```bash
# Edit deployment
kubectl scale deployment <deployment-name> -n <namespace> --replicas=5

# Or edit YAML
kubectl edit deployment <deployment-name> -n <namespace>

# Verify
kubectl get deployment <deployment-name> -n <namespace>
```

---

## 🔗 Useful URLs (Port-Forwarded)

| Service | Command | URL |
|---------|---------|-----|
| ArgoCD | `kubectl port-forward svc/argocd-server -n argocd 8080:443` | https://localhost:8080 |
| Vault | `kubectl port-forward svc/vault -n platform-system 8200:8200` | http://localhost:8200 |
| Grafana | `kubectl port-forward svc/grafana -n platform-monitoring 3000:80` | http://localhost:3000 |
| Prometheus | `kubectl port-forward svc/prometheus -n platform-monitoring 9090:9090` | http://localhost:9090 |

---

## 🆘 Get Help

```bash
# List all make commands
make help

# Validate setup
make check-tools

# View all resources
kubectl api-resources

# Get detailed command help
kubectl <command> --help
terraform <command> -help
argocd <command> --help
vault <command> -help
```

---

**Bookmark this page for quick reference!**

Last updated: December 26, 2024
