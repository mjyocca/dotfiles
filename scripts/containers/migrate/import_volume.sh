#!/bin/bash
set -e

VOLUME_NAME="${1:?Usage: $0 <volume_name>}"
ARCHIVE="$(pwd)/${VOLUME_NAME}.tar.gz"

if [[ ! -f "$ARCHIVE" ]]; then
  echo "Error: $ARCHIVE not found"
  exit 1
fi

echo "Creating volume '$VOLUME_NAME'..."
docker volume create "${VOLUME_NAME}"

echo "Importing data from $ARCHIVE..."
docker run --rm \
  -v "${VOLUME_NAME}:/data" \
  -v "$(pwd):/backup" \
  alpine tar xzf "/backup/${VOLUME_NAME}.tar.gz" -C /data

echo "Done."
