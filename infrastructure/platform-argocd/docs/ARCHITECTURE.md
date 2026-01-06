# ArgoCD Architecture

## Overview

ArgoCD manages deployments using GitOps principles.

## Components

- **Application Controller**: Monitors Git repos
- **Repo Server**: Generates K8s manifests
- **API Server**: Provides API/UI
- **Redis**: Cache

## Sync Process

1. Application Controller polls Git repo
2. Detects changes
3. Repo Server generates manifests
4. Controller applies to cluster

## Best Practices

- Use app-of-apps pattern
- Enable auto-sync
- Use sync waves
- Monitor health
