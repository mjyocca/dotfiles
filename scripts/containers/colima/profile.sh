#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  profile.sh start <profile> [colima start args...]
  profile.sh switch <profile> [--skip-socket-link]
  profile.sh stop <profile>
  profile.sh delete <profile>
  profile.sh ls
  profile.sh socket <profile>

Examples:
  profile.sh start exp-vz --cpu 2 --memory 4
  profile.sh switch exp-vz
  profile.sh switch default --skip-socket-link
EOF
}

context_for_profile() {
  local profile="$1"
  if [[ "$profile" == "default" ]]; then
    printf 'colima'
  else
    printf 'colima-%s' "$profile"
  fi
}

socket_for_profile() {
  local profile="$1"
  printf '%s/.colima/%s/docker.sock' "$HOME" "$profile"
}

ensure_profile_arg() {
  if [[ $# -lt 1 ]]; then
    usage
    exit 1
  fi
}

link_socket() {
  local socket="$1"
  if [[ ! -S "$socket" ]]; then
    printf 'Socket not found: %s\n' "$socket" >&2
    exit 1
  fi

  sudo ln -sf "$socket" /var/run/docker.sock
}

switch_context() {
  local profile="$1"
  local skip_socket_link="${2:-false}"
  local context
  local socket

  context="$(context_for_profile "$profile")"
  socket="$(socket_for_profile "$profile")"

  docker context use "$context" >/dev/null
  printf 'Switched Docker context to %s\n' "$context"

  if [[ "$skip_socket_link" == "false" ]]; then
    link_socket "$socket"
    printf 'Linked /var/run/docker.sock -> %s\n' "$socket"
  fi
}

command="${1:-}"
if [[ -z "$command" ]]; then
  usage
  exit 1
fi
shift

case "$command" in
  start)
    ensure_profile_arg "$@"
    profile="$1"
    shift

    colima start --profile "$profile" "$@"
    switch_context "$profile" false
    ;;
  switch)
    ensure_profile_arg "$@"
    profile="$1"
    shift

    skip="false"
    if [[ "${1:-}" == "--skip-socket-link" ]]; then
      skip="true"
    fi

    switch_context "$profile" "$skip"
    ;;
  stop)
    ensure_profile_arg "$@"
    profile="$1"
    colima stop --profile "$profile"
    ;;
  delete)
    ensure_profile_arg "$@"
    profile="$1"
    colima delete --profile "$profile"
    ;;
  ls)
    colima ls
    ;;
  socket)
    ensure_profile_arg "$@"
    profile="$1"
    socket_for_profile "$profile"
    ;;
  *)
    usage
    exit 1
    ;;
esac
