#!/usr/bin/env bash
set -euo pipefail

# ---------------------------
# Config (your saved defaults)
# ---------------------------
GIT_REPO_PATH="$HOME/cloud-journey"
AZ_LOCATION="eastus2"
RG_NAME="StorageRG"
CONTAINER="mycontainer"
ACCOUNT_PREFIX="mendozastoragejoe"   # script appends a unique suffix
CLEANUP="${CLEANUP:-false}"           # set CLEANUP=true to auto delete Azure stuff at the end

# ---------------------------
# GitHub setup (idempotent)
# ---------------------------
mkdir -p "$GIT_REPO_PATH"
cd "$GIT_REPO_PATH"
[ -d .git ] || git init
git branch -M main || true

if ! git remote get-url origin >/dev/null 2>&1; then
  git remote add origin git@github.com:mendozajoe99/cloud-journey.git
fi

# Day folder + start log
mkdir -p day5
cd day5
echo "Day 5 start: $(date)" >> notes.txt
git add notes.txt
git commit -m "Day 5 start log" || true
git push -u origin main || git pull --rebase origin main && git push

# ---------------------------
# Azure: ensure RG exists
# ---------------------------
az group create --name "$RG_NAME" --location "$AZ_LOCATION" >/dev/null

# ---------------------------
# Azure: create unique storage account
#   (3–24 chars, lowercase letters/numbers)
# ---------------------------
SUFFIX="$(date +%s | tail -c 5)"
STORAGE_NAME="${ACCOUNT_PREFIX}${SUFFIX}"
echo "Creating storage account: $STORAGE_NAME"

az storage account create \
  --name "$STORAGE_NAME" \
  --resource-group "$RG_NAME" \
  --location "$AZ_LOCATION" \
  --sku Standard_LRS >/dev/null

# ---------------------------
# Get key & ensure container
# ---------------------------
STORAGE_KEY="$(az storage account keys list \
  --resource-group "$RG_NAME" \
  --account-name "$STORAGE_NAME" \
  --query "[0].value" -o tsv)"

az storage container create \
  --name "$CONTAINER" \
  --account-name "$STORAGE_NAME" \
  --account-key "$STORAGE_KEY" >/dev/null

# ---------------------------
# Upload → List → Download → Verify
# ---------------------------
RUN_ID="$(date +%s)"
SRC_FILE="hello_${RUN_ID}.txt"
DST_FILE="downloaded_${RUN_ID}.txt"

echo "Hello from Mendoza Day 5 @ $(date)" > "$SRC_FILE"

# Upload (single line to avoid CLI parsing issues)
az storage blob upload \
  --account-name "$STORAGE_NAME" \
  --account-key "$STORAGE_KEY" \
  --container-name "$CONTAINER" \
  --file "$SRC_FILE" \
  --name "$SRC_FILE" \
  --overwrite true >/dev/null

# List
echo "=== Blobs in $CONTAINER for $STORAGE_NAME ==="
az storage blob list \
  --account-name "$STORAGE_NAME" \
  --account-key "$STORAGE_KEY" \
  --container-name "$CONTAINER" -o table

# Download
az storage blob download \
  --account-name "$STORAGE_NAME" \
  --account-key "$STORAGE_KEY" \
  --container-name "$CONTAINER" \
  --name "$SRC_FILE" \
  --file "$DST_FILE" \
  --overwrite true >/dev/null

# Verify contents match
if diff -q "$SRC_FILE" "$DST_FILE" >/dev/null; then
  echo "Verification: OK. Downloaded file matches uploaded file."
else
  echo "Verification: MISMATCH. Files differ." >&2
  exit 1
fi

# ---------------------------
# Save quick reference locally
# ---------------------------
echo "$STORAGE_NAME" > last_storage_name.txt

# ---------------------------
# Log proof to GitHub (includes the script)
# ---------------------------
git add "$SRC_FILE" "$DST_FILE" notes.txt last_storage_name.txt day5_drill.sh
git commit -m "Day 5 drill script + run ($STORAGE_NAME)" || true
git push

# ---------------------------
# Optional cleanup
# ---------------------------
if [ "$CLEANUP" = "true" ]; then
  echo "Cleanup enabled: deleting resource group $RG_NAME"
  az group delete --name "$RG_NAME" --yes --no-wait
else
  echo "Cleanup disabled. Resources kept:"
  echo "  RG: $RG_NAME"
  echo "  Storage account: $STORAGE_NAME"
  echo "  Container: $CONTAINER"
fi

echo "Done. Storage account used: $STORAGE_NAME"
