#!/bin/bash
set -e

echo "[INFO] Starting Day 8 GitHub push..."

# Define paths
REPO_PATH="$HOME/cloud-journey"
DAY_FOLDER="$REPO_PATH/day8"

# Make sure repo exists
if [ ! -d "$REPO_PATH" ]; then
  echo "[ERROR] Repo not found at $REPO_PATH"
  exit 1
fi

# Make sure day8 folder exists
mkdir -p "$DAY_FOLDER"

# Move day8.sh into repo
if [ -f "$HOME/day8.sh" ]; then
  mv "$HOME/day8.sh" "$DAY_FOLDER/"
  echo "[INFO] day8.sh moved into $DAY_FOLDER/"
elif [ -f "$REPO_PATH/day8.sh" ]; then
  mv "$REPO_PATH/day8.sh" "$DAY_FOLDER/"
  echo "[INFO] day8.sh moved from repo root into $DAY_FOLDER/"
else
  echo "[ERROR] day8.sh not found — place it in $HOME or repo root first."
  exit 1
fi

# Git commit and push
cd "$REPO_PATH"
git add .
git commit -m "Add Day 8 script"
git push origin main

echo "[INFO] Day 8 push complete!"
