#!/usr/bin/env bash
set -euo pipefail

# -----------------------------------------------------------------------------
# push-image.sh
# Tags and pushes the local Podman image to Azure Container Registry (ACR).
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

LOCAL_IMAGE="${IMAGE_NAME:-codice-fiscale-web}:${IMAGE_TAG:-latest}"
STACK_NAME="${PULUMI_STACK:-dev}"

# Retrieve login server from argument or Pulumi output
ACR_LOGIN_SERVER="${1:-${ACR_LOGIN_SERVER:-}}"

if [[ -z "${ACR_LOGIN_SERVER}" ]]; then
  if command -v pulumi >/dev/null 2>&1; then
    echo "Querying Pulumi stack output for registryLoginServer..."
    ACR_LOGIN_SERVER="$(pulumi stack output registryLoginServer -s "${STACK_NAME}" 2>/dev/null || true)"
  fi
fi

if [[ -z "${ACR_LOGIN_SERVER}" ]]; then
  echo "Error: ACR_LOGIN_SERVER not provided and could not be discovered from Pulumi stack." >&2
  echo "Usage: $0 <acr-login-server.azurecr.io>" >&2
  echo "Example: $0 elixirfisc123acr.azurecr.io" >&2
  exit 1
fi

REMOTE_IMAGE="${ACR_LOGIN_SERVER}/${LOCAL_IMAGE}"

echo "================================================================="
echo "Pushing image to Azure Container Registry"
echo "Local image:  ${LOCAL_IMAGE}"
echo "Remote image: ${REMOTE_IMAGE}"
echo "================================================================="

# Authenticate with ACR
echo "Authenticating with ACR (${ACR_LOGIN_SERVER})..."
if command -v az >/dev/null 2>&1; then
  REGISTRY_NAME="${ACR_LOGIN_SERVER%%.*}"
  echo "Using Azure CLI to authenticate with ACR '${REGISTRY_NAME}'..."
  az acr login --name "${REGISTRY_NAME}"
else
  echo "Please authenticate using podman login ${ACR_LOGIN_SERVER}"
fi

# Tag the image
echo "Tagging ${LOCAL_IMAGE} as ${REMOTE_IMAGE}..."
podman tag "${LOCAL_IMAGE}" "${REMOTE_IMAGE}"

# Push the image
echo "Pushing ${REMOTE_IMAGE}..."
podman push "${REMOTE_IMAGE}"

echo ""
echo "Image successfully pushed to ${REMOTE_IMAGE}"
