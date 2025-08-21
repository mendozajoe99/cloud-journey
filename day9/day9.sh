#!/bin/bash
set -euo pipefail

# Variables
RESOURCE_GROUP="MyNewRG"
LOCATION="eastus2"
STORAGE_ACCOUNT="mendozastg$RANDOM"
CONTAINER="mycontainer"
FILENAME="day9_test.txt"

echo "Starting Day 9 core drill..."

# 1. Make sure RG exists
az group create --name $RESOURCE_GROUP --location $LOCATION

# 2. Create storage account
az storage account create \
  --name $STORAGE_ACCOUNT \
  --resource-group $RESOURCE_GROUP \
  --location $LOCATION \
  --sku Standard_LRS

# 3. Get storage key
ACCOUNT_KEY=$(az storage account keys list \
  --resource-group $RESOURCE_GROUP \
  --account-name $STORAGE_ACCOUNT \
  --query "[0].value" -o tsv)

# 4. Create blob container
az storage container create \
  --name $CONTAINER \
  --account-name $STORAGE_ACCOUNT \
  --account-key $ACCOUNT_KEY

# 5. Make a test file
echo "Hello from Day 9" > $FILENAME

# 6. Upload file
az storage blob upload \
  --container-name $CONTAINER \
  --account-name $STORAGE_ACCOUNT \
  --account-key $ACCOUNT_KEY \
  --file $FILENAME \
  --name $FILENAME

# 7. Verify blob exists
az storage blob list \
  --container-name $CONTAINER \
  --account-name $STORAGE_ACCOUNT \
  --account-key $ACCOUNT_KEY \
  --output table

# 8. Cleanup
az group delete --name $RESOURCE_GROUP --yes --no-wait

echo "Day 9 core drill complete. All resources cleaned up."
