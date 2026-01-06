#!/bin/bash
# Import all dashboards to Grafana

GRAFANA_URL="${GRAFANA_URL:-http://localhost:3000}"
GRAFANA_USER="${GRAFANA_USER:-admin}"
GRAFANA_PASSWORD="${GRAFANA_PASSWORD:-admin123}"

for dashboard in dashboards/*/*.json; do
    echo "Importing $(basename $dashboard)..."
    curl -X POST "$GRAFANA_URL/api/dashboards/db" \
        -H "Content-Type: application/json" \
        -u "$GRAFANA_USER:$GRAFANA_PASSWORD" \
        -d @"$dashboard"
done

echo "✅ All dashboards imported"
