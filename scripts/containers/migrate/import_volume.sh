#!/bin/bash
set -euo pipefail

VOLUME_NAME="${1:?Usage: $0 <volume_name> [context] [archive_dir] [target_volume_name]}"
CONTEXT="${2:-$(docker context show)}"
ARCHIVE_DIR="${3:-$(pwd)}"
TARGET_VOLUME_NAME="${4:-$VOLUME_NAME}"
ARCHIVE="${ARCHIVE_DIR}/${VOLUME_NAME}.tar.gz"

if [[ ! -f "$ARCHIVE" ]]; then
  echo "Error: $ARCHIVE not found"
  exit 1
fi

echo "Creating volume '$TARGET_VOLUME_NAME' in context '$CONTEXT'..."
docker --context "$CONTEXT" volume create "${TARGET_VOLUME_NAME}" >/dev/null

echo "Importing data from $ARCHIVE into '$TARGET_VOLUME_NAME'..."
docker --context "$CONTEXT" run --rm \
  -v "${TARGET_VOLUME_NAME}:/data" \
  -v "${ARCHIVE_DIR}:/backup" \
  alpine tar xzf "/backup/${VOLUME_NAME}.tar.gz" -C /data

echo "Done."
