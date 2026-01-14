.PHONY: help
help: ## Show this help message
	@echo "════════════════════════════════════════════════════════════════"
	@echo "  AtomicAds Campaign Lifecycle Platform - Infrastructure"
	@echo "════════════════════════════════════════════════════════════════"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
	@echo ""

# ============================================================================
# LOCAL DEVELOPMENT TARGETS
# ============================================================================

.PHONY: quickstart-local
quickstart-local: ## 🚀 ONE-COMMAND LOCAL DEPLOYMENT - Complete platform on local K8s
	@echo "════════════════════════════════════════════════════════════════"
	@echo "🚀 AtomicAds Platform - Local Quickstart"
	@echo "════════════════════════════════════════════════════════════════"
	@echo ""
	@$(MAKE) preflight-local
	@$(MAKE) setup-local-cluster
	@$(MAKE) bootstrap-argocd
	@$(MAKE) deploy-platform-local
	@$(MAKE) verify-platform
	@$(MAKE) show-endpoints
	@echo ""
	@echo "════════════════════════════════════════════════════════════════"
	@echo "✅ Platform Ready!"
	@echo "════════════════════════════════════════════════════════════════"

.PHONY: preflight-local
preflight-local: ## ✓ Verify prerequisites for local deployment
	@echo "→ Checking prerequisites..."
	@command -v docker >/dev/null 2>&1 || (echo "❌ Docker not found. Install Docker Desktop" && exit 1)
	@command -v kubectl >/dev/null 2>&1 || (echo "❌ kubectl not found. Run: brew install kubectl" && exit 1)
	@command -v kustomize >/dev/null 2>&1 || (echo "❌ kustomize not found. Run: brew install kustomize" && exit 1)
	@command -v helm >/dev/null 2>&1 || (echo "❌ helm not found. Run: brew install helm" && exit 1)
	@docker info >/dev/null 2>&1 || (echo "❌ Docker daemon not running. Start Docker Desktop" && exit 1)
	@kubectl cluster-info >/dev/null 2>&1 || (echo "❌ Kubernetes cluster not accessible. Enable Kubernetes in Docker Desktop" && exit 1)
	@if [ -z "$$GITHUB_TOKEN" ]; then echo "⚠️  WARNING: GITHUB_TOKEN not set. ArgoCD may fail to sync private repos."; fi
	@echo "✅ All prerequisites met"

.PHONY: setup-local-cluster
setup-local-cluster: ## 🏗️  Configure local Kubernetes cluster
	@echo "→ Setting up local Kubernetes cluster..."
	@kubectl config use-context docker-desktop || kubectl config use-context k3s-default || (echo "❌ No local cluster found" && exit 1)
	@kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
	@kubectl create namespace atomicads-local --dry-run=client -o yaml | kubectl apply -f -
	@echo "✅ Local cluster configured"

.PHONY: bootstrap-argocd
bootstrap-argocd: ## 📦 Install and configure ArgoCD
	@echo "→ Installing ArgoCD..."
	@./scripts/bootstrap-argocd.sh
	@echo "✅ ArgoCD installed and configured"

.PHONY: deploy-platform-local
deploy-platform-local: ## 🚢 Deploy all platform components via ArgoCD
	@echo "→ Deploying platform components..."
	@kubectl apply -k ../platform-kubernetes/overlays/local/ 2>/dev/null || echo "⚠️  Local overlay not found, will create it"
	@echo "✅ Platform deployment initiated"

.PHONY: verify-platform
verify-platform: ## 🔍 Verify all components are healthy
	@echo "→ Verifying platform health..."
	@./scripts/verify-platform.sh

.PHONY: show-endpoints
show-endpoints: ## 📍 Display service access endpoints
	@echo ""
	@echo "════════════════════════════════════════════════════════════════"
	@echo "📍 Service Endpoints"
	@echo "════════════════════════════════════════════════════════════════"
	@echo ""
	@./scripts/show-endpoints.sh

.PHONY: logs-local
logs-local: ## 📋 Stream logs from all platform components
	@echo "→ Streaming platform logs (Ctrl+C to stop)..."
	@kubectl logs -f -l app.kubernetes.io/part-of=atomicads -n atomicads-local --all-containers=true --max-log-requests=10 2>/dev/null || \
		kubectl logs -f -l platform=atomicads -n atomicads-local --all-containers=true --max-log-requests=10

.PHONY: teardown-local
teardown-local: ## 🗑️  Complete cleanup of local environment
	@echo "⚠️  This will DELETE all local platform resources!"
	@read -p "Continue? (yes/no): " confirm && [ "$$confirm" = "yes" ] || (echo "Aborted" && exit 1)
	@echo "→ Tearing down local environment..."
	@kubectl delete namespace atomicads-local --ignore-not-found=true
	@kubectl delete namespace argocd --ignore-not-found=true
	@echo "✅ Local environment cleaned up"

# ============================================================================
# AWS EKS DEPLOYMENT TARGETS
# ============================================================================

.PHONY: quickstart-aws-dev
quickstart-aws-dev: ## 🌩️  Deploy to AWS EKS (dev environment)
	@echo "→ Deploying to AWS EKS (dev)..."
	@cd terraform/providers/aws/dev && terraform init && terraform apply -auto-approve
	@$(MAKE) configure-kubectl-aws-dev
	@$(MAKE) bootstrap-argocd
	@echo "✅ AWS dev environment ready"

.PHONY: configure-kubectl-aws-dev
configure-kubectl-aws-dev: ## ⚙️  Configure kubectl for AWS EKS dev
	@echo "→ Configuring kubectl for AWS EKS..."
	@aws eks update-kubeconfig --region us-east-1 --name platform-dev

.PHONY: terraform-plan-dev
terraform-plan-dev: ## 📋 Show Terraform plan for dev
	@cd terraform/providers/aws/dev && terraform plan

.PHONY: terraform-apply-dev
terraform-apply-dev: ## 🚀 Apply Terraform for dev
	@cd terraform/providers/aws/dev && terraform apply

.PHONY: terraform-destroy-dev
terraform-destroy-dev: ## 💥 Destroy AWS dev infrastructure
	@echo "⚠️  This will DESTROY the AWS dev environment!"
	@read -p "Type 'destroy' to confirm: " confirm && [ "$$confirm" = "destroy" ] || exit 1
	@cd terraform/providers/aws/dev && terraform destroy

# ============================================================================
# ARGOCD MANAGEMENT
# ============================================================================

.PHONY: argocd-ui
argocd-ui: ## 🌐 Open ArgoCD UI in browser
	@echo "→ Opening ArgoCD UI..."
	@echo "Username: admin"
	@echo "Password: $$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)"
	@kubectl port-forward svc/argocd-server -n argocd 8080:443 >/dev/null 2>&1 &
	@sleep 2
	@open https://localhost:8080 || echo "Open https://localhost:8080 in your browser"

.PHONY: argocd-password
argocd-password: ## 🔑 Get ArgoCD admin password
	@echo "ArgoCD Admin Password:"
	@kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
	@echo ""

.PHONY: argocd-sync-all
argocd-sync-all: ## 🔄 Sync all ArgoCD applications
	@echo "→ Syncing all applications..."
	@kubectl get applications -n argocd -o name | xargs -I {} kubectl patch {} -n argocd --type merge -p '{"operation":{"sync":{}}}'
	@echo "✅ Sync triggered for all applications"

# ============================================================================
# DATABASE MANAGEMENT
# ============================================================================

.PHONY: db-migrate
db-migrate: ## 📦 Run database migrations
	@echo "→ Running database migrations..."
	@kubectl exec -n atomicads-local -it deployment/postgres -- psql -U platform -d platform_dev -f /migrations/001_init_schema.sql
	@echo "✅ Migrations complete"

.PHONY: db-seed
db-seed: ## 🌱 Load seed data
	@echo "→ Loading seed data..."
	@kubectl exec -n atomicads-local -it deployment/postgres -- psql -U platform -d platform_dev -f /migrations/002_seed_data.sql
	@echo "✅ Seed data loaded"

.PHONY: db-reset
db-reset: ## 🔄 Reset database (drop and recreate)
	@echo "⚠️  This will DELETE all data!"
	@read -p "Continue? (yes/no): " confirm && [ "$$confirm" = "yes" ] || exit 1
	@kubectl exec -n atomicads-local -it deployment/postgres -- psql -U platform -d postgres -c "DROP DATABASE IF EXISTS platform_dev;"
	@kubectl exec -n atomicads-local -it deployment/postgres -- psql -U platform -d postgres -c "CREATE DATABASE platform_dev;"
	@$(MAKE) db-migrate
	@$(MAKE) db-seed
	@echo "✅ Database reset complete"

.PHONY: db-shell-postgres
db-shell-postgres: ## 🐘 Connect to PostgreSQL shell
	@kubectl exec -n atomicads-local -it deployment/postgres -- psql -U platform -d platform_dev

.PHONY: db-shell-clickhouse
db-shell-clickhouse: ## 🏠 Connect to ClickHouse shell
	@kubectl exec -n atomicads-local -it deployment/clickhouse -- clickhouse-client

.PHONY: db-shell-redis
db-shell-redis: ## 🔴 Connect to Redis shell
	@kubectl exec -n atomicads-local -it deployment/redis -- redis-cli

# ============================================================================
# MONITORING & DEBUGGING
# ============================================================================

.PHONY: status
status: ## 📊 Show platform status
	@echo "════════════════════════════════════════════════════════════════"
	@echo "Platform Status"
	@echo "════════════════════════════════════════════════════════════════"
	@echo ""
	@echo "→ Namespaces:"
	@kubectl get namespaces | grep -E "NAME|atomicads|argocd"
	@echo ""
	@echo "→ Pods (atomicads-local):"
	@kubectl get pods -n atomicads-local
	@echo ""
	@echo "→ Services:"
	@kubectl get svc -n atomicads-local
	@echo ""
	@echo "→ ArgoCD Applications:"
	@kubectl get applications -n argocd 2>/dev/null || echo "ArgoCD not installed"

.PHONY: grafana
grafana: ## 📊 Open Grafana dashboards
	@echo "→ Opening Grafana..."
	@kubectl port-forward -n atomicads-local svc/grafana 3000:80 >/dev/null 2>&1 &
	@sleep 2
	@echo "Grafana: http://localhost:3000 (admin/admin)"
	@open http://localhost:3000 || echo "Open http://localhost:3000 in your browser"

.PHONY: prometheus
prometheus: ## 📈 Open Prometheus UI
	@echo "→ Opening Prometheus..."
	@kubectl port-forward -n atomicads-local svc/prometheus 9090:9090 >/dev/null 2>&1 &
	@sleep 2
	@open http://localhost:9090 || echo "Open http://localhost:9090 in your browser"

# ============================================================================
# UTILITY TARGETS
# ============================================================================

.PHONY: k9s
k9s: ## 🐕 Launch k9s (Kubernetes CLI UI)
	@command -v k9s >/dev/null 2>&1 || (echo "Install k9s: brew install k9s" && exit 1)
	@k9s -n atomicads-local

.PHONY: clean-pv
clean-pv: ## 🧹 Clean persistent volumes
	@kubectl delete pvc --all -n atomicads-local
	@kubectl delete pv --all

.PHONY: restart-pod
restart-pod: ## 🔄 Restart a specific pod (Usage: make restart-pod POD=postgres)
	@if [ -z "$(POD)" ]; then echo "Usage: make restart-pod POD=<pod-name>"; exit 1; fi
	@kubectl delete pod -n atomicads-local -l app=$(POD)
	@echo "✅ Pod $(POD) restarted"

.PHONY: describe-pod
describe-pod: ## 🔍 Describe a specific pod (Usage: make describe-pod POD=postgres)
	@if [ -z "$(POD)" ]; then echo "Usage: make describe-pod POD=<pod-name>"; exit 1; fi
	@kubectl describe pod -n atomicads-local -l app=$(POD)

.PHONY: port-forward
port-forward: ## 🔌 Port forward to a service (Usage: make port-forward SVC=postgres PORT=5432)
	@if [ -z "$(SVC)" ] || [ -z "$(PORT)" ]; then echo "Usage: make port-forward SVC=<service> PORT=<port>"; exit 1; fi
	@kubectl port-forward -n atomicads-local svc/$(SVC) $(PORT):$(PORT)

# ============================================================================
# DEFAULT TARGET
# ============================================================================

.DEFAULT_GOAL := help
