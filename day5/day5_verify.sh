#!/usr/bin/env bash
set -euo pipefail

RG_NAME="StorageRG"
CONTAINER="mycontainer"

if [ ! -f last_storage_name.txt ]; then
  echo "last_storage_name.txt not found. Run day5_drill.sh first." >&2
  exit 1
fi

STORAGE_NAME="$(cat last_storage_name.txt)"
echo "Using storage account: $STORAGE_NAME"

STORAGE_KEY="$(az storage account keys list \
  --resource-group "$RG_NAME" \
  --account-name "$STORAGE_NAME" \
  --query "[0].value" -o tsv)"

echo "=== Blobs in $CONTAINER for $STORAGE_NAME ===" | tee verify_output.txt
az storage blob list \
  --account-name "$STORAGE_NAME" \
  --account-key "$STORAGE_KEY" \
  --container-name "$CONTAINER" -o table | tee -a verify_output.txt

# Try to find the newest hello_*.txt and download it for proof (if present)
LATEST_HELLO="$(az storage blob list \
  --account-name "$STORAGE_NAME" \
  --account-key "$STORAGE_KEY" \
  --container-name "$CONTAINER" \
  --query "reverse(sort_by([?starts_with(name, 'hello_')], &properties.lastModified))[0].name" -o tsv || true)"

if [ -n "${LATEST_HELLO:-}" ] && [ "$LATEST_HELLO" != "null" ]; then
  echo "Newest blob: $LATEST_HELLO" | tee -a verify_output.txt
  az storage blob download \
    --account-name "$STORAGE_NAME" \
    --account-key "$STORAGE_KEY" \
    --container-name "$CONTAINER" \
    --name "$LATEST_HELLO" \
    --file "verify_download.txt" \
    --overwrite true >/dev/null
  echo "=== Downloaded file contents ===" | tee -a verify_output.txt
  cat verify_download.txt | tee -a verify_output.txt
else
  echo "No hello_*.txt blobs found to download." | tee -a verify_output.txt
fi

# GitHub log
echo "Day 5 verify run: $(date) for $STORAGE_NAME" >> notes.txt
git add day5_verify.sh verify_output.txt notes.txt
git commit -m "Day 5 verify: listed & checked blobs for $STORAGE_NAME" || true
git push
