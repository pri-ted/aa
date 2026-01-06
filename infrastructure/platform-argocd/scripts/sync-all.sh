#!/bin/bash
set -e

echo "🔄 Syncing all applications..."

argocd app sync -l app.kubernetes.io/part-of=AtomicAds

echo "✅ All applications synced"
