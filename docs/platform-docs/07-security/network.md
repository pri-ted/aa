# Network Security

> Network isolation, firewalls, and access controls.

---

## Network Architecture

```text
┌─────────────────────────────────────────────────────────────────────────────┐
│                           NETWORK TOPOLOGY                                  │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│   Internet                                                                  │
│       │                                                                     │
│       ▼                                                                     │
│   ┌─────────────────┐                                                       │
│   │   WAF / CDN     │  ← DDoS protection, rate limiting                     │
│   │   (Cloudflare)   │                                                       │
│   └────────┬────────┘                                                       │
│            │                                                                │
│            ▼                                                                │
│   ┌─────────────────┐                                                       │
│   │  Load Balancer  │  ← TLS termination                                    │
│   │  (Public)       │                                                       │
│   └────────┬────────┘                                                       │
│            │                                                                │
│  ══════════╪════════════════════════════════════════════════════════════    │
│  DMZ       │                                                                │
│            ▼                                                                │
│   ┌─────────────────┐                                                       │
│   │   API Gateway   │  ← Auth, rate limiting                                │
│   │   (Kong)        │                                                       │
│   └────────┬────────┘                                                       │
│            │                                                                │
│  ══════════╪════════════════════════════════════════════════════════════    │
│  Private   │                                                                │
│            ▼                                                                │
│   ┌─────────────────────────────────────────────────────────────────┐       │
│   │                    Application Tier                             │       │
│   │   ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐            │       │
│   │   │  Auth   │  │ Config   │  │   ETL   │  │  Query  │            │       │
│   │   └─────────┘  └─────────┘  └─────────┘  └─────────┘            │       │
│   └─────────────────────────────────────────────────────────────────┘       │
│            │                                                                │
│  ══════════╪════════════════════════════════════════════════════════════    │
│  Data      │                                                                │
│            ▼                                                                │
│   ┌─────────────────────────────────────────────────────────────────┐       │
│   │                      Data Tier                                  │       │
│   │   ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐            │       │
│   │   │ Postgres│  │ClickHse │  │  Redis  │  │  Kafka  │            │       │
│   │   └─────────┘  └─────────┘  └─────────┘  └─────────┘            │       │
│   └─────────────────────────────────────────────────────────────────┘       │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Network Segmentation

### Kubernetes Namespaces

| Namespace | Purpose | Network Policy |
| ----------- | --------- | ---------------- |
| platform-system | Core infra (ingress, cert-manager) | Restricted |
| platform-apps | Application services | Service mesh |
| platform-data | Databases, message queues | Highly restricted |
| platform-monitoring | Observability stack | Read from all |

### Network Policies

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: data-tier-isolation
  namespace: platform-data
spec:
  podSelector: {}
  policyTypes:
    - Ingress
    - Egress
  ingress:
    - from:
        - namespaceSelector:
            matchLabels:
              name: platform-apps
  egress:
    - to:
        - namespaceSelector:
            matchLabels:
              name: platform-data
```

---

## Firewall Rules

### Ingress Rules

| Source | Destination | Port | Protocol | Action |
| -------- | ------------- | ------ | ---------- | -------- |
| Internet | Load Balancer | 443 | HTTPS | Allow |
| Load Balancer | API Gateway | 8000 | HTTP | Allow |
| API Gateway | App Services | 8001-8012 | HTTP | Allow |
| App Services | Data Tier | 5432,9000,6379 | TCP | Allow |
| * | * | * | * | Deny |

### Egress Rules

| Source | Destination | Port | Purpose |
| -------- | ------------- | ------ | --------- |
| Connector Service | DSP APIs | 443 | API calls |
| Notification Service | SMTP/Slack | 443,587 | Alerts |
| All Services | KMS | 443 | Key management |
| All Services | Vault | 8200 | Secrets |

---

## DDoS Protection

### Cloudflare Configuration

```yaml
cloudflare:
  ddos_protection:
    sensitivity: "medium"
    
  rate_limiting:
    - path: "/api/v1/auth/login"
      requests: 10
      period: 60
      action: "challenge"
    
    - path: "/api/v1/*"
      requests: 1000
      period: 60
      action: "block"
  
  bot_management:
    enabled: true
    action: "challenge"
```

### WAF Rules

```yaml
waf:
  managed_rules:
    - owasp_crs
    - cloudflare_managed
  
  custom_rules:
    - name: "Block SQL Injection"
      expression: 'http.request.uri.query contains "SELECT" or http.request.uri.query contains "UNION"'
      action: "block"
```

---

## VPN / Private Connectivity

### Site-to-Site VPN

```yaml
vpn:
  type: "ipsec"
  local_gateway: "vpn-gw.platform.internal"
  
  tunnels:
    - name: "customer-dc"
      remote_gateway: "vpn.customer.com"
      psk: "${VPN_PSK}"
      ike_version: 2
      phase1:
        encryption: "aes256"
        hash: "sha256"
        dh_group: 14
```

### Private Link / Private Service Connect

```yaml
private_endpoints:
  - service: "postgresql"
    endpoint: "psql.privatelink.database.azure.com"
    
  - service: "clickhouse"
    endpoint: "ch.privatelink.platform.internal"
```

---

## IP Allowlisting

### DSP IP Ranges

```yaml
allowlist:
  dv360:
    - "216.58.192.0/19"
    - "172.217.0.0/16"
  
  ttd:
    - "52.20.0.0/16"
    - "34.235.0.0/16"
```

### Customer Egress IPs

```yaml
customer_ips:
  org_456:
    - "203.0.113.0/24"
    - "198.51.100.0/24"
```

---

## Service Mesh (Istio)

### mTLS Configuration

```yaml
apiVersion: security.istio.io/v1beta1
kind: PeerAuthentication
metadata:
  name: default
  namespace: platform-apps
spec:
  mtls:
    mode: STRICT
```

### Authorization Policy

```yaml
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: auth-service-policy
spec:
  selector:
    matchLabels:
      app: auth-service
  rules:
    - from:
        - source:
            principals: ["cluster.local/ns/platform-apps/sa/api-gateway"]
      to:
        - operation:
            methods: ["POST", "GET"]
            paths: ["/api/v1/auth/*"]
```

---

## Navigation

- **Up:** [Security](README.md)
- **Previous:** [Encryption](encryption.md)
