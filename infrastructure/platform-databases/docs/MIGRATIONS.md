# Migration Guide

## Creating Migrations

1. Create new file: `NNN_description.sql`
2. Always use `IF NOT EXISTS` / `IF EXISTS`
3. Test rollback if possible
4. Document breaking changes

## Running Migrations

```bash
./scripts/migrate.sh
```

## Best Practices

- Sequential numbering
- Idempotent operations
- One-way migrations
- Test on staging first
