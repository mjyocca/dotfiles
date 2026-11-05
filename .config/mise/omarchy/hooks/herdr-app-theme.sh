#!/usr/bin/env bash
# Publish Omarchy's rendered palette; Herdr reloads the selected theme live.
# Omarchy invokes hooks with Bash and passes the theme slug (unused here).
set -euo pipefail

source_path="$HOME/.local/state/omarchy/current/theme/herdr-app.json"
app_home="${HERDR_APP_HOME:-${XDG_CONFIG_HOME:-$HOME/.config}/herdr-app}"
[[ -d "$app_home" ]] || exit 0

# Use Omarchy's staging lock so a concurrent switch cannot replace the source
# during publication, or let an older hook overwrite a newer palette.
exec 9>"${XDG_RUNTIME_DIR:-/tmp}/omarchy-theme-set.lock"
flock 9
[[ -f "$source_path" ]] || exit 0
palette=$(cat "$source_path")

if ! jq -e '
  def rgb: type == "string" and test("^#[0-9a-fA-F]{6}$");
  def color: type == "string" and test("^#[0-9a-fA-F]{6}([0-9a-fA-F]{2})?$");
  type == "object" and
  ((keys - ["background", "foreground", "selection", "cursor", "ansi", "colors"]) | length == 0) and
  (.background | rgb) and (.foreground | rgb) and (.selection | rgb) and
  ((.cursor // .foreground) | rgb) and
  (.ansi | type == "array" and length == 16 and all(.[]; rgb)) and
  (if has("colors") then (.colors | type == "object" and all(.[]; color)) else true end)
' <<<"$palette" >/dev/null 2>&1; then
  echo "Skipping Herdr theme: generated colors are invalid or unresolved." >&2
  exit 0
fi

theme_path="$app_home/themes/omarchy.json"
mkdir -p "${theme_path%/*}"
theme_tmp=$(mktemp "$theme_path.XXXXXX")
trap 'rm -f "$theme_tmp"' EXIT
printf '%s\n' "$palette" >"$theme_tmp"
if ! cmp -s "$theme_tmp" "$theme_path"; then
  mv "$theme_tmp" "$theme_path"
fi

# No settings edits or app commands: publish even while Herdr is closed, and
# respect any different theme selected inside Herdr.
