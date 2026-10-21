#!/usr/bin/env bash
set -euo pipefail

# -----------------------------------------------------------------------------
# destroy.sh
# Destroys all Azure resources provisioned by Pulumi.
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STACK_NAME="${1:-${PULUMI_STACK:-dev}}"

cd "${SCRIPT_DIR}"

echo "================================================================="
echo " Destroying Azure Infrastructure (Stack: ${STACK_NAME})"
echo "================================================================="

if ! command -v pulumi >/dev/null 2>&1; then
  echo "Error: pulumi CLI not found." >&2
  exit 1
fi

pulumi destroy --yes --stack "${STACK_NAME}"

echo ""
echo "Infrastructure destroyed successfully."
