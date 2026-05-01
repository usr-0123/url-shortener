#!/usr/bin/env bash
set -euo pipefail

ENV="${1:-dev}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INFRA_DIR="$SCRIPT_DIR/../infrastructure/environments/$ENV"

echo "This will DESTROY all infrastructure in the $ENV environment."
echo "   Resource group: rg-snipurl-$ENV"
read -r -p "Type 'destroy' to confirm: " confirm

if [[ "$confirm" != "destroy" ]]; then
  echo "Aborted."
  exit 1
fi

cd "$INFRA_DIR"
terraform destroy -auto-approve

echo "✅  Dev environment destroyed. Monthly cost: $0."
