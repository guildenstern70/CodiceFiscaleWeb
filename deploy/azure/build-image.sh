#!/usr/bin/env bash
set -euo pipefail

# -----------------------------------------------------------------------------
# build-image.sh
# Builds the Codice Fiscale Web container image using Podman.
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

IMAGE_NAME="${IMAGE_NAME:-codice-fiscale-web}"
IMAGE_TAG="${IMAGE_TAG:-latest}"
PHX_HOST="${PHX_HOST:-localhost}"
TARGET_PLATFORM="${TARGET_PLATFORM:-linux/amd64}"

echo "================================================================="
echo "Building Podman Image: ${IMAGE_NAME}:${IMAGE_TAG}"
echo "Platform:              ${TARGET_PLATFORM}"
echo "PHX_HOST:              ${PHX_HOST}"
echo "Project Root:          ${PROJECT_ROOT}"
echo "================================================================="

# Check podman command
if ! command -v podman >/dev/null 2>&1; then
  echo "Error: podman command not found. Please install Podman." >&2
  exit 1
fi

# On macOS, check if podman machine is running
if [[ "$(uname)" == "Darwin" ]]; then
  if ! podman machine info >/dev/null 2>&1; then
    echo "Notice: Podman machine is not running. Attempting to start it..."
    podman machine start || {
      echo "Error: Failed to start podman machine. Please run 'podman machine init' or 'podman machine start'." >&2
      exit 1
    }
  fi
fi

# Build image
podman build \
  --platform "${TARGET_PLATFORM}" \
  --build-arg PHX_HOST="${PHX_HOST}" \
  -t "${IMAGE_NAME}:${IMAGE_TAG}" \
  -f "${PROJECT_ROOT}/Dockerfile" \
  "${PROJECT_ROOT}"

echo ""
echo "Successfully built Podman image: ${IMAGE_NAME}:${IMAGE_TAG}"
echo "To inspect: podman images | grep ${IMAGE_NAME}"
