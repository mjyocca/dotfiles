#!/usr/bin/env bash
# Export a named docker volume to a .tar.gz archive in the current directory
# Usage: export_volume.sh <volume_name> [--context <docker_context>]

set -euo pipefail

_usage() {
  echo "Usage: $0 <volume_name> [--context <docker_context>]"
  echo ""
  echo "Arguments:"
  echo "  volume_name              Name of the docker volume to export"
  echo "  --context <context>      Docker context to use (default: active context)"
  echo ""
  echo "Examples:"
  echo "  $0 my_volume"
  echo "  $0 my_volume --context colima"
  echo "  $0 my_volume --context colima-arm"
}

VOLUME_NAME=""
DOCKER_CONTEXT=""

# Parse arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    --context)
      DOCKER_CONTEXT="${2:?--context requires a value}"
      shift 2
      ;;
    --help|-h)
      _usage
      exit 0
      ;;
    -*)
      echo "Unknown option: $1" >&2
      _usage >&2
      exit 1
      ;;
    *)
      if [[ -z "$VOLUME_NAME" ]]; then
        VOLUME_NAME="$1"
      else
        echo "Unexpected argument: $1" >&2
        _usage >&2
        exit 1
      fi
      shift
      ;;
  esac
done

if [[ -z "$VOLUME_NAME" ]]; then
  echo "Error: volume_name is required" >&2
  _usage >&2
  exit 1
fi

# Build docker command prefix
if [[ -n "$DOCKER_CONTEXT" ]]; then
  DOCKER="docker --context ${DOCKER_CONTEXT}"
else
  DOCKER="docker"
fi

OUTPUT_FILE="$(pwd)/${VOLUME_NAME}.tar.gz"

echo "Exporting volume '${VOLUME_NAME}' to ${OUTPUT_FILE}..."
${DOCKER} run --rm \
  -v "${VOLUME_NAME}:/data" \
  -v "$(pwd):/backup" \
  alpine tar czf "/backup/${VOLUME_NAME}.tar.gz" -C /data .

echo "DONE: ${OUTPUT_FILE}"
