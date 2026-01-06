# Encryption

> Data protection at rest and in transit.

---

## Encryption Overview

| Layer | Method | Key Management |
| ------- | -------- | ---------------- |
| In Transit | TLS 1.3 | Automatic (cert-manager) |
| At Rest (DB) | AES-256 | AWS KMS / GCP KMS |
| At Rest (S3) | AES-256-GCM | AWS KMS |
| Application | AES-256-GCM | Vault |

---

## Encryption at Rest

### Database Encryption

```yaml
database:
  encryption:
    enabled: true
    key_provider: "aws_kms"
    key_id: "arn:aws:kms:us-east-1:123:key/abc..."
```

### S3/GCS Encryption

```yaml
storage:
  encryption:
    type: "SSE-KMS"
    key_id: "${KMS_KEY_ID}"
  bucket_policy:
    enforce_encryption: true
```

---

## Encryption in Transit

### TLS Configuration

```yaml
tls:
  min_version: "1.3"
  cipher_suites:
    - "TLS_AES_256_GCM_SHA384"
    - "TLS_CHACHA20_POLY1305_SHA256"
```

### Service-to-Service mTLS

```yaml
mesh:
  mtls:
    mode: "STRICT"
  certificates:
    rotation_interval: "24h"
```

---

## Key Management

### Key Rotation

| Key Type | Rotation Period |
| ---------- | ----------------- |
| Master Key (KEK) | Annual |
| Data Keys (DEK) | Monthly |
| TLS Certificates | 90 days |
| JWT Signing Keys | Quarterly |

### Vault Integration

```yaml
vault:
  address: "https://vault.internal:8200"
  auth_method: "kubernetes"
  secrets_path: "secret/data/platform"
  transit_path: "transit/encrypt/platform-key"
```

---

## Sensitive Data Handling

### Classified Data

| Classification | Encryption | Access |
| ---------------- | ------------ | -------- |
| PII | Required | Logged |
| Credentials | Required | Audit |
| API Keys | Required | Restricted |
| Financial | Required | Logged |

### Data Masking

```yaml
masking:
  rules:
    - field: "email"
      type: "partial"
      show_chars: 3
    - field: "api_key"
      type: "full"
      replacement: "***"
```

---

## Navigation

- **Up:** [Security](README.md)
- **Previous:** [Permissions](permissions.md)
- **Next:** [Network Security](network.md)
