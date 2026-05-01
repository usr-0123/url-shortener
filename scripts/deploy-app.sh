#!/usr/bin/env bash
set -euo pipefail

ENV="${1:-dev}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Fetch values from Terraform outputs
RESOURCE_GROUP=$(terraform -chdir="$SCRIPT_DIR/../infrastructure/environments/$ENV" output -raw resource_group_name)
ACR_NAME=$(az acr list --resource-group "$RESOURCE_GROUP" --query "[0].name" -o tsv)
ACR_SERVER=$(az acr show --name "$ACR_NAME" --query loginServer -o tsv)
IMAGE_TAG=$(git rev-parse --short HEAD)

echo "→ Building image: $ACR_SERVER/snipurl:$IMAGE_TAG"
az acr login --name "$ACR_NAME"
docker build -t "$ACR_SERVER/snipurl:$IMAGE_TAG" "$SCRIPT_DIR/../app"
docker push "$ACR_SERVER/snipurl:$IMAGE_TAG"

echo "→ Updating Container App..."
az containerapp update \
  --name "ca-snipurl-$ENV" \
  --resource-group "$RESOURCE_GROUP" \
  --image "$ACR_SERVER/snipurl:$IMAGE_TAG"

echo "Deployed snipurl:$IMAGE_TAG to $ENV"
