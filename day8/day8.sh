#!/bin/bash
set -Eeuo pipefail
trap 'echo "Error on line $LINENO"; exit 1' ERR

# Config
RESOURCE_GROUP="StorageRG"
LOCATION="eastus2"
BASE="mendozastgweb"
SUFFIX="$(date +%y%m%d%H%M%S)"
STORAGE_ACCOUNT="${BASE}${SUFFIX}"
STORAGE_ACCOUNT="${STORAGE_ACCOUNT:0:24}"

echo "Using storage account: $STORAGE_ACCOUNT" | tee .day8_storage_account.txt

# Create account (idempotent RG)
az group create --name "$RESOURCE_GROUP" --location "$LOCATION" 1>/dev/null
az storage account create \
  --name "$STORAGE_ACCOUNT" \
  --resource-group "$RESOURCE_GROUP" \
  --location "$LOCATION" \
  --sku Standard_LRS \
  --kind StorageV2 \
  1>/dev/null

# Get an account key (works regardless of RBAC data-plane roles)
ACCOUNT_KEY="$(az storage account keys list \
  --account-name "$STORAGE_ACCOUNT" \
  --resource-group "$RESOURCE_GROUP" \
  --query "[0].value" -o tsv)"

# Enable Static Website
az storage blob service-properties update \
  --account-name "$STORAGE_ACCOUNT" \
  --account-key "$ACCOUNT_KEY" \
  --static-website \
  --index-document index.html \
  --404-document 404.html \
  1>/dev/null

# Site files (ASCII only)
cat > index.html <<'HTML'
<!doctype html>
<meta charset="utf-8">
<title>Day 8 - Static Site</title>
<meta name="viewport" content="width=device-width, initial-scale=1">
<h1>It works!</h1>
<p>This page is served from Azure Blob Static Website.</p>
HTML

cat > 404.html <<'HTML'
<!doctype html>
<meta charset="utf-8">
<title>404</title>
<meta name="viewport" content="width=device-width, initial-scale=1">
<h1>404 - Page not found</h1>
<p>Try <a href="/">home</a>.</p>
HTML

# Upload to $web
az storage blob upload \
  --account-name "$STORAGE_ACCOUNT" \
  --account-key "$ACCOUNT_KEY" \
  --container-name '$web' \
  --name index.html \
  --file index.html \
  --overwrite true \
  1>/dev/null

az storage blob upload \
  --account-name "$STORAGE_ACCOUNT" \
  --account-key "$ACCOUNT_KEY" \
  --container-name '$web' \
  --name 404.html \
  --file 404.html \
  --overwrite true \
  1>/dev/null

# Get public URL
WEB_ENDPOINT="$(az storage account show \
  --name "$STORAGE_ACCOUNT" \
  --resource-group "$RESOURCE_GROUP" \
  --query 'primaryEndpoints.web' -o tsv)"

echo "Static website URL:"
echo "$WEB_ENDPOINT" | tee day8_site_url.txt

# Quick check
curl -I "$WEB_ENDPOINT" 2>/dev/null | head -n 1 || true

echo "Done. Storage account: $STORAGE_ACCOUNT"

