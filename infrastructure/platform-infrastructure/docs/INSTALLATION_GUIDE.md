## 🚀 Deployment Steps LOCAL

### Option 1: Using Makefile (Recommended)

```bash
cd platform-infrastructure/
chmod +x ./scripts/*.sh

# Set GitHub token (for private repos)
export GITHUB_TOKEN=ghp_your_token_here

# ONE COMMAND - Deploy everything!
make quickstart-local
```
This will:
1. ✅ Check prerequisites
2. ✅ Setup local Kubernetes cluster
3. ✅ Install and configure ArgoCD
4. ✅ Deploy Strimzi operator
5. ✅ Deploy all databases (PostgreSQL, ClickHouse, Redis, Kafka, MinIO)
6. ✅ Verify all components are healthy
7. ✅ Display service endpoints

**Expected output:**
```
════════════════════════════════════════════════════════════════
🚀 AtomicAds Platform - Local Quickstart
════════════════════════════════════════════════════════════════

→ Checking prerequisites...
✅ All prerequisites met

→ Setting up local Kubernetes cluster...
✅ Local cluster configured

→ Installing ArgoCD...
✅ ArgoCD installed and configured

→ Deploying platform components...
✅ Platform deployment initiated

→ Verifying platform health...
  → PostgreSQL... ✓ Ready
  → ClickHouse... ✓ Ready
  → Redis... ✓ Ready
  → Kafka... ✓ Ready (3 pods)
  → MinIO (Iceberg)... ✓ Ready
✅ All components healthy

════════════════════════════════════════════════════════════════
📍 Service Endpoints
════════════════════════════════════════════════════════════════

🐘 PostgreSQL
   Local:      localhost:30432
   Connection: postgresql://platform:platform_dev@localhost:30432/platform_dev

🏠 ClickHouse
   HTTP:       localhost:30123
   Native:     localhost:30900

🔴 Redis
   Local:      localhost:30379
   CLI:        redis-cli -h localhost -p 30379

📨 Kafka
   Local:      localhost:30092
   Topics:     7 topics created

🗄️  MinIO (Iceberg Storage)
   Console:    http://localhost:30901
   Credentials: minioadmin / minioadmin

🔄 ArgoCD
   URL:        https://localhost:8080
   Username:   admin
   Password:   (run: make argocd-password)

════════════════════════════════════════════════════════════════
✅ Platform Ready!
════════════════════════════════════════════════════════════════
```

---

### Option 2: Manual Step-by-Step Deployment

If you prefer to deploy manually:

#### Step 1: Install Strimzi Operator

```bash
cd platform-kubernetes/

# Install Strimzi operator
kubectl create namespace atomicads-local
kubectl apply -k infrastructure/strimzi/

# Wait for operator to be ready
kubectl wait --for=condition=ready pod -l name=strimzi-cluster-operator -n atomicads-local --timeout=300s
```

#### Step 2: Deploy Databases

```bash
# Deploy PostgreSQL
kubectl apply -k databases/postgresql/overlays/local/

# Deploy ClickHouse
kubectl apply -k databases/clickhouse/overlays/local/

# Deploy Redis
kubectl apply -k databases/redis/overlays/local/

# Deploy Kafka (after Strimzi operator is ready)
kubectl apply -k databases/kafka/overlays/local/

# Deploy MinIO
kubectl apply -k databases/minio/overlays/local/
```

#### Step 3: Verify Deployment

```bash
# Check all pods
kubectl get pods -n atomicads-local

# Wait for all to be ready
kubectl wait --for=condition=ready pod --all -n atomicads-local --timeout=600s
```

#### Step 4: Install ArgoCD (Optional)

```bash
cd ../platform-infrastructure/

# Run bootstrap script
./scripts/bootstrap-argocd.sh
```

---

## 🔧 Useful Commands

### View Status

```bash
make status                    # Overall platform status
make verify-platform          # Health check all components
make show-endpoints           # Display all endpoints
```

### Database Access

```bash
make db-shell-postgres        # PostgreSQL CLI
make db-shell-clickhouse      # ClickHouse CLI
make db-shell-redis           # Redis CLI
```

### Monitoring

```bash
make grafana                  # Open Grafana (once deployed)
make prometheus               # Open Prometheus
make argocd-ui                # Open ArgoCD UI
```

### Logs

```bash
make logs-local               # Stream all logs
kubectl logs -f <pod-name> -n atomicads-local
```

### Cleanup

```bash
make teardown-local           # Complete cleanup
```

---

## 🐛 Troubleshooting

### Issue: Pods stuck in Pending

**Cause:** PersistentVolumeClaims waiting for storage

**Solution:**
```bash
# Check PVCs
kubectl get pvc -n atomicads-local

# Docker Desktop uses 'hostpath' storageClass automatically
# If using k3s, install local-path-provisioner:
kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/master/deploy/local-path-storage.yaml
```

### Issue: Kafka pods not starting

**Cause:** Strimzi operator not ready yet

**Solution:**
```bash
# Check operator status
kubectl get pods -n atomicads-local -l name=strimzi-cluster-operator

# Wait for operator
kubectl wait --for=condition=ready pod -l name=strimzi-cluster-operator -n atomicads-local --timeout=300s

# Then redeploy Kafka
kubectl apply -k platform-kubernetes/databases/kafka/overlays/local/
```

### Issue: Cannot access services via NodePort

**Cause:** Docker Desktop networking

**Solution:**
```bash
# For Docker Desktop, use localhost
# For k3s/minikube, get node IP:
kubectl get nodes -o wide

# Or use port-forward:
kubectl port-forward -n atomicads-local svc/postgres 5432:5432
```

### Issue: ArgoCD cannot sync repositories

**Cause:** Missing GitHub token or private repo access

**Solution:**
```bash
# Set GitHub token before running bootstrap
export GITHUB_TOKEN=ghp_your_token_here

# Re-run bootstrap
cd platform-infrastructure/
./scripts/bootstrap-argocd.sh
```

---

## 📊 Resource Usage

**Total local resource requirements:**

| Component | CPU | Memory | Storage |
|-----------|-----|--------|---------|
| PostgreSQL | 250m | 256Mi | 10Gi |
| ClickHouse | 500m | 512Mi | 20Gi |
| Redis | 100m | 128Mi | ephemeral |
| Kafka | 250m | 512Mi | 20Gi |
| Zookeeper | 100m | 256Mi | 5Gi |
| MinIO | 100m | 256Mi | 20Gi |
| **Total** | **~1.3 CPU** | **~2GB RAM** | **~75GB disk** |

**Recommended local machine specs:**
- CPU: 4+ cores
- RAM: 8GB+ available
- Disk: 100GB+ free space

---

## 🎯 Next Steps

Once the platform is running locally:

1. **Run Database Migrations:**
   ```bash
   make db-migrate
   make db-seed
   ```

2. **Deploy Application Services:**
   ```bash
   # Deploy via ArgoCD (if installed)
   kubectl apply -f platform-argocd/app-of-apps/root.yaml
   
   # Or manually
   kubectl apply -k platform-kubernetes/services/auth/overlays/local/
   ```

3. **Access Monitoring:**
   ```bash
   make grafana      # Dashboards
   make prometheus   # Metrics
   ```

4. **Test Connectivity:**
   ```bash
   # PostgreSQL
   psql postgresql://platform:platform_dev@localhost:30432/platform_dev
   
   # ClickHouse
   curl http://localhost:30123/ping
   
   # Redis
   redis-cli -h localhost -p 30379 ping
   
   # MinIO
   open http://localhost:30901
   ```

---

## 📞 Support

- **Issues:** Create GitHub issue in respective repository
- **Documentation:** See `platform-docs` repository
- **Architecture:** See architecture documentation in project knowledge

---

**Last Updated:** 2026-01-09  
**Platform Version:** 1.0.0  
**Kubernetes Version:** 1.28+
