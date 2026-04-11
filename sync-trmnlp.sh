#!/bin/bash
# Sync plugin templates to the trmnlp dev server
# Usage: ./sync-trmnlp.sh

REMOTE="jpoh@192.168.2.168"
REMOTE_DIR="/home/jpoh/trmnlp/telescopius/src"
LOCAL_DIR="./private_plugin_227426"

FILES=(
  "settings.yml"
  "full.liquid"
  "half_horizontal.liquid"
  "half_vertical.liquid"
  "quadrant.liquid"
)

for f in "${FILES[@]}"; do
  if [ -f "$LOCAL_DIR/$f" ]; then
    scp "$LOCAL_DIR/$f" "$REMOTE:$REMOTE_DIR/$f" && echo "  ✓ $f"
  fi
done

echo "Done — http://192.168.2.168:4567"
