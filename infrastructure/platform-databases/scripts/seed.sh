#!/bin/bash
set -e

DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-5432}"
DB_USER="${DB_USER:-platform}"
DB_NAME="${DB_NAME:-platform_dev}"

echo "Loading seed data..."
PGPASSWORD="${DB_PASSWORD}" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" \
    -f "$(dirname "$0")/../postgresql/migrations/002_seed_data.sql"
echo "✅ Seed data loaded"
