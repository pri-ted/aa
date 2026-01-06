# Kubernetes Architecture

> Cluster design, namespaces, and resource management.

---

## Cluster Overview

| Property | Value |
| ---------- | ------- |
| **Distribution** | EKS / GKE / AKS |
| **Version** | 1.28+ |
| **Node Pools** | 3 (system, apps, data) |
| **Total Nodes** | 18 (at 1000 orgs) |

---

## Node Pools

### System Pool

```yaml
pool:
  name: "system"
  node_count: 3
  instance_type: "t3.large"
  
  labels:
    pool: "system"
  
  taints:
    - key: "CriticalAddonsOnly"
      effect: "NoSchedule"
  
  workloads:
    - ingress-nginx
    - cert-manager
    - external-dns
    - argocd
```

### Application Pool

```yaml
pool:
  name: "apps"
  node_count: 9
  instance_type: "m5.xlarge"
  
  autoscaling:
    min: 6
    max: 15
    
  labels:
    pool: "apps"
  
  workloads:
    - auth-service
    - config-service
    - connector-service
    - etl-service
    - query-service
    # ... all application services
```

### Data Pool

```yaml
pool:
  name: "data"
  node_count: 6
  instance_type: "r5.2xlarge"
  
  storage:
    type: "gp3"
    iops: 10000
    
  labels:
    pool: "data"
  
  workloads:
    - postgresql
    - clickhouse
    - redis
    - kafka
```

---

## Namespaces

### Namespace Structure

```code
platform-system      # Core infrastructure
platform-apps        # Application services
platform-data        # Databases and queues
platform-monitoring  # Observability stack
platform-staging     # Staging environment
```

### Namespace Configuration

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: platform-apps
  labels:
    istio-injection: enabled
    environment: production
  annotations:
    scheduler.alpha.kubernetes.io/defaultTolerations: |
      [{"key": "pool", "operator": "Equal", "value": "apps", "effect": "NoSchedule"}]
---
apiVersion: v1
kind: ResourceQuota
metadata:
  name: platform-apps-quota
  namespace: platform-apps
spec:
  hard:
    requests.cpu: "100"
    requests.memory: "200Gi"
    limits.cpu: "200"
    limits.memory: "400Gi"
    pods: "500"
```

---

## Service Deployment

### Deployment Template

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: auth-service
  namespace: platform-apps
spec:
  replicas: 3
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
  selector:
    matchLabels:
      app: auth-service
  template:
    metadata:
      labels:
        app: auth-service
        version: v1.2.3
    spec:
      serviceAccountName: auth-service
      
      affinity:
        podAntiAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            - labelSelector:
                matchLabels:
                  app: auth-service
              topologyKey: kubernetes.io/hostname
      
      containers:
        - name: auth-service
          image: platform/auth-service:v1.2.3
          
          ports:
            - containerPort: 8001
              name: http
            - containerPort: 9001
              name: grpc
          
          resources:
            requests:
              cpu: "500m"
              memory: "512Mi"
            limits:
              cpu: "1000m"
              memory: "1Gi"
          
          livenessProbe:
            httpGet:
              path: /health
              port: 8001
            initialDelaySeconds: 10
            periodSeconds: 10
          
          readinessProbe:
            httpGet:
              path: /ready
              port: 8001
            initialDelaySeconds: 5
            periodSeconds: 5
          
          envFrom:
            - configMapRef:
                name: auth-service-config
            - secretRef:
                name: auth-service-secrets
```

---

## Horizontal Pod Autoscaler

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: auth-service-hpa
  namespace: platform-apps
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: auth-service
  
  minReplicas: 3
  maxReplicas: 10
  
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 70
    
    - type: Resource
      resource:
        name: memory
        target:
          type: Utilization
          averageUtilization: 80
  
  behavior:
    scaleDown:
      stabilizationWindowSeconds: 300
    scaleUp:
      stabilizationWindowSeconds: 60
```

---

## Pod Disruption Budget

```yaml
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: auth-service-pdb
  namespace: platform-apps
spec:
  minAvailable: 2
  selector:
    matchLabels:
      app: auth-service
```

---

## Service Mesh (Istio)

### Virtual Service

```yaml
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: auth-service
  namespace: platform-apps
spec:
  hosts:
    - auth-service
  http:
    - timeout: 30s
      retries:
        attempts: 3
        perTryTimeout: 10s
        retryOn: gateway-error,connect-failure,refused-stream
      route:
        - destination:
            host: auth-service
            port:
              number: 8001
```

---

## Ingress

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: platform-ingress
  namespace: platform-apps
  annotations:
    kubernetes.io/ingress.class: nginx
    cert-manager.io/cluster-issuer: letsencrypt-prod
    nginx.ingress.kubernetes.io/rate-limit: "100"
spec:
  tls:
    - hosts:
        - api.platform.example.com
      secretName: platform-tls
  rules:
    - host: api.platform.example.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: api-gateway
                port:
                  number: 8000
```

---

## Navigation

- **Up:** [Infrastructure](README.md)
- **Next:** [Deployment](deployment.md)
