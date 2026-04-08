#!/bin/bash
set -e

VOLUME_NAME="${1:?Usage: $0 <volume_name>}"
OUTPUT_FILE="$(pwd)/${VOLUME_NAME}.tar.gz"

echo "Exporting volume '$VOLUME_NAME' to $OUTPUT_FILE..."
docker run --rm \
  -v "${VOLUME_NAME}:/data" \
  -v "$(pwd):/backup" \
  alpine tar czf "/backup/${VOLUME_NAME}.tar.gz" -C /data .

echo "DONE: $OUTPUT_FILE"
