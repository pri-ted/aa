.PHONY: help
.DEFAULT_GOAL := help

# Colors for output
CYAN := \033[0;36m
GREEN := \033[0;32m
YELLOW := \033[0;33m
RED := \033[0;31m
RESET := \033[0m

##@ General

help: ## Display this help message
	@awk 'BEGIN {FS = ":.*##"; printf "\n$(CYAN)Usage:$(RESET)\n  make $(GREEN)<target>$(RESET)\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  $(GREEN)%-25s$(RESET) %s\n", $$1, $$2 } /^##@/ { printf "\n$(CYAN)%s$(RESET)\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

check-tools: ## Check required tools are installed
	@echo "$(CYAN)Checking required tools...$(RESET)"
	@command -v terraform >/dev/null 2>&1 || { echo "$(RED)terraform not found$(RESET)"; exit 1; }
	@command -v kubectl >/dev/null 2>&1 || { echo "$(RED)kubectl not found$(RESET)"; exit 1; }
	@command -v helm >/dev/null 2>&1 || { echo "$(RED)helm not found$(RESET)"; exit 1; }
	@command -v aws >/dev/null 2>&1 || echo "$(YELLOW)aws-cli not found (needed for AWS deployments)$(RESET)"
	@command -v gcloud >/dev/null 2>&1 || echo "$(YELLOW)gcloud not found (needed for GCP deployments)$(RESET)"
	@echo "$(GREEN)✓ All required tools found$(RESET)"

##@ AWS Development

deploy-aws-dev: check-tools ## Deploy complete AWS dev environment
	@echo "$(CYAN)Deploying AWS dev environment...$(RESET)"
	@cd terraform/providers/aws/dev && terraform init
	@cd terraform/providers/aws/dev && terraform apply -auto-approve
	@$(MAKE) bootstrap-argocd-aws-dev
	@echo "$(GREEN)✓ AWS dev environment deployed$(RESET)"

plan-aws-dev: check-tools ## Plan AWS dev infrastructure changes
	@cd terraform/providers/aws/dev && terraform init
	@cd terraform/providers/aws/dev && terraform plan

destroy-aws-dev: ## Destroy AWS dev environment (WARNING: destructive)
	@echo "$(RED)WARNING: This will destroy the entire dev environment!$(RESET)"
	@echo "Press Ctrl+C to cancel, or wait 10 seconds to continue..."
	@sleep 10
	@cd terraform/providers/aws/dev && terraform destroy

get-kubeconfig-aws-dev: ## Update kubeconfig for AWS dev cluster
	@aws eks update-kubeconfig --name platform-dev --region us-east-1
	@echo "$(GREEN)✓ Kubeconfig updated$(RESET)"

##@ AWS Staging

deploy-aws-staging: check-tools ## Deploy AWS staging environment
	@echo "$(CYAN)Deploying AWS staging environment...$(RESET)"
	@cd terraform/providers/aws/staging && terraform init
	@cd terraform/providers/aws/staging && terraform apply -auto-approve
	@$(MAKE) bootstrap-argocd-aws-staging
	@echo "$(GREEN)✓ AWS staging environment deployed$(RESET)"

plan-aws-staging: check-tools ## Plan AWS staging infrastructure changes
	@cd terraform/providers/aws/staging && terraform init
	@cd terraform/providers/aws/staging && terraform plan

get-kubeconfig-aws-staging: ## Update kubeconfig for AWS staging cluster
	@aws eks update-kubeconfig --name platform-staging --region us-east-1

##@ AWS Production

deploy-aws-prod: check-tools ## Deploy AWS production environment
	@echo "$(RED)Deploying PRODUCTION environment$(RESET)"
	@echo "$(YELLOW)Manual approval required. Type 'yes' to continue:$(RESET)"
	@read -p "" confirm && [ "$$confirm" = "yes" ]
	@cd terraform/providers/aws/production && terraform init
	@cd terraform/providers/aws/production && terraform apply
	@$(MAKE) bootstrap-argocd-aws-prod
	@echo "$(GREEN)✓ AWS production environment deployed$(RESET)"

plan-aws-prod: check-tools ## Plan AWS production infrastructure changes
	@cd terraform/providers/aws/production && terraform init
	@cd terraform/providers/aws/production && terraform plan

get-kubeconfig-aws-prod: ## Update kubeconfig for AWS production cluster
	@aws eks update-kubeconfig --name platform-prod --region us-east-1

##@ GCP (Future)

deploy-gcp-dev: check-tools ## Deploy GCP dev environment
	@echo "$(YELLOW)GCP support coming in Phase 2$(RESET)"
	@cd terraform/providers/gcp/dev && terraform init
	@cd terraform/providers/gcp/dev && terraform apply

##@ GitOps

bootstrap-argocd-aws-dev: ## Bootstrap ArgoCD on AWS dev cluster
	@echo "$(CYAN)Bootstrapping ArgoCD...$(RESET)"
	@./scripts/bootstrap-argocd.sh dev
	@echo "$(GREEN)✓ ArgoCD deployed$(RESET)"
	@echo "$(CYAN)ArgoCD UI:$(RESET) https://argocd.dev.platform.internal"
	@echo "$(CYAN)Username:$(RESET) admin"
	@kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d && echo

bootstrap-argocd-aws-staging: ## Bootstrap ArgoCD on AWS staging cluster
	@./scripts/bootstrap-argocd.sh staging

bootstrap-argocd-aws-prod: ## Bootstrap ArgoCD on AWS production cluster
	@./scripts/bootstrap-argocd.sh production

deploy-apps: ## Deploy all platform applications via ArgoCD
	@echo "$(CYAN)Deploying platform applications...$(RESET)"
	@kubectl apply -f argocd/app-of-apps/
	@echo "$(GREEN)✓ Applications deployed$(RESET)"

sync-apps: ## Sync all ArgoCD applications
	@argocd app sync -l app.kubernetes.io/instance=platform

##@ Vault

vault-init: ## Initialize HashiCorp Vault
	@echo "$(CYAN)Initializing Vault...$(RESET)"
	@./scripts/vault-init.sh
	@echo "$(GREEN)✓ Vault initialized$(RESET)"
	@echo "$(RED)IMPORTANT: Save the unseal keys and root token securely!$(RESET)"

vault-unseal: ## Unseal Vault
	@./scripts/vault-unseal.sh

vault-status: ## Check Vault status
	@kubectl exec -n platform-system vault-0 -- vault status

##@ Database

deploy-postgres-operator: ## Deploy PostgreSQL operator
	@echo "$(CYAN)Deploying PostgreSQL operator...$(RESET)"
	@kubectl apply -k kubernetes/platform-data/postgres-operator/
	@echo "$(GREEN)✓ PostgreSQL operator deployed$(RESET)"

deploy-clickhouse-operator: ## Deploy ClickHouse operator
	@echo "$(CYAN)Deploying ClickHouse operator...$(RESET)"
	@kubectl apply -k kubernetes/platform-data/clickhouse-operator/
	@echo "$(GREEN)✓ ClickHouse operator deployed$(RESET)"

deploy-redis-operator: ## Deploy Redis operator
	@echo "$(CYAN)Deploying Redis operator...$(RESET)"
	@kubectl apply -k kubernetes/platform-data/redis-operator/
	@echo "$(GREEN)✓ Redis operator deployed$(RESET)"

##@ Monitoring

deploy-monitoring: ## Deploy monitoring stack (Prometheus, Grafana, Loki)
	@echo "$(CYAN)Deploying monitoring stack...$(RESET)"
	@kubectl apply -k kubernetes/platform-monitoring/
	@echo "$(GREEN)✓ Monitoring stack deployed$(RESET)"
	@echo "$(CYAN)Grafana:$(RESET) https://grafana.platform.internal"
	@echo "$(CYAN)Prometheus:$(RESET) https://prometheus.platform.internal"

port-forward-grafana: ## Port-forward Grafana to localhost:3000
	@kubectl port-forward -n platform-monitoring svc/grafana 3000:80

port-forward-prometheus: ## Port-forward Prometheus to localhost:9090
	@kubectl port-forward -n platform-monitoring svc/prometheus 9090:9090

##@ Validation

validate-k8s: ## Validate all Kubernetes manifests
	@echo "$(CYAN)Validating Kubernetes manifests...$(RESET)"
	@find kubernetes -name "*.yaml" -o -name "*.yml" | xargs -I {} kubectl apply --dry-run=client -f {}
	@echo "$(GREEN)✓ All manifests valid$(RESET)"

validate-terraform: ## Validate Terraform configurations
	@echo "$(CYAN)Validating Terraform...$(RESET)"
	@cd terraform/providers/aws/dev && terraform validate
	@echo "$(GREEN)✓ Terraform valid$(RESET)"

lint-terraform: ## Lint Terraform code
	@echo "$(CYAN)Linting Terraform...$(RESET)"
	@terraform fmt -check -recursive terraform/

format-terraform: ## Format Terraform code
	@terraform fmt -recursive terraform/

##@ Utilities

clean: ## Clean temporary files and caches
	@find . -type d -name ".terraform" -exec rm -rf {} + 2>/dev/null || true
	@find . -type f -name "*.tfstate*" -delete 2>/dev/null || true
	@find . -type f -name ".terraform.lock.hcl" -delete 2>/dev/null || true
	@echo "$(GREEN)✓ Cleaned$(RESET)"

logs-argocd: ## Show ArgoCD logs
	@kubectl logs -n argocd -l app.kubernetes.io/name=argocd-server --tail=100 -f

logs-vault: ## Show Vault logs
	@kubectl logs -n platform-system -l app.kubernetes.io/name=vault --tail=100 -f

shell-postgres: ## Get psql shell to PostgreSQL
	@kubectl exec -it -n platform-data postgres-0 -- psql -U platform

shell-clickhouse: ## Get clickhouse-client shell
	@kubectl exec -it -n platform-data clickhouse-0 -- clickhouse-client

shell-redis: ## Get redis-cli shell
	@kubectl exec -it -n platform-data redis-0 -- redis-cli

##@ Development

local-dev: ## Start local development environment (Docker Compose)
	@echo "$(CYAN)Starting local development environment...$(RESET)"
	@docker-compose -f docker-compose.dev.yaml up -d
	@echo "$(GREEN)✓ Local environment running$(RESET)"

local-stop: ## Stop local development environment
	@docker-compose -f docker-compose.dev.yaml down

local-logs: ## Show logs from local development environment
	@docker-compose -f docker-compose.dev.yaml logs -f

##@ CI/CD

ci-terraform-plan: ## CI: Run Terraform plan
	@cd terraform/providers/aws/dev && terraform init -backend=true
	@cd terraform/providers/aws/dev && terraform plan -out=tfplan

ci-terraform-apply: ## CI: Apply Terraform plan
	@cd terraform/providers/aws/dev && terraform apply tfplan

##@ Documentation

docs-serve: ## Serve documentation locally
	@echo "$(CYAN)Serving documentation at http://localhost:8000$(RESET)"
	@cd docs && python3 -m http.server 8000

docs-architecture: ## Generate architecture diagrams
	@./scripts/generate-diagrams.sh
