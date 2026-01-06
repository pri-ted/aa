#!/bin/bash
set -e

DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-5432}"
DB_USER="${DB_USER:-platform}"
DB_NAME="${DB_NAME:-platform_dev}"

MIGRATIONS_DIR="$(cd "$(dirname "$0")/../postgresql/migrations" && pwd)"

echo "Running migrations..."
for migration in "$MIGRATIONS_DIR"/*.sql; do
    echo "  - $(basename "$migration")"
    PGPASSWORD="${DB_PASSWORD}" psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -f "$migration"
done
echo "✅ All migrations completed"
