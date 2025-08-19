#!/bin/bash
set -euo pipefail
# Standard config for your drills
RESOURCE_GROUP="StorageRG"
LOCATION="eastus2"
#Unique name each run (Azure storage account names must be globally unique)
STORAGE_NAME="mendozastoragejoe$RANDOM"
CONTAINER_NAME="mycontainer"
echo "[1/5] Creating storage account..."
az storage account create \
--name "$STORAGE_NAME" \
--resource-group "$RESOURCE_GROUP" \
--location "$LOCATION" \
--sku  Standard_LRS
echo "[2/5] Creating container (using your login for auth)..."
az storage container create \
--account-name "$STORAGE_NAME" \
--name "$CONTAINER_NAME" \
--auth-mode login
echo "[3/5] Creating and uploading test file..."
echo "Hello Cloud Day 6" > test.txt
az storage blob upload \
--account-name "$STORAGE_NAME" \
--container-name "$CONTAINER_NAME" \
--name test.txt \
--file ./test.txt \
--auth-mode login
echo "[4/5] Verifying blobs..."
az storage blob list \
--account-name "$STORAGE_NAME" \
--container-name "$CONTAINER_NAME" \
--output table \
--auth-mode login
echo "[5/5] Done!"
echo "Storage account: $STORAGE_NAME"
echo "Container: $CONTAINER_NAME"
