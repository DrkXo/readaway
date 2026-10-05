#!/usr/bin/env bash
set -euo pipefail

# Determine script & project root directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
APP_DIR="$ROOT_DIR/apps/readaway"
BUNDLE_DIR="$APP_DIR/build/linux/x64/release/bundle"

# 1. Resolve Version
INPUT_VERSION="${1:-}"
if [ -z "$INPUT_VERSION" ]; then
  # Extract version from apps/readaway/pubspec.yaml (e.g. 1.1.0+2 -> v1.1.0)
  RAW_VERSION=$(grep "^version:" "$APP_DIR/pubspec.yaml" | head -n 1 | awk '{print $2}' | cut -d'+' -f1 | tr -d '"' | tr -d "'")
  VERSION="v$RAW_VERSION"
else
  VERSION="$(echo "$INPUT_VERSION" | sed 's/^readaway-//')"
  if [[ ! "$VERSION" =~ ^v ]]; then
    VERSION="v$VERSION"
  fi
fi

# Clean version without leading 'v' for standard package managers (e.g. 1.1.0)
VERSION_CLEAN="$(echo "$VERSION" | sed 's/^v//')"

# 2. Resolve Output Directory & Target Packagers
OUT_DIR="${2:-$ROOT_DIR/build/release}"
TARGET_PACKAGER="${3:-all}" # all, deb, or rpm
mkdir -p "$OUT_DIR"

echo "=================================================="
echo "Packaging Linux Native (.deb / .rpm) for Readaway ($VERSION)"
echo "Output Directory: $OUT_DIR"
echo "Target Format(s): $TARGET_PACKAGER"
echo "=================================================="

if [ ! -d "$BUNDLE_DIR" ]; then
  echo "Error: Linux release bundle not found at $BUNDLE_DIR" >&2
  echo "Please run 'melos run build:linux' (or 'fvm exec flutter build linux --release' in apps/readaway) first." >&2
  exit 1
fi

# 3. Ensure nFPM CLI is Available
TOOL_DIR="$ROOT_DIR/build/tools"
mkdir -p "$TOOL_DIR"

if command -v nfpm >/dev/null 2>&1; then
  NFPM_EXEC="nfpm"
elif [ -x "$TOOL_DIR/nfpm" ]; then
  NFPM_EXEC="$TOOL_DIR/nfpm"
else
  echo "  [INFO] Downloading standalone nFPM packager (v2.47.0)..."
  NFPM_TAR="$TOOL_DIR/nfpm.tar.gz"
  curl -sSL -o "$NFPM_TAR" "https://github.com/goreleaser/nfpm/releases/download/v2.47.0/nfpm_2.47.0_Linux_x86_64.tar.gz"
  tar -xzf "$NFPM_TAR" -C "$TOOL_DIR" nfpm
  chmod +x "$TOOL_DIR/nfpm"
  rm -f "$NFPM_TAR"
  NFPM_EXEC="$TOOL_DIR/nfpm"
fi

TEMPLATE_FILE="$SCRIPT_DIR/packaging/nfpm.yaml.template"
if [ ! -f "$TEMPLATE_FILE" ]; then
  echo "Error: Template not found at $TEMPLATE_FILE" >&2
  exit 1
fi

COUNT=0
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

# Helper function to render template
render_config() {
  local arch="$1"
  local config_path="$2"

  sed -e "s|\${ARCH}|$arch|g" \
      -e "s|\${VERSION_CLEAN}|$VERSION_CLEAN|g" \
      -e "s|\${BUNDLE_DIR}|$BUNDLE_DIR|g" \
      -e "s|\${APP_DIR}|$APP_DIR|g" \
      -e "s|\${SCRIPTS_DIR}|$SCRIPT_DIR|g" \
      "$TEMPLATE_FILE" > "$config_path"
}

# -------------------------------------------------------------
# 1. Package Debian (.deb)
# -------------------------------------------------------------
if [ "$TARGET_PACKAGER" = "all" ] || [ "$TARGET_PACKAGER" = "deb" ]; then
  DEB_NAME="readaway-${VERSION}-linux-amd64.deb"
  DEB_CONFIG="$TMP_DIR/nfpm_deb.yaml"
  render_config "amd64" "$DEB_CONFIG"

  echo "  [INFO] Building Debian package ($DEB_NAME)..."
  "$NFPM_EXEC" package --config "$DEB_CONFIG" --packager deb --target "$OUT_DIR/$DEB_NAME"
  if [ -f "$OUT_DIR/$DEB_NAME" ]; then
    echo "  [OK] Created: $DEB_NAME ($(du -h "$OUT_DIR/$DEB_NAME" | cut -f1))"
    COUNT=$((COUNT + 1))
  else
    echo "  [ERROR] Failed to create $DEB_NAME" >&2
    exit 1
  fi
fi

# -------------------------------------------------------------
# 2. Package Red Hat (.rpm)
# -------------------------------------------------------------
if [ "$TARGET_PACKAGER" = "all" ] || [ "$TARGET_PACKAGER" = "rpm" ]; then
  RPM_NAME="readaway-${VERSION}-linux-x86_64.rpm"
  RPM_CONFIG="$TMP_DIR/nfpm_rpm.yaml"
  render_config "x86_64" "$RPM_CONFIG"

  echo "  [INFO] Building Red Hat RPM package ($RPM_NAME)..."
  "$NFPM_EXEC" package --config "$RPM_CONFIG" --packager rpm --target "$OUT_DIR/$RPM_NAME"
  if [ -f "$OUT_DIR/$RPM_NAME" ]; then
    echo "  [OK] Created: $RPM_NAME ($(du -h "$OUT_DIR/$RPM_NAME" | cut -f1))"
    COUNT=$((COUNT + 1))
  else
    echo "  [ERROR] Failed to create $RPM_NAME" >&2
    exit 1
  fi
fi

echo "=================================================="
echo "Successfully packaged $COUNT native Linux package(s) into $OUT_DIR"
