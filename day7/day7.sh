#!/bin/bash
set -euo pipefail

# Day 7 Drill: Multi-container automation

# Vars
RESOURCE_GROUP="StorageRG"
LOCATION="eastus2"

# Make a short, valid storage account name (<=24 chars, lowercase/numbers)
BASE="mendozastg"                               # 10 chars
SUFFIX="$(date +%y%m%d%H%M%S)"                  # 12 digits
STORAGE_ACCOUNT="${BASE}${SUFFIX}"              # 22 chars total

# Extra safety: truncate to 24 just in case you change BASE
STORAGE_ACCOUNT="${STORAGE_ACCOUNT:0:24}"

echo "Using storage account: $STORAGE_ACCOUNT"

# Ensure RG exists
az group create --name "$RESOURCE_GROUP" --location "$LOCATION" >/dev/null

# Preflight name check (Azure validates availability and pattern)
az storage account check-name --name "$STORAGE_ACCOUNT" -o table

# Sample file
echo "Day 7 storage test file" > sample.txt

# Create the storage account
az storage account create \
  --name "$STORAGE_ACCOUNT" \
  --resource-group "$RESOURCE_GROUP" \
  --location "$LOCATION" \
  --sku Standard_LRS \
  --kind StorageV2

# Get connection string
CONN_STRING="$(az storage account show-connection-string \
  --name "$STORAGE_ACCOUNT" \
  --resource-group "$RESOURCE_GROUP" \
  --query connectionString -o tsv)"

# Create 3 containers and upload the file to each
for c in container1 container2 container3; do
  az storage container create \
    --name "$c" \
    --connection-string "$CONN_STRING" \
    --public-access off

  az storage blob upload \
    --container-name "$c" \
    --file sample.txt \
    --name sample.txt \
    --connection-string "$CONN_STRING" \
    --overwrite true
done

# Verify: list blobs in each container
for c in container1 container2 container3; do
  echo "=== $c ==="
  az storage blob list \
    --container-name "$c" \
    --connection-string "$CONN_STRING" \
    -o table
done

