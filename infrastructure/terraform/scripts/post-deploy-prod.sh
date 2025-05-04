#!/bin/bash

set -e

# Get cluster credentials
cluster_name=$(terraform output -raw aks_cluster_name)
resource_group=$(terraform output -raw resource_group_name)

echo "Running post-deployment validation for production environment..."

# Get AKS credentials
echo "Getting AKS credentials..."
az aks get-credentials \
    --resource-group "$resource_group" \
    --name "$cluster_name" \
    --overwrite-existing

# Validate node pool configuration
echo "Validating node pools..."
node_count=$(kubectl get nodes -l nodepool=application -o json | jq '.items | length')
if [ "$node_count" -lt 4 ]; then
    echo "Error: Expected at least 4 application nodes in production"
    exit 1
fi

# Check pod security policies
echo "Checking pod security policies..."
if ! kubectl auth can-i use podsecuritypolicy --all-namespaces; then
    echo "Error: Pod security policies not enabled"
    exit 1
fi

# Validate network policies
echo "Validating network policies..."
if ! kubectl get networkpolicies --all-namespaces; then
    echo "Error: Network policies not configured"
    exit 1
fi

# Check monitoring components
echo "Checking monitoring components..."
for component in prometheus-server grafana loki-stack tempo; do
    if ! kubectl get deployment -n monitoring $component; then
        echo "Error: $component not deployed"
        exit 1
    fi
done

# Validate Key Vault integration
echo "Validating Key Vault integration..."
if ! az keyvault secret list --vault-name "$cluster_name-kv" --query length -o tsv > /dev/null; then
    echo "Error: Unable to access Key Vault"
    exit 1
fi

# Check Application Gateway health
echo "Checking Application Gateway health..."
gateway_name="${cluster_name}-appgw"
gateway_health=$(az network application-gateway show \
    --name "$gateway_name" \
    --resource-group "$resource_group" \
    --query "operationalState" \
    -o tsv)

if [ "$gateway_health" != "Running" ]; then
    echo "Error: Application Gateway not healthy. State: $gateway_health"
    exit 1
fi

# Validate WAF policy
echo "Checking WAF policy..."
waf_mode=$(az network application-gateway waf-policy list \
    --resource-group "$resource_group" \
    --query "[0].policySettings.mode" \
    -o tsv)

if [ "$waf_mode" != "Prevention" ]; then
    echo "Error: WAF not in Prevention mode"
    exit 1
fi

# Check diagnostic settings
echo "Validating diagnostic settings..."
components=("aks" "appgw" "keyvault")
for component in "${components[@]}"; do
    if ! az monitor diagnostic-settings list \
        --resource "$cluster_name-$component" \
        --resource-group "$resource_group" \
        --query "[?contains(name, 'diag')].id" \
        -o tsv > /dev/null; then
        echo "Error: Diagnostic settings not configured for $component"
        exit 1
    fi
done

# Final health check
echo "Running final health checks..."
kubectl get nodes
kubectl get pods --all-namespaces
kubectl cluster-info

echo "Production post-deployment validation completed successfully"