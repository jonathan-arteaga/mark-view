#!/usr/bin/env bash

if [[ -z "${ROOT:-}" ]]; then
  ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fi

project_setting() {
  local key="$1"
  /usr/bin/awk -F: -v key="$key" '
    $1 ~ "^[[:space:]]*" key "$" {
      value = $2
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", value)
      gsub(/^"|"$/, "", value)
      print value
      exit
    }
  ' "$ROOT/project.yml"
}

MARKVIEW_VERSION="${MARKVIEW_VERSION:-$(project_setting MARKETING_VERSION)}"
MARKVIEW_BUILD_NUMBER="${MARKVIEW_BUILD_NUMBER:-$(project_setting CURRENT_PROJECT_VERSION)}"

if [[ -z "$MARKVIEW_VERSION" || -z "$MARKVIEW_BUILD_NUMBER" ]]; then
  echo "Could not read MarkView version from project.yml." >&2
  return 1 2>/dev/null || exit 1
fi
