#!/usr/bin/env bash
# Shared parser: one package name per line, with optional # comments.

# Print required shared paths plus any optional files for an explicit machine.
package_list_files() {
  local directory="$1" machine="$2" list filename
  shift 2
  if [[ -n "$machine" ]]; then
    if [[ ! "$machine" =~ ^[a-zA-Z0-9][a-zA-Z0-9_-]*$ ]]; then
      echo "Invalid machine name: $machine (use letters, digits, underscores, or hyphens)" >&2
      return 1
    fi
    if [[ ! -d "$directory/machines/$machine" ]]; then
      echo "Machine package directory not found: $directory/machines/$machine" >&2
      return 1
    fi
  fi

  for list in "$@"; do
    case "$list" in
      system) filename=packages.txt ;;
      gui|aur) filename="packages-$list.txt" ;;
      *) echo "Unknown package list: $list" >&2; return 1 ;;
    esac
    printf '%s/%s\n' "$directory" "$filename"
    if [[ -n "$machine" && ( -e "$directory/machines/$machine/$filename" || -L "$directory/machines/$machine/$filename" ) ]]; then
      printf '%s/machines/%s/%s\n' "$directory" "$machine" "$filename"
    fi
  done
}

read_package_list() {
  local file="$1"
  if [[ ! -r "$file" || ! -f "$file" ]]; then
    echo "Package list not readable: $file" >&2
    return 1
  fi

  LC_ALL=C awk '
    {
      sub(/#.*/, "")
      gsub(/^[[:space:]]+|[[:space:]]+$/, "")
      if (!length) next
      if ($0 !~ /^[[:alnum:]@_+][[:alnum:]@._+-]*$/) {
        printf "%s:%d: expected one package name per line: %s\n", FILENAME, FNR, $0 > "/dev/stderr"
        invalid = 1
        next
      }
      if (!seen[$0]++) print
    }
    END { exit invalid ? 1 : 0 }
  ' "$file"
}
