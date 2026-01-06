# Alert Configuration

## Alert Levels

- **Critical**: PagerDuty + Slack
- **Warning**: Slack only
- **Info**: Logging only

## Adding Alerts

1. Create YAML in alerts/
2. Apply: `kubectl apply -f alerts/`
3. Verify: Check Prometheus UI

## Routing

Configure in AlertManager:
```yaml
routes:
  - match:
      severity: critical
    receiver: pagerduty
  - match:
      severity: warning
    receiver: slack
```
