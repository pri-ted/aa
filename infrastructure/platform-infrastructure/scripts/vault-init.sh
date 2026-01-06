#!/bin/bash
set -euo pipefail

# Colors
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
RESET='\033[0m'

ENVIRONMENT=${1:-dev}
VAULT_NAMESPACE="platform-system"

echo -e "${CYAN}========================================${RESET}"
echo -e "${CYAN}Initializing HashiCorp Vault${RESET}"
echo -e "${CYAN}========================================${RESET}\n"

# Check kubectl
if ! kubectl cluster-info &> /dev/null; then
    echo -e "${RED}Error: kubectl not configured${RESET}"
    exit 1
fi

echo -e "${CYAN}Step 1: Installing Vault via Helm${RESET}"
helm repo add hashicorp https://helm.releases.hashicorp.com
helm repo update

# Vault configuration based on environment
if [ "$ENVIRONMENT" == "production" ]; then
    VAULT_REPLICAS=3
    VAULT_STORAGE_SIZE="50Gi"
else
    VAULT_REPLICAS=1
    VAULT_STORAGE_SIZE="10Gi"
fi

cat > /tmp/vault-values.yaml <<EOF
global:
  enabled: true
  tlsDisable: true  # Will use Istio/Ingress for TLS

server:
  enabled: true
  replicas: ${VAULT_REPLICAS}
  
  resources:
    requests:
      memory: 256Mi
      cpu: 250m
    limits:
      memory: 512Mi
      cpu: 500m

  dataStorage:
    enabled: true
    size: ${VAULT_STORAGE_SIZE}
    storageClass: gp3
  
  auditStorage:
    enabled: true
    size: ${VAULT_STORAGE_SIZE}

  ha:
    enabled: $([ "$VAULT_REPLICAS" -gt 1 ] && echo "true" || echo "false")
    replicas: ${VAULT_REPLICAS}
    raft:
      enabled: true
      setNodeId: true
      config: |
        ui = true
        
        listener "tcp" {
          tls_disable = 1
          address = "[::]:8200"
          cluster_address = "[::]:8201"
        }
        
        storage "raft" {
          path = "/vault/data"
          retry_join {
            leader_api_addr = "http://vault-0.vault-internal:8200"
          }
          retry_join {
            leader_api_addr = "http://vault-1.vault-internal:8200"
          }
          retry_join {
            leader_api_addr = "http://vault-2.vault-internal:8200"
          }
        }
        
        service_registration "kubernetes" {}

  service:
    enabled: true
    type: ClusterIP

ui:
  enabled: true
  serviceType: ClusterIP

injector:
  enabled: true
  resources:
    requests:
      memory: 128Mi
      cpu: 100m
    limits:
      memory: 256Mi
      cpu: 200m
EOF

helm upgrade --install vault hashicorp/vault \
  --namespace ${VAULT_NAMESPACE} \
  --create-namespace \
  --values /tmp/vault-values.yaml \
  --wait

echo -e "${CYAN}Step 2: Waiting for Vault pods to be ready${RESET}"
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=vault -n ${VAULT_NAMESPACE} --timeout=300s

echo -e "${CYAN}Step 3: Initializing Vault${RESET}"
INIT_OUTPUT=$(kubectl exec vault-0 -n ${VAULT_NAMESPACE} -- vault operator init -format=json)

# Parse and save keys
UNSEAL_KEYS=$(echo $INIT_OUTPUT | jq -r '.unseal_keys_b64[]')
ROOT_TOKEN=$(echo $INIT_OUTPUT | jq -r '.root_token')

# Save to secure location
VAULT_KEYS_FILE="/tmp/vault-keys-${ENVIRONMENT}.json"
echo $INIT_OUTPUT > ${VAULT_KEYS_FILE}
chmod 600 ${VAULT_KEYS_FILE}

echo -e "${CYAN}Step 4: Unsealing Vault${RESET}"
counter=0
for key in $(echo $UNSEAL_KEYS); do
    counter=$((counter + 1))
    if [ $counter -le 3 ]; then
        kubectl exec vault-0 -n ${VAULT_NAMESPACE} -- vault operator unseal $key
    fi
done

# Unseal other replicas if HA is enabled
if [ "$VAULT_REPLICAS" -gt 1 ]; then
    for i in $(seq 1 $((VAULT_REPLICAS - 1))); do
        echo -e "${CYAN}Unsealing vault-${i}${RESET}"
        counter=0
        for key in $(echo $UNSEAL_KEYS); do
            counter=$((counter + 1))
            if [ $counter -le 3 ]; then
                kubectl exec vault-${i} -n ${VAULT_NAMESPACE} -- vault operator unseal $key
            fi
        done
    done
fi

echo -e "${CYAN}Step 5: Configuring Vault${RESET}"
kubectl exec vault-0 -n ${VAULT_NAMESPACE} -- sh -c "
export VAULT_TOKEN=${ROOT_TOKEN}

# Enable KV secrets engine v2
vault secrets enable -version=2 -path=secret kv

# Enable database secrets engine
vault secrets enable database

# Enable AWS secrets engine
vault secrets enable aws

# Create service account for Kubernetes auth
vault auth enable kubernetes

vault write auth/kubernetes/config \
    kubernetes_host=https://kubernetes.default.svc:443 \
    kubernetes_ca_cert=@/var/run/secrets/kubernetes.io/serviceaccount/ca.crt \
    token_reviewer_jwt=@/var/run/secrets/kubernetes.io/serviceaccount/token

# Create policies
vault policy write platform-apps - <<EOF
path \"secret/data/platform/*\" {
  capabilities = [\"read\", \"list\"]
}
path \"database/creds/platform\" {
  capabilities = [\"read\"]
}
EOF

# Create Kubernetes role for service accounts
vault write auth/kubernetes/role/platform-apps \
    bound_service_account_names=* \
    bound_service_account_namespaces=platform-apps \
    policies=platform-apps \
    ttl=24h
"

echo -e "${CYAN}Step 6: Setting up External Secrets Operator${RESET}"
helm repo add external-secrets https://charts.external-secrets.io
helm repo update

cat > /tmp/external-secrets-values.yaml <<EOF
installCRDs: true
webhook:
  port: 9443
EOF

helm upgrade --install external-secrets \
  external-secrets/external-secrets \
  --namespace ${VAULT_NAMESPACE} \
  --values /tmp/external-secrets-values.yaml \
  --wait

# Create SecretStore for Vault
kubectl apply -f - <<EOF
apiVersion: external-secrets.io/v1beta1
kind: SecretStore
metadata:
  name: vault-backend
  namespace: platform-apps
spec:
  provider:
    vault:
      server: "http://vault.${VAULT_NAMESPACE}:8200"
      path: "secret"
      version: "v2"
      auth:
        kubernetes:
          mountPath: "kubernetes"
          role: "platform-apps"
          serviceAccountRef:
            name: "default"
EOF

echo -e "\n${GREEN}========================================${RESET}"
echo -e "${GREEN}Vault Initialization Complete!${RESET}"
echo -e "${GREEN}========================================${RESET}\n"

echo -e "${CYAN}Vault Information:${RESET}"
echo -e "  ${GREEN}Status:${RESET} $(kubectl exec vault-0 -n ${VAULT_NAMESPACE} -- vault status -format=json | jq -r .initialized)"
echo -e "  ${GREEN}URL:${RESET}    http://vault.${VAULT_NAMESPACE}:8200"

echo -e "\n${CYAN}Access Credentials:${RESET}"
echo -e "  ${GREEN}Root Token:${RESET} ${ROOT_TOKEN}"

echo -e "\n${CYAN}Unseal Keys (need 3 of 5):${RESET}"
counter=1
for key in $(echo $UNSEAL_KEYS); do
    echo -e "  ${GREEN}Key ${counter}:${RESET} ${key}"
    counter=$((counter + 1))
done

echo -e "\n${RED}CRITICAL SECURITY NOTICE:${RESET}"
echo -e "${RED}========================================${RESET}"
echo -e "${RED}1. Save these credentials in a secure location${RESET}"
echo -e "${RED}2. Delete this output from your terminal history${RESET}"
echo -e "${RED}3. Distribute unseal keys to different people${RESET}"
echo -e "${RED}4. Never commit these to git${RESET}"
echo -e "${RED}5. Keys saved to: ${VAULT_KEYS_FILE}${RESET}"
echo -e "${RED}6. Move this file to secure storage IMMEDIATELY${RESET}"
echo -e "${RED}========================================${RESET}\n"

echo -e "${CYAN}Next Steps:${RESET}"
echo -e "1. ${GREEN}Save credentials to password manager${RESET}"
echo -e "2. ${GREEN}Test Vault access:${RESET}"
echo -e "   kubectl port-forward svc/vault -n ${VAULT_NAMESPACE} 8200:8200"
echo -e "   export VAULT_ADDR='http://127.0.0.1:8200'"
echo -e "   vault login ${ROOT_TOKEN}"
echo -e "3. ${GREEN}Add application secrets:${RESET}"
echo -e "   vault kv put secret/platform/postgres password=<password>"
echo -e "4. ${GREEN}Delete temporary keys file after securing:${RESET}"
echo -e "   rm ${VAULT_KEYS_FILE}\n"
