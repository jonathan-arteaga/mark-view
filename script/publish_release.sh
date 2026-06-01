#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="MarkView"
VERSION="${MARKVIEW_VERSION:-0.1.1}"
TAG="${MARKVIEW_RELEASE_TAG:-v$VERSION}"
REPO="${MARKVIEW_GITHUB_REPO:-jonathan-arteaga/mark-view}"
DMG_PATH="$ROOT/dist/$APP_NAME-$VERSION-macOS.dmg"
ZIP_ASSET="$APP_NAME-$VERSION-macOS.zip"

if ! command -v gh >/dev/null 2>&1; then
  echo "GitHub CLI is required. Install gh, authenticate, then rerun this script."
  exit 1
fi

if [[ ! -f "$DMG_PATH" ]]; then
  echo "Missing DMG: $DMG_PATH"
  echo "Run ./script/package_dmg.sh first."
  exit 1
fi

gh release upload "$TAG" "$DMG_PATH" --repo "$REPO" --clobber

if gh release view "$TAG" --repo "$REPO" --json assets --jq '.assets[].name' | /usr/bin/grep -qx "$ZIP_ASSET"; then
  gh release delete-asset "$TAG" "$ZIP_ASSET" --repo "$REPO" --yes
fi

echo "Uploaded $DMG_PATH to $REPO@$TAG"
