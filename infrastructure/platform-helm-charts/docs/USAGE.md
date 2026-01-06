# Usage Guide

## Installing a Service

```bash
helm install service-auth ./charts/service-template \
  --set serviceName=auth \
  --set image.repository=service-auth \
  --set image.tag=v1.0.0
```

## Customizing

Create a values file:

```yaml
serviceName: myservice
replicaCount: 5
image:
  repository: myorg/myservice
  tag: v2.0.0
```

Install:

```bash
helm install myservice ./charts/service-template -f my-values.yaml
```

## Upgrading

```bash
helm upgrade myservice ./charts/service-template -f my-values.yaml
```

## Uninstalling

```bash
helm uninstall myservice
```
