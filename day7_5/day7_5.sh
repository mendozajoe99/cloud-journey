#!/bin/bash
set -euo pipefail
# Day 7.5: Storage best practices end to end
RESOURCE_GROUP="StorageRG"
LOCATION="eastus2"
# short valid base + timestamp suffix, capped to 24
BASE="mendozastg"
SUFFIX="$(date +%y%m%d%H%M%S)"
STORAGE_ACCOUNT="${BASE}${SUFFIX}"
STORAGE_ACCOUNT="${STORAGE_ACCOUNT:0:24}"
echo "Using storage account: $STORAGE_ACCOUNT"
echo "$STORAGE_ACCOUNT" > .created_storage_account.txt
# ensure RG
az group create --name "$RESOURCE_GROUP" --location "$LOCATION" >/dev/null
# preflight name check
az storage account check-name --name "$STORAGE_ACCOUNT" -o table
# create account
az storage account create \
--name "$STORAGE_ACCOUNT" \
--resource-group "$RESOURCE_GROUP" \
--location "$LOCATION" \
--sku Standard_LRS \
--kind StorageV2
# enable blob versioning + soft delete
az storage account blob-service-properties update \
  --account-name "$STORAGE_ACCOUNT" \
  --resource-group "$RESOURCE_GROUP" \
  --enable-versioning true \
  --enable-delete-retention true \
  --delete-retention-days 7

# connection stirng
CONN_STRING="$(az storage account show-connection-string \
--name "$STORAGE_ACCOUNT" \
--resource-group "$RESOURCE_GROUP" \
--query connectionString -o tsv)"
# create containers
for c in dev test prod temp; do
az storage container create \
--name "$c" \
--file sample.txt \
--name sample.txt \
--connection-string "$CONN_STRING" \
--overwrite true
done
# put a timestamped temp file into temp (so lifecycle can target it)
STAMP="$(date +%Y%m%d%H%M%S)"
echo "temporary build artifact $STAMP" > temp_$STAMP.txt
az storage blob upload \
--container-name temp \
--file "temp_$STAMP.txt" \
--name "temp_$STAMP.txt" \
--connection-string "$CONN_STRING" \
--overwrite trie
# add a lifecycle rule:
# delete blobs in the 'temp' container older than 7 days
cat > lifecycle.json << 'JSON'
{
"rules": [
{
"name": "delete-old-temp",
"enabled": true,
"type": "Lifecycle",
"definition": {
"filters": {
"blobTypes": [ "blockBlob" ],
"prefixMatch": [ "temp/" ]
},
"actions": {
"baseBlob": {
"delete": { "daysAfterModificationGreaterThan": 7 }
}
}
}
}
]
}
JSON
# Set the management policy
az storage account management-policy
az storage account management-policy create \
--account-name "$STORAGE_ACCOUNT" \
--resource-group "$RESOURCE_GROUP" \
--policy "@lifecycle.json
# generate a read-only SAS for the 'dev' container, valid 30 minutes
EXPIRY="$(date -u -d '+30 minutes' +%Y-%m-%dT%H:%MZ)"
SAS_TOKEN=$(az storage container generate-sas \
--name dev \
--connection-string "$CONN_STRING" \
--permissions rl \
--expiry "$EXPIRY" -o tsv)"
# build a test /URL
ACCOUNT_URL="https://${STORAGE_ACCOUNT}.blob.core.windows.net"
READ_URL="${ACCOUNT_URL}/dev/sample.txt?${SAS_TOKEN}"
echo "Read-only dev sample URL (valid 30 min):"
echo "$READ_URL" | tee dev_sample_sas_url.txt
# verify listings
for c in dev test prod temp; do
echo "=== $c ==="
az storage blob list \
--container-name "$c" \
--connection-string "$CONN_STRING" \
-o table
done
echo "Done. Storage account: $STORAGE_ACCOUNT"
