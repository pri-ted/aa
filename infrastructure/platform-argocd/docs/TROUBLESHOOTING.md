# Troubleshooting Guide

Common issues and solutions.

## Application Won't Sync

\`\`\`bash
# Check status
argocd app get service-auth

# Force refresh
argocd app get service-auth --refresh --hard

# Force sync
argocd app sync service-auth --force
\`\`\`

## Health Degraded

\`\`\`bash
# Check pods
kubectl get pods -n platform-apps

# Check logs
kubectl logs -l app=service-auth -n platform-apps
\`\`\`

## More Help

- GitHub Issues
- Slack: #platform-argocd
- Email: platform-team@company.com
