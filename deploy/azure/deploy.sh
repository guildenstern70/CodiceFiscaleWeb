#!/usr/bin/env bash
set -euo pipefail

# -----------------------------------------------------------------------------
# deploy.sh
# End-to-end deployment script for Codice Fiscale Web to Azure.
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STACK_NAME="${1:-${PULUMI_STACK:-dev}}"

cd "${SCRIPT_DIR}"

echo "================================================================="
echo " Codice Fiscale Web - Azure Deployment (Pulumi + Podman)"
echo " Stack: ${STACK_NAME}"
echo "================================================================="

# 1. Check prerequisites
echo "==> [1/5] Checking prerequisites..."

for cmd in az pulumi podman node npm; do
  if ! command -v "${cmd}" >/dev/null 2>&1; then
    echo "Error: Required command '${cmd}' is not installed or not in PATH." >&2
    exit 1
  fi
done

# 2. Check Azure CLI authentication
echo "==> [2/5] Checking Azure CLI login..."
if ! az account show >/dev/null 2>&1; then
  echo "Error: Not logged in to Azure. Please run 'az login' first." >&2
  exit 1
fi
AZ_SUB="$(az account show --query name -o tsv)"
echo "Active Azure subscription: ${AZ_SUB}"

# 3. Check Podman machine (macOS)
echo "==> [3/5] Checking Podman environment..."
if [[ "$(uname)" == "Darwin" ]]; then
  if ! podman info >/dev/null 2>&1; then
    echo "Podman machine is not currently running. Starting podman machine..."
    podman machine start || {
      echo "Error: Could not start podman machine. Please initialize and start with 'podman machine start'." >&2
      exit 1
    }
  fi
fi

# 4. Install Node dependencies
echo "==> [4/5] Preparing Pulumi dependencies..."
if [[ ! -d "node_modules" ]]; then
  echo "Installing npm dependencies in ${SCRIPT_DIR}..."
  npm install
fi

# Build TypeScript to verify types
npm run build

# 5. Initialize/select Pulumi stack and execute deployment
echo "==> [5/5] Deploying infrastructure and container to Azure..."
if ! pulumi stack select "${STACK_NAME}" >/dev/null 2>&1; then
  echo "Creating stack '${STACK_NAME}'..."
  pulumi stack init "${STACK_NAME}"
fi

# Ensure default configs are set if not present
pulumi config set azure-native:location westeurope --non-interactive 2>/dev/null || true
pulumi config set elixir-fiscal-code-azure:resourceGroupName "Elixir-FiscalCode-Resouce" --non-interactive 2>/dev/null || true

# Run Pulumi up
pulumi up --yes --stack "${STACK_NAME}"

echo ""
echo "================================================================="
echo " Deployment Complete!"
echo "================================================================="
APP_URL="$(pulumi stack output applicationUrl -s "${STACK_NAME}" 2>/dev/null || echo "")"
FQDN="$(pulumi stack output containerFqdn -s "${STACK_NAME}" 2>/dev/null || echo "")"
RG="$(pulumi stack output resourceGroupNameOutput -s "${STACK_NAME}" 2>/dev/null || echo "Elixir-FiscalCode-Resouce")"
ACI="$(pulumi stack output containerGroupName -s "${STACK_NAME}" 2>/dev/null || echo "elixir-fiscal-code-aci")"

echo "Application URL:   ${APP_URL}"
echo "Container FQDN:    ${FQDN}"
echo "Resource Group:    ${RG}"
echo "Container Group:   ${ACI}"
echo ""
echo "To check container logs:"
echo "  az container logs --resource-group \"${RG}\" --name \"${ACI}\""
echo ""
echo "To destroy these resources when done:"
echo "  ./destroy.sh ${STACK_NAME}"
echo "================================================================="
