# Deployment Guide

Complete guide for deploying the Campaign Lifecycle Platform using ArgoCD.

## Prerequisites

- Kubernetes cluster (1.28+)
- kubectl configured
- Cluster admin access
- ArgoCD CLI (optional)

## Installation Steps

### 1. Install ArgoCD

\`\`\`bash
# Create namespace
kubectl create namespace argocd

# Install ArgoCD
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for ready
kubectl wait --for=condition=available --timeout=300s \\
  deployment/argocd-server -n argocd
\`\`\`

### 2. Access ArgoCD

\`\`\`bash
# Get password
kubectl -n argocd get secret argocd-initial-admin-secret \\
  -o jsonpath="{.data.password}" | base64 -d

# Port-forward
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Access: https://localhost:8080
# User: admin
# Password: [from above]
\`\`\`

### 3. Deploy Platform

\`\`\`bash
# Apply projects
kubectl apply -f projects/

# Deploy root app
kubectl apply -f app-of-apps/root.yaml

# Watch
kubectl get applications -n argocd --watch
\`\`\`

### 4. Verify

\`\`\`bash
argocd app list
kubectl get pods --all-namespaces
\`\`\`

## Troubleshooting

See TROUBLESHOOTING.md for common issues.
