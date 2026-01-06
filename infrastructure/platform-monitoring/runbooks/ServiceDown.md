# Runbook: ServiceDown

## Alert
**Severity:** Critical  
**Team:** Platform  
**PagerDuty:** Yes

## Description
A service has been unavailable for more than 5 minutes.

## Impact
- Service unavailable to users
- Potential data processing delays
- Downstream service failures

## Diagnosis

### 1. Check Pod Status
```bash
kubectl get pods -n platform-apps -l app=<service-name>
```

### 2. Check Pod Logs
```bash
kubectl logs -l app=<service-name> -n platform-apps --tail=100
```

### 3. Check Events
```bash
kubectl get events -n platform-apps --sort-by='.lastTimestamp'
```

### 4. Check Resource Usage
```bash
kubectl top pods -n platform-apps
```

## Resolution

### If Pod is CrashLooping
```bash
# Check logs for errors
kubectl logs <pod-name> -n platform-apps --previous

# Check resource limits
kubectl describe pod <pod-name> -n platform-apps
```

### If Out of Memory
```bash
# Increase memory limits
kubectl edit deployment <service-name> -n platform-apps
# Update: resources.limits.memory: 1Gi
```

### If Image Pull Error
```bash
# Check image exists
docker pull <image-name>

# Update image pull secrets
kubectl get secrets -n platform-apps
```

## Escalation
- **Level 1:** Platform team (#platform-team)
- **Level 2:** On-call engineer (via PagerDuty)
- **Level 3:** Platform lead
