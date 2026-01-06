#!/bin/bash
set -e

echo "🚀 Deploying AtomicAds Platform via ArgoCD"
echo ""

# Apply projects
echo "Applying ArgoCD projects..."
kubectl apply -f projects/

# Apply root app
echo "Applying root application..."
kubectl apply -f app-of-apps/root.yaml

echo ""
echo "✅ Deployment initiated"
echo "Watch progress: kubectl get applications -n argocd --watch"
