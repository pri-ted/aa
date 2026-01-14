#!/bin/bash
set -euo pipefail

# ============================================================================
# ArgoCD Bootstrap Script
# Installs ArgoCD and registers platform repositories for GitOps
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GITHUB_ORG="${GITHUB_ORG:-AtomicAds}"
GITHUB_TOKEN="${GITHUB_TOKEN:-}"

echo "════════════════════════════════════════════════════════════════"
echo "🚀 Bootstrapping ArgoCD"
echo "════════════════════════════════════════════════════════════════"
echo ""

# ============================================================================
# Check Prerequisites
# ============================================================================

echo "→ Checking prerequisites..."

if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl not found. Please install kubectl first."
    exit 1
fi

if ! kubectl cluster-info &> /dev/null; then
    echo "❌ Cannot connect to Kubernetes cluster"
    exit 1
fi

echo "✅ Prerequisites met"
echo ""

# ============================================================================
# Install ArgoCD
# ============================================================================

echo "→ Installing ArgoCD..."

# Create namespace
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -

# Install ArgoCD (latest stable)
ARGOCD_VERSION="v2.10.0"
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/${ARGOCD_VERSION}/manifests/install.yaml

echo "→ Waiting for ArgoCD to be ready (this may take 2-3 minutes)..."

# Wait for ArgoCD server to be ready
kubectl wait --for=condition=available --timeout=300s \
    deployment/argocd-server -n argocd

echo "✅ ArgoCD installed successfully"
echo ""

# ============================================================================
# Configure ArgoCD
# ============================================================================

echo "→ Configuring ArgoCD..."

# Patch ArgoCD to be insecure (for local development)
kubectl patch configmap argocd-cmd-params-cm -n argocd \
    --type merge \
    -p '{"data":{"server.insecure":"true"}}'

# Restart ArgoCD server to apply changes
kubectl rollout restart deployment/argocd-server -n argocd
kubectl rollout status deployment/argocd-server -n argocd --timeout=120s

echo "✅ ArgoCD configured"
echo ""

# ============================================================================
# Register Platform Repositories
# ============================================================================

echo "→ Registering platform repositories..."

# Only setup GitHub credentials if token is provided
if [ -n "$GITHUB_TOKEN" ]; then
    echo "→ Setting up GitHub credentials..."
    
    # Create secret for GitHub access
    kubectl create secret generic github-creds \
        --from-literal=username=git \
        --from-literal=password="$GITHUB_TOKEN" \
        --namespace=argocd \
        --dry-run=client -o yaml | kubectl apply -f -
    
    # Register platform-kubernetes repository
    kubectl apply -f - <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: platform-kubernetes-repo
  namespace: argocd
  labels:
    argocd.argoproj.io/secret-type: repository
stringData:
  type: git
  url: https://github.com/${GITHUB_ORG}/platform-kubernetes.git
  password: ${GITHUB_TOKEN}
  username: git
EOF

    # Register platform-argocd repository
    kubectl apply -f - <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: platform-argocd-repo
  namespace: argocd
  labels:
    argocd.argoproj.io/secret-type: repository
stringData:
  type: git
  url: https://github.com/${GITHUB_ORG}/platform-argocd.git
  password: ${GITHUB_TOKEN}
  username: git
EOF

    echo "✅ GitHub repositories registered"
else
    echo "⚠️  GITHUB_TOKEN not set - repositories will be accessed as public"
    echo "   If your repos are private, set GITHUB_TOKEN environment variable"
fi

echo ""

# ============================================================================
# Deploy ArgoCD Projects
# ============================================================================

echo "→ Creating ArgoCD Projects..."

# Check if platform-argocd repo exists locally
if [ -d "${SCRIPT_DIR}/../../platform-argocd" ]; then
    ARGOCD_REPO_PATH="${SCRIPT_DIR}/../../platform-argocd"
else
    echo "⚠️  platform-argocd repository not found locally"
    echo "   Skipping project creation - deploy manually from platform-argocd repo"
    ARGOCD_REPO_PATH=""
fi

if [ -n "$ARGOCD_REPO_PATH" ] && [ -f "$ARGOCD_REPO_PATH/projects/projects.yaml" ]; then
    kubectl apply -f "$ARGOCD_REPO_PATH/projects/projects.yaml"
    echo "✅ ArgoCD Projects created"
else
    echo "⚠️  Projects not applied - file not found"
fi

echo ""

# ============================================================================
# Deploy App-of-Apps (Optional)
# ============================================================================

# Uncomment this section when you're ready to auto-deploy the platform
# echo "→ Deploying App-of-Apps..."
# if [ -n "$ARGOCD_REPO_PATH" ] && [ -f "$ARGOCD_REPO_PATH/app-of-apps/root.yaml" ]; then
#     kubectl apply -f "$ARGOCD_REPO_PATH/app-of-apps/root.yaml"
#     echo "✅ App-of-Apps deployed"
# fi

# ============================================================================
# Display Access Information
# ============================================================================

echo "════════════════════════════════════════════════════════════════"
echo "✅ ArgoCD Bootstrap Complete!"
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "📍 Access ArgoCD:"
echo ""
echo "   URL:      https://localhost:8080"
echo "   Username: admin"
echo "   Password: \$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath=\"{.data.password}\" | base64 -d)"
echo ""
echo "🔌 To access ArgoCD UI, run:"
echo "   kubectl port-forward svc/argocd-server -n argocd 8080:443"
echo ""
echo "🔑 To get admin password, run:"
echo "   kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath=\"{.data.password}\" | base64 -d && echo"
echo ""
echo "════════════════════════════════════════════════════════════════"
