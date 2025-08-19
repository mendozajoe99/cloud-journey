#!/bin/bash
set -euo pipefail

# Day 8: Deploy a static website to Azure Blob Storage

# ---- Config (all defined here; don't rename later) ----
RESOURCE_GROUP="StorageRG"
LOCATION="eastus2"

# Storage account: <=24 chars, lowercase+digits
BASE="mendozastgweb"
SUFFIX="$(date +%y%m%d%H%M%S)"
STORAGE_ACCOUNT="${BASE}${SUFFIX}"
STORAGE_ACCOUNT="${STORAGE_ACCOUNT:0:24}"

echo "Using storage account: $STORAGE_ACCOUNT" | tee .day8_storage_account.txt

# ---- Sanity checks ----
command -v az >/dev/null || { echo "Azure CLI not found"; exit 1; }
az account show >/dev/null || { echo "Run: az login --use-device-code"; exit 1; }

# ---- Ensure RG exists ----
az group create --name "$RESOURCE_GROUP" --location "$LOCATION" 1>/dev/null

# ---- Create storage account ----
az storage account create \
  --name "$STORAGE_ACCOUNT" \
  --resource-group "$RESOURCE_GROUP" \
  --location "$LOCATION" \
  --sku Standard_LRS \
  --kind StorageV2 \
  1>/dev/null

# ---- Enable Static Website ($web container) ----
az storage blob service-properties update \
  --account-name "$STORAGE_ACCOUNT" \
  --auth-mode login \
  --static-website \
  --index-document index.html \
  --404-document 404.html \
  1>/dev/null

# ---- Site files (ASCII only) ----
cat > index.html <<'HTML'
<!doctype html>
<html lang="en">
<meta charset="utf-8">
<title>Day 8 - DoseofMendoza Static Site</title>
<meta name="viewport" content="width=device-width, initial-scale=1">
<style>
  body { font-family: Arial, Helvetica, sans-serif; margin: 40px; max-width: 720px; }
  code { background: #f3f3f3; padding: 2px 6px; border-radius: 6px; }
</style>
<h1>It works!</h1>
<p>This site is hosted on Azure Blob Static Website.</p>
<p>Uploaded by <code>day8.sh</code>.</p>
HTML

cat > 404.html <<'HTML'
<!doctype html>
<html lang="en">
<meta charset="utf-8">
<title>Not Found</title>
<meta name="viewport" content="width=device-width, initial-scale=1">
<style>
  body { font-family: Arial, Helvetica, sans-serif; margin: 40px; max-width: 720px; color: #a00; }
</style>
<h1>404 - Page not found</h1>
<p>The file you are looking for does not exist. Try <a href="/">home</a>.</p>
HTML

# ---- Upload files to $web ----
az storage blob upload \
  --account-name "$STORAGE_ACCOUNT" \
  --auth-mode login \
  --container-name '$web' \
  --name index.html \
  --file index.html \
  --overwrite true \
  1>/dev/null

az storage blob upload \
  --account-name "$STORAGE_ACCOUNT" \
  --auth-mode login \
  --container-name '$web' \
  --name 404.html \
  --file 404.html \
  --overwrite true \
  1>/dev/null

# ---- Get and print site URL ----
WEB_ENDPOINT="$(az storage account show \
  --name "$STORAGE_ACCOUNT" \
  --resource-group "$RESOURCE_GROUP" \
  --query 'primaryEndpoints.web' -o tsv)"

echo "Static website URL:"
echo "$WEB_ENDPOINT" | tee day8_site_url.txt

# ---- Quick verification ----
echo "Fetching index.html header (expect HTTP/1.1 200 OK):"
curl -I "${WEB_ENDPOINT}" 2>/dev/null | head -n 1 || true

echo "Done. Storage account: $STORAGE_ACCOUNT"

