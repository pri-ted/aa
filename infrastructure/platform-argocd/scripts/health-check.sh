#!/bin/bash

echo "🔍 Platform Health Check"
echo "======================="
echo ""

argocd app list | grep -E "platform|service|vault|prometheus|grafana|postgresql|clickhouse|redis"

echo ""
echo "Detailed status:"
kubectl get pods -n platform-system
kubectl get pods -n platform-data
kubectl get pods -n platform-apps
kubectl get pods -n platform-monitoring
