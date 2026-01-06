#!/bin/bash
set -euo pipefail

# Colors for output
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
RESET='\033[0m'

ENVIRONMENT=${1:-dev}

echo -e "${CYAN}========================================${RESET}"
echo -e "${CYAN}Bootstrapping ArgoCD - ${ENVIRONMENT}${RESET}"
echo -e "${CYAN}========================================${RESET}\n"

# Validate environment
if [[ ! "$ENVIRONMENT" =~ ^(dev|staging|production)$ ]]; then
    echo -e "${RED}Error: Invalid environment. Must be dev, staging, or production${RESET}"
    exit 1
fi

# Check if kubectl is configured
if ! kubectl cluster-info &> /dev/null; then
    echo -e "${RED}Error: kubectl not configured. Please run 'make get-kubeconfig-aws-${ENVIRONMENT}' first${RESET}"
    exit 1
fi

echo -e "${CYAN}Step 1: Creating ArgoCD namespace${RESET}"
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -

echo -e "${CYAN}Step 2: Installing ArgoCD${RESET}"
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

echo -e "${CYAN}Step 3: Waiting for ArgoCD to be ready${RESET}"
kubectl wait --for=condition=available --timeout=300s \
    deployment/argocd-server \
    deployment/argocd-repo-server \
    deployment/argocd-application-controller \
    -n argocd

echo -e "${CYAN}Step 4: Patching ArgoCD server for LoadBalancer${RESET}"
if [ "$ENVIRONMENT" == "production" ]; then
    # Production uses LoadBalancer
    kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'
else
    # Dev/Staging use NodePort
    kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "NodePort"}}'
fi

echo -e "${CYAN}Step 5: Configuring ArgoCD${RESET}"
# Disable TLS for internal access (behind ALB)
kubectl patch configmap argocd-cmd-params-cm -n argocd --type merge -p '{"data": {"server.insecure": "true"}}'

# Enable anonymous read-only access for monitoring
kubectl patch configmap argocd-cm -n argocd --type merge -p '{"data": {"users.anonymous.enabled": "true"}}'

# Configure resource tracking
kubectl patch configmap argocd-cm -n argocd --type merge -p '{"data": {"application.resourceTrackingMethod": "annotation+label"}}'

echo -e "${CYAN}Step 6: Restarting ArgoCD server to apply changes${RESET}"
kubectl rollout restart deployment argocd-server -n argocd
kubectl rollout status deployment argocd-server -n argocd

echo -e "${CYAN}Step 7: Retrieving initial admin password${RESET}"
ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)

echo -e "${CYAN}Step 8: Installing ArgoCD CLI${RESET}"
if ! command -v argocd &> /dev/null; then
    echo -e "${YELLOW}ArgoCD CLI not found. Installing...${RESET}"
    curl -sSL -o /usr/local/bin/argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
    chmod +x /usr/local/bin/argocd
else
    echo -e "${GREEN}ArgoCD CLI already installed${RESET}"
fi

# Get ArgoCD server endpoint
if [ "$ENVIRONMENT" == "production" ]; then
    ARGOCD_SERVER=$(kubectl get svc argocd-server -n argocd -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
    echo -e "${CYAN}Waiting for LoadBalancer to be ready...${RESET}"
    while [ -z "$ARGOCD_SERVER" ]; do
        sleep 5
        ARGOCD_SERVER=$(kubectl get svc argocd-server -n argocd -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
    done
else
    # For dev/staging, use port-forward
    ARGOCD_SERVER="localhost:8080"
    echo -e "${YELLOW}Note: For dev/staging, you'll need to port-forward:${RESET}"
    echo -e "${YELLOW}  kubectl port-forward svc/argocd-server -n argocd 8080:443${RESET}"
fi

echo -e "\n${GREEN}========================================${RESET}"
echo -e "${GREEN}ArgoCD Bootstrap Complete!${RESET}"
echo -e "${GREEN}========================================${RESET}\n"

echo -e "${CYAN}Access Information:${RESET}"
echo -e "  ${GREEN}URL:${RESET}      https://${ARGOCD_SERVER}"
echo -e "  ${GREEN}Username:${RESET} admin"
echo -e "  ${GREEN}Password:${RESET} ${ARGOCD_PASSWORD}"

echo -e "\n${CYAN}Next Steps:${RESET}"
echo -e "1. ${GREEN}Login to ArgoCD CLI:${RESET}"
if [ "$ENVIRONMENT" == "production" ]; then
    echo -e "   argocd login ${ARGOCD_SERVER} --username admin --password '${ARGOCD_PASSWORD}'"
else
    echo -e "   kubectl port-forward svc/argocd-server -n argocd 8080:443 &"
    echo -e "   argocd login localhost:8080 --username admin --password '${ARGOCD_PASSWORD}' --insecure"
fi

echo -e "\n2. ${GREEN}Change the admin password:${RESET}"
echo -e "   argocd account update-password"

echo -e "\n3. ${GREEN}Deploy platform applications:${RESET}"
echo -e "   make deploy-apps"

echo -e "\n${YELLOW}IMPORTANT: Save the password above securely!${RESET}"
echo -e "${YELLOW}The initial admin secret will be deleted after first login.${RESET}\n"
