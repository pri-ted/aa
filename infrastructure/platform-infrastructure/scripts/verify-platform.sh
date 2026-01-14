#!/bin/bash
set -euo pipefail

# ============================================================================
# Platform Verification Script
# Checks health of all platform components
# ============================================================================

NAMESPACE="${NAMESPACE:-atomicads-local}"
TIMEOUT="${TIMEOUT:-300}"

echo "════════════════════════════════════════════════════════════════"
echo "🔍 Verifying Platform Health"
echo "════════════════════════════════════════════════════════════════"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Track overall status
ALL_HEALTHY=true

# ============================================================================
# Helper Functions
# ============================================================================

check_deployment() {
    local name=$1
    local label=$2
    
    echo -n "  → ${name}... "
    
    if kubectl get deployment -n "$NAMESPACE" -l "$label" &>/dev/null; then
        if kubectl wait --for=condition=available --timeout=${TIMEOUT}s \
            deployment -n "$NAMESPACE" -l "$label" &>/dev/null; then
            echo -e "${GREEN}✓ Ready${NC}"
            return 0
        else
            echo -e "${RED}✗ Not Ready${NC}"
            ALL_HEALTHY=false
            return 1
        fi
    else
        echo -e "${YELLOW}⊘ Not Found${NC}"
        return 0  # Don't fail if optional component not deployed
    fi
}

check_statefulset() {
    local name=$1
    local label=$2
    
    echo -n "  → ${name}... "
    
    if kubectl get statefulset -n "$NAMESPACE" -l "$label" &>/dev/null; then
        if kubectl wait --for=jsonpath='{.status.readyReplicas}'=1 --timeout=${TIMEOUT}s \
            statefulset -n "$NAMESPACE" -l "$label" &>/dev/null; then
            echo -e "${GREEN}✓ Ready${NC}"
            return 0
        else
            echo -e "${RED}✗ Not Ready${NC}"
            ALL_HEALTHY=false
            return 1
        fi
    else
        echo -e "${YELLOW}⊘ Not Found${NC}"
        return 0
    fi
}

check_pod_by_label() {
    local name=$1
    local label=$2
    
    echo -n "  → ${name}... "
    
    if kubectl get pods -n "$NAMESPACE" -l "$label" &>/dev/null 2>&1; then
        local pod_count=$(kubectl get pods -n "$NAMESPACE" -l "$label" --no-headers 2>/dev/null | wc -l)
        if [ "$pod_count" -gt 0 ]; then
            if kubectl wait --for=condition=ready --timeout=${TIMEOUT}s \
                pod -n "$NAMESPACE" -l "$label" &>/dev/null; then
                echo -e "${GREEN}✓ Ready (${pod_count} pods)${NC}"
                return 0
            else
                echo -e "${RED}✗ Not Ready${NC}"
                ALL_HEALTHY=false
                return 1
            fi
        else
            echo -e "${YELLOW}⊘ No pods found${NC}"
            return 0
        fi
    else
        echo -e "${YELLOW}⊘ Not Found${NC}"
        return 0
    fi
}

# ============================================================================
# Check Namespace
# ============================================================================

echo "Checking namespace..."
if kubectl get namespace "$NAMESPACE" &>/dev/null; then
    echo -e "  ${GREEN}✓${NC} Namespace '${NAMESPACE}' exists"
else
    echo -e "  ${RED}✗${NC} Namespace '${NAMESPACE}' not found"
    ALL_HEALTHY=false
fi
echo ""

# ============================================================================
# Check Persistence Layer
# ============================================================================

echo "Checking persistence layer..."

check_statefulset "PostgreSQL" "app=postgres"
check_statefulset "ClickHouse" "app=clickhouse"
check_deployment "Redis" "app=redis"
check_statefulset "Kafka" "app=kafka"
check_statefulset "Zookeeper" "app=zookeeper"
check_deployment "MinIO (Iceberg)" "app=minio"

echo ""

# ============================================================================
# Check Monitoring Stack
# ============================================================================

echo "Checking monitoring stack..."

check_deployment "Prometheus" "app=prometheus"
check_deployment "Grafana" "app=grafana"
check_deployment "Loki" "app=loki"

echo ""

# ============================================================================
# Check ArgoCD
# ============================================================================

echo "Checking ArgoCD..."

if kubectl get namespace argocd &>/dev/null; then
    check_deployment "ArgoCD Server" "app.kubernetes.io/name=argocd-server" || true
    check_deployment "ArgoCD Repo Server" "app.kubernetes.io/name=argocd-repo-server" || true
    check_deployment "ArgoCD App Controller" "app.kubernetes.io/name=argocd-application-controller" || true
else
    echo -e "  ${YELLOW}⊘ ArgoCD namespace not found${NC}"
fi

echo ""

# ============================================================================
# Check Services (if deployed)
# ============================================================================

echo "Checking application services..."

# These might not be deployed yet in local, so we won't fail on them
check_deployment "Auth Service" "app=service-auth" || true
check_deployment "Config Service" "app=service-config" || true
check_deployment "ETL Service" "app=service-etl" || true

echo ""

# ============================================================================
# Check Storage
# ============================================================================

echo "Checking persistent volumes..."

PVC_COUNT=$(kubectl get pvc -n "$NAMESPACE" --no-headers 2>/dev/null | wc -l)
PVC_BOUND=$(kubectl get pvc -n "$NAMESPACE" --field-selector=status.phase=Bound --no-headers 2>/dev/null | wc -l)

if [ "$PVC_COUNT" -gt 0 ]; then
    if [ "$PVC_COUNT" -eq "$PVC_BOUND" ]; then
        echo -e "  ${GREEN}✓${NC} All PVCs bound (${PVC_BOUND}/${PVC_COUNT})"
    else
        echo -e "  ${YELLOW}⚠${NC} Some PVCs not bound (${PVC_BOUND}/${PVC_COUNT})"
        kubectl get pvc -n "$NAMESPACE" | grep -v "Bound" | tail -n +2
    fi
else
    echo -e "  ${YELLOW}⊘${NC} No PVCs found"
fi

echo ""

# ============================================================================
# Final Summary
# ============================================================================

echo "════════════════════════════════════════════════════════════════"
if [ "$ALL_HEALTHY" = true ]; then
    echo -e "${GREEN}✅ All Critical Components Healthy${NC}"
    echo "════════════════════════════════════════════════════════════════"
    exit 0
else
    echo -e "${RED}❌ Some Components Unhealthy${NC}"
    echo "════════════════════════════════════════════════════════════════"
    echo ""
    echo "To troubleshoot:"
    echo "  kubectl get pods -n $NAMESPACE"
    echo "  kubectl describe pod <pod-name> -n $NAMESPACE"
    echo "  kubectl logs <pod-name> -n $NAMESPACE"
    exit 1
fi
