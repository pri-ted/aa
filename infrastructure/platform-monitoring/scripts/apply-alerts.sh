#!/bin/bash
# Apply all alert rules to Kubernetes

echo "Applying critical alerts..."
kubectl apply -f alerts/critical/

echo "Applying warning alerts..."
kubectl apply -f alerts/warning/

echo "✅ All alerts applied"
