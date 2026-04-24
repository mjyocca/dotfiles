#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  transfer_volume.sh <volume_name> <source_context> <target_context> [archive_dir] [target_volume_name]

Examples:
  transfer_volume.sh postgres_data colima colima-exp
  transfer_volume.sh redis_data colima-dev colima-test ./backups redis_data_test
EOF
}

if [[ $# -lt 3 ]]; then
  usage
  exit 1
fi

VOLUME_NAME="$1"
SOURCE_CONTEXT="$2"
TARGET_CONTEXT="$3"
ARCHIVE_DIR="${4:-$(pwd)}"
TARGET_VOLUME_NAME="${5:-$VOLUME_NAME}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

"$SCRIPT_DIR/export_volume.sh" "$VOLUME_NAME" "$SOURCE_CONTEXT" "$ARCHIVE_DIR"
"$SCRIPT_DIR/import_volume.sh" "$VOLUME_NAME" "$TARGET_CONTEXT" "$ARCHIVE_DIR" "$TARGET_VOLUME_NAME"

echo "Transfer complete: ${VOLUME_NAME} (${SOURCE_CONTEXT} -> ${TARGET_VOLUME_NAME} on ${TARGET_CONTEXT})"
