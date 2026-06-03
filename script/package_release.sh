#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="MarkView"
source "$ROOT/script/project_version.sh"
BUILD_ROOT="${MARKVIEW_BUILD_ROOT:-$HOME/Library/Caches/MarkView}"
DERIVED_DATA="$BUILD_ROOT/PackageDerivedData"
CONFIGURATION="${MARKVIEW_CONFIGURATION:-Release}"
PROJECT="$ROOT/$APP_NAME.xcodeproj"
APP_PRODUCT="$DERIVED_DATA/Build/Products/$CONFIGURATION/$APP_NAME.app"
DIST_DIR="$ROOT/dist"
STAGING_DIR="$(mktemp -d "${TMPDIR:-/tmp}/markview-package.XXXXXX")"
VERSION="$MARKVIEW_VERSION"
ZIP_PATH="$DIST_DIR/$APP_NAME-$VERSION-macOS.zip"
LSREGISTER="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister"

cleanup() {
  rm -rf "$STAGING_DIR"
}
trap cleanup EXIT

unregister_bundles_under() {
  local path="$1"
  if [[ ! -e "$path" ]]; then
    return
  fi

  while IFS= read -r -d '' bundle_path; do
    /usr/bin/pluginkit -r "$bundle_path" >/dev/null 2>&1 || true
    "$LSREGISTER" -u "$bundle_path" >/dev/null 2>&1 || true
  done < <(/usr/bin/find "$path" \( -name "$APP_NAME.app" -o -name "${APP_NAME}PreviewExtension.appex" \) -print0 2>/dev/null || true)
}

adhoc_sign_for_distribution_zip() {
  local app_path="$1"
  local entitlements
  entitlements="$(/usr/bin/mktemp "${TMPDIR:-/tmp}/markview-zip-entitlements.XXXXXX.plist")"

  /usr/bin/plutil -create xml1 "$entitlements"
  /usr/libexec/PlistBuddy -c "Add :com.apple.security.cs.disable-library-validation bool true" "$entitlements"
  codesign --force --deep --sign - --timestamp=none --entitlements "$entitlements" "$app_path" >/dev/null
  rm -f "$entitlements"
}

if ! command -v xcodegen >/dev/null 2>&1; then
  echo "xcodegen is required. Install it with Homebrew, then rerun this script."
  exit 1
fi

cd "$ROOT"
export COPYFILE_DISABLE=1

rm -rf "$DERIVED_DATA" "$DIST_DIR/$APP_NAME.app" "$ZIP_PATH"
mkdir -p "$DIST_DIR"

xattr -rc "$ROOT/MarkViewPreviewExtension/Resources" "$ROOT/MarkView/Resources" >/dev/null 2>&1 || true
xcodegen generate

xcodebuild \
  -project "$PROJECT" \
  -scheme "$APP_NAME" \
  -configuration "$CONFIGURATION" \
  -derivedDataPath "$DERIVED_DATA" \
  build

/usr/bin/ditto --noqtn "$APP_PRODUCT" "$STAGING_DIR/$APP_NAME.app"
/usr/bin/find "$STAGING_DIR/$APP_NAME.app" -name .DS_Store -delete
/usr/bin/dot_clean -m "$STAGING_DIR/$APP_NAME.app" >/dev/null 2>&1 || true
xattr -cr "$STAGING_DIR/$APP_NAME.app" >/dev/null 2>&1 || true
xattr -d com.apple.FinderInfo "$STAGING_DIR/$APP_NAME.app" >/dev/null 2>&1 || true
adhoc_sign_for_distribution_zip "$STAGING_DIR/$APP_NAME.app"
codesign --verify --deep --strict --verbose=2 "$STAGING_DIR/$APP_NAME.app"

(
  cd "$STAGING_DIR"
  /usr/bin/ditto -c -k --sequesterRsrc --keepParent "$APP_NAME.app" "$ZIP_PATH"
)

unregister_bundles_under "$DERIVED_DATA"
rm -rf "$DERIVED_DATA" "$DIST_DIR/$APP_NAME.app"
/usr/bin/qlmanage -r >/dev/null 2>&1 || true
/usr/bin/qlmanage -r cache >/dev/null 2>&1 || true

echo "Packaged $ZIP_PATH"
