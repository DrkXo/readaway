#!/usr/bin/env bash
set -euo pipefail

# Determine script & project root directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
APP_DIR="$ROOT_DIR/apps/readaway"

# 1. Resolve Version
INPUT_VERSION="${1:-}"
if [ -z "$INPUT_VERSION" ]; then
  # Extract version from apps/readaway/pubspec.yaml (e.g. 1.1.0+2 -> v1.1.0)
  RAW_VERSION=$(grep "^version:" "$APP_DIR/pubspec.yaml" | head -n 1 | awk '{print $2}' | cut -d'+' -f1 | tr -d '"' | tr -d "'")
  VERSION="v$RAW_VERSION"
else
  # Clean up provided version (e.g. readaway-v1.1.0 -> v1.1.0)
  VERSION="$(echo "$INPUT_VERSION" | sed 's/^readaway-//')"
  if [[ ! "$VERSION" =~ ^v ]]; then
    VERSION="v$VERSION"
  fi
fi

# 2. Resolve Output Directory
OUT_DIR="${2:-$ROOT_DIR/build/release}"
mkdir -p "$OUT_DIR"

echo "=================================================="
echo "Packaging Android Artifacts for ReadAway ($VERSION)"
echo "Output Directory: $OUT_DIR"
echo "=================================================="

APK_DIR="$APP_DIR/build/app/outputs/flutter-apk"
AAB_DIR="$APP_DIR/build/app/outputs/bundle/release"

COUNT=0

# Helper function to copy and rename
copy_artifact() {
  local src="$1"
  local dest_name="$2"
  if [ -f "$src" ]; then
    cp "$src" "$OUT_DIR/$dest_name"
    echo "  [OK] Created: $dest_name ($(du -h "$src" | cut -f1))"
    COUNT=$((COUNT + 1))
  else
    echo "  [SKIP] Not found: $src"
  fi
}

# Copy Universal APK
copy_artifact "$APK_DIR/app-release.apk" "readaway-${VERSION}-android-universal.apk"

# Copy ABI Split APKs
copy_artifact "$APK_DIR/app-arm64-v8a-release.apk" "readaway-${VERSION}-android-arm64-v8a.apk"
copy_artifact "$APK_DIR/app-armeabi-v7a-release.apk" "readaway-${VERSION}-android-armeabi-v7a.apk"
copy_artifact "$APK_DIR/app-x86_64-release.apk" "readaway-${VERSION}-android-x86_64.apk"

# Copy App Bundle
copy_artifact "$AAB_DIR/app-release.aab" "readaway-${VERSION}-android.aab"

echo "=================================================="
if [ "$COUNT" -gt 0 ]; then
  echo "Successfully packaged $COUNT Android artifact(s) into $OUT_DIR"
else
  echo "Error: No Android build artifacts found in $APP_DIR/build!" >&2
  exit 1
fi
