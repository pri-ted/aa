#!/bin/bash
set -e

APP_NAME="$1"

if [ -z "$APP_NAME" ]; then
  echo "Usage: ./rollback.sh <app-name>"
  exit 1
fi

echo "⏪ Rolling back $APP_NAME..."

argocd app rollback "$APP_NAME"

echo "✅ Rollback complete"
