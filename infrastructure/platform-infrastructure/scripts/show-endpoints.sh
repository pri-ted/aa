#!/bin/bash
set -euo pipefail

# ============================================================================
# Show Endpoints Script
# Displays access information for all platform services
# ============================================================================

NAMESPACE="${NAMESPACE:-atomicads-local}"

# Colors
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

get_nodeport() {
    local service=$1
    local port_name=${2:-}
    
    if [ -z "$port_name" ]; then
        kubectl get svc "$service" -n "$NAMESPACE" -o jsonpath='{.spec.ports[0].nodePort}' 2>/dev/null || echo "N/A"
    else
        kubectl get svc "$service" -n "$NAMESPACE" -o jsonpath="{.spec.ports[?(@.name=='$port_name')].nodePort}" 2>/dev/null || echo "N/A"
    fi
}

get_clusterip() {
    local service=$1
    kubectl get svc "$service" -n "$NAMESPACE" -o jsonpath='{.spec.clusterIP}' 2>/dev/null || echo "N/A"
}

check_service_exists() {
    local service=$1
    kubectl get svc "$service" -n "$NAMESPACE" &>/dev/null
}

echo ""
echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}                    SERVICE ENDPOINTS${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
echo ""

# ============================================================================
# Persistence Layer
# ============================================================================

echo -e "${GREEN}━━━ Persistence Layer ━━━${NC}"
echo ""

if check_service_exists "postgres"; then
    PG_PORT=$(get_nodeport "postgres" "postgres")
    PG_IP=$(get_clusterip "postgres")
    echo "🐘 PostgreSQL"
    echo "   Local:      localhost:${PG_PORT}"
    echo "   Cluster:    postgres.${NAMESPACE}.svc.cluster.local:5432"
    echo "   Connection: postgresql://platform:platform_dev@localhost:${PG_PORT}/platform_dev"
    echo ""
fi

if check_service_exists "clickhouse"; then
    CH_HTTP=$(get_nodeport "clickhouse" "http")
    CH_NATIVE=$(get_nodeport "clickhouse" "native")
    echo "🏠 ClickHouse"
    echo "   HTTP:       localhost:${CH_HTTP}"
    echo "   Native:     localhost:${CH_NATIVE}"
    echo "   Cluster:    clickhouse.${NAMESPACE}.svc.cluster.local:8123"
    echo ""
fi

if check_service_exists "redis"; then
    REDIS_PORT=$(get_nodeport "redis")
    echo "🔴 Redis"
    echo "   Local:      localhost:${REDIS_PORT}"
    echo "   Cluster:    redis.${NAMESPACE}.svc.cluster.local:6379"
    echo "   CLI:        redis-cli -h localhost -p ${REDIS_PORT}"
    echo ""
fi

if check_service_exists "kafka"; then
    KAFKA_PORT=$(get_nodeport "kafka")
    echo "📨 Kafka"
    echo "   Local:      localhost:${KAFKA_PORT}"
    echo "   Cluster:    kafka.${NAMESPACE}.svc.cluster.local:9092"
    echo ""
fi

if check_service_exists "minio"; then
    MINIO_API=$(get_nodeport "minio" "api")
    MINIO_CONSOLE=$(get_nodeport "minio" "console")
    echo "🗄️  MinIO (Iceberg Storage)"
    echo "   API:        localhost:${MINIO_API}"
    echo "   Console:    http://localhost:${MINIO_CONSOLE}"
    echo "   Credentials: minioadmin / minioadmin"
    echo ""
fi

# ============================================================================
# Monitoring Stack
# ============================================================================

echo -e "${GREEN}━━━ Monitoring Stack ━━━${NC}"
echo ""

if check_service_exists "prometheus" || check_service_exists "prometheus-server"; then
    PROM_SVC=$(kubectl get svc -n "$NAMESPACE" -o name | grep prometheus | head -1 | cut -d/ -f2)
    PROM_PORT=$(get_nodeport "$PROM_SVC")
    echo "📈 Prometheus"
    echo "   URL:        http://localhost:${PROM_PORT}"
    echo "   Port Forward: kubectl port-forward -n ${NAMESPACE} svc/${PROM_SVC} 9090:9090"
    echo ""
fi

if check_service_exists "grafana"; then
    GRAFANA_PORT=$(get_nodeport "grafana")
    echo "📊 Grafana"
    echo "   URL:        http://localhost:${GRAFANA_PORT}"
    echo "   Credentials: admin / admin"
    echo "   Port Forward: kubectl port-forward -n ${NAMESPACE} svc/grafana 3000:80"
    echo ""
fi

if check_service_exists "loki"; then
    LOKI_PORT=$(get_nodeport "loki")
    echo "📋 Loki (Logs)"
    echo "   URL:        http://localhost:${LOKI_PORT}"
    echo ""
fi

# ============================================================================
# ArgoCD
# ============================================================================

if kubectl get namespace argocd &>/dev/null; then
    echo -e "${GREEN}━━━ GitOps (ArgoCD) ━━━${NC}"
    echo ""
    
    echo "🔄 ArgoCD"
    echo "   URL:        https://localhost:8080"
    echo "   Username:   admin"
    echo "   Password:   \$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath=\"{.data.password}\" | base64 -d)"
    echo "   Port Forward: kubectl port-forward -n argocd svc/argocd-server 8080:443"
    echo ""
fi

# ============================================================================
# Application Services
# ============================================================================

SERVICE_COUNT=$(kubectl get svc -n "$NAMESPACE" -l tier=application --no-headers 2>/dev/null | wc -l)

if [ "$SERVICE_COUNT" -gt 0 ]; then
    echo -e "${GREEN}━━━ Application Services ━━━${NC}"
    echo ""
    
    kubectl get svc -n "$NAMESPACE" -l tier=application --no-headers 2>/dev/null | while read -r line; do
        SVC_NAME=$(echo "$line" | awk '{print $1}')
        SVC_PORT=$(echo "$line" | awk '{print $5}' | cut -d: -f2 | cut -d/ -f1)
        echo "   ${SVC_NAME}: localhost:${SVC_PORT}"
    done
    echo ""
fi

# ============================================================================
# Quick Access Commands
# ============================================================================

echo -e "${GREEN}━━━ Quick Access Commands ━━━${NC}"
echo ""
echo "  Database Shells:"
echo "    make db-shell-postgres    # PostgreSQL CLI"
echo "    make db-shell-clickhouse  # ClickHouse CLI"
echo "    make db-shell-redis       # Redis CLI"
echo ""
echo "  Monitoring:"
echo "    make grafana              # Open Grafana"
echo "    make prometheus           # Open Prometheus"
echo "    make argocd-ui            # Open ArgoCD"
echo ""
echo "  Logs:"
echo "    make logs-local           # Stream all logs"
echo "    kubectl logs -f <pod> -n ${NAMESPACE}"
echo ""
echo "  Status:"
echo "    make status               # Platform status"
echo "    kubectl get pods -n ${NAMESPACE}"
echo ""

echo -e "${BLUE}════════════════════════════════════════════════════════════════${NC}"
echo ""
