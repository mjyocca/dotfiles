#!/bin/bash
set -euo pipefail

VOLUME_NAME="${1:?Usage: $0 <volume_name> [context] [output_dir]}"
CONTEXT="${2:-$(docker context show)}"
OUTPUT_DIR="${3:-$(pwd)}"
OUTPUT_FILE="${OUTPUT_DIR}/${VOLUME_NAME}.tar.gz"

mkdir -p "$OUTPUT_DIR"

echo "Exporting volume '$VOLUME_NAME' from context '$CONTEXT' to $OUTPUT_FILE..."
docker --context "$CONTEXT" run --rm \
  -v "${VOLUME_NAME}:/data" \
  -v "${OUTPUT_DIR}:/backup" \
  alpine tar czf "/backup/${VOLUME_NAME}.tar.gz" -C /data .

echo "DONE: $OUTPUT_FILE"
