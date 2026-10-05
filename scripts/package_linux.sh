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

BUNDLE_DIR="$APP_DIR/build/linux/x64/release/bundle"

echo "=================================================="
echo "Packaging Linux Artifacts for Readaway ($VERSION)"
echo "Output Directory: $OUT_DIR"
echo "=================================================="

if [ ! -d "$BUNDLE_DIR" ]; then
  echo "Error: Linux release bundle not found at $BUNDLE_DIR" >&2
  echo "Please run 'fvm exec flutter build linux --release' inside apps/readaway first." >&2
  exit 1
fi

COUNT=0

# -------------------------------------------------------------
# 1. Package .tar.gz Portable Archive
# -------------------------------------------------------------
TAR_NAME="readaway-${VERSION}-linux-x86_64.tar.gz"
TEMP_TAR_DIR="$(mktemp -d)"
PACKAGE_FOLDER_NAME="readaway-${VERSION}"

mkdir -p "$TEMP_TAR_DIR/$PACKAGE_FOLDER_NAME"
cp -r "$BUNDLE_DIR"/* "$TEMP_TAR_DIR/$PACKAGE_FOLDER_NAME/"

tar -czf "$OUT_DIR/$TAR_NAME" -C "$TEMP_TAR_DIR" "$PACKAGE_FOLDER_NAME"
rm -rf "$TEMP_TAR_DIR"
echo "  [OK] Created: $TAR_NAME ($(du -h "$OUT_DIR/$TAR_NAME" | cut -f1))"
COUNT=$((COUNT + 1))

# -------------------------------------------------------------
# 2. Package .AppImage & .zsync
# -------------------------------------------------------------
APPIMAGE_NAME="readaway-${VERSION}-linux-x86_64.AppImage"
ZSYNC_NAME="${APPIMAGE_NAME}.zsync"
TEMP_APPDIR="$(mktemp -d)/AppDir"
mkdir -p "$TEMP_APPDIR"

# Copy binary & assets
cp -r "$BUNDLE_DIR"/* "$TEMP_APPDIR/"

# -------------------------------------------------------------
# Staging standard Freedesktop directory structure
# -------------------------------------------------------------
mkdir -p "$TEMP_APPDIR/usr/share/applications"
mkdir -p "$TEMP_APPDIR/usr/share/mime/packages"
mkdir -p "$TEMP_APPDIR/usr/share/icons/hicolor/256x256/apps"

mkdir -p "$TEMP_APPDIR/usr/share/metainfo"

# Copy desktop file to both root and usr/share/applications
if [ -f "$APP_DIR/linux/dev.readaway.desktop" ]; then
  cp "$APP_DIR/linux/dev.readaway.desktop" "$TEMP_APPDIR/dev.readaway.desktop"
  cp "$APP_DIR/linux/dev.readaway.desktop" "$TEMP_APPDIR/usr/share/applications/dev.readaway.desktop"
fi

# Copy MIME XML definition
if [ -f "$APP_DIR/linux/dev.readaway.xml" ]; then
  cp "$APP_DIR/linux/dev.readaway.xml" "$TEMP_APPDIR/usr/share/mime/packages/dev.readaway.xml"
fi

# Copy AppStream metadata
if [ -f "$APP_DIR/linux/dev.readaway.metainfo.xml" ]; then
  cp "$APP_DIR/linux/dev.readaway.metainfo.xml" "$TEMP_APPDIR/usr/share/metainfo/dev.readaway.metainfo.xml"
fi

# Create symlink for lowercase executable name
(cd "$TEMP_APPDIR" && ln -sf Readaway readaway)

# Copy icons (standard, namespaced, and AppDir metadata)
ICON_SRC="$APP_DIR/assets/logo/foreground.png"
if [ -f "$ICON_SRC" ]; then
  cp "$ICON_SRC" "$TEMP_APPDIR/usr/share/icons/hicolor/256x256/apps/readaway.png"
  cp "$ICON_SRC" "$TEMP_APPDIR/usr/share/icons/hicolor/256x256/apps/dev.readaway.png"
  cp "$ICON_SRC" "$TEMP_APPDIR/readaway.png"
  cp "$ICON_SRC" "$TEMP_APPDIR/dev.readaway.png"
  cp "$ICON_SRC" "$TEMP_APPDIR/.DirIcon"
fi

# Create AppRun launcher with self-registration capabilities
cat << 'EOF' > "$TEMP_APPDIR/AppRun"
#!/usr/bin/env bash
set -e
HERE="$(dirname "$(readlink -f "${0}")")"
export LD_LIBRARY_PATH="${HERE}/lib:${LD_LIBRARY_PATH:-}"
export PATH="${HERE}:${PATH}"

# Self-registration handler for desktop integration and MIME associations
if [ "${1:-}" = "--install" ] || [ "${1:-}" = "--register-desktop" ]; then
  TARGET_APP_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/applications"
  TARGET_ICON_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/icons/hicolor/256x256/apps"
  TARGET_MIME_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/mime/packages"
  mkdir -p "$TARGET_APP_DIR" "$TARGET_ICON_DIR" "$TARGET_MIME_DIR"

  APPIMAGE_PATH="${APPIMAGE:-$(readlink -f "$0")}"
  sed -e "s|^Exec=.*|Exec=\"${APPIMAGE_PATH}\" %F|" \
      "$HERE/dev.readaway.desktop" > "$TARGET_APP_DIR/dev.readaway.desktop"

  if [ -f "$HERE/readaway.png" ]; then
    cp "$HERE/readaway.png" "$TARGET_ICON_DIR/readaway.png"
    cp "$HERE/readaway.png" "$TARGET_ICON_DIR/dev.readaway.png"
  fi
  if [ -f "$HERE/usr/share/mime/packages/dev.readaway.xml" ]; then
    cp "$HERE/usr/share/mime/packages/dev.readaway.xml" "$TARGET_MIME_DIR/dev.readaway.xml"
  fi

  update-desktop-database "$TARGET_APP_DIR" 2>/dev/null || true
  update-mime-database "${XDG_DATA_HOME:-$HOME/.local/share}/mime" 2>/dev/null || true
  gtk-update-icon-cache -t -f "${XDG_DATA_HOME:-$HOME/.local/share}/icons/hicolor" 2>/dev/null || true
  echo "[OK] Readaway successfully integrated with desktop and registered for all document MIME types."
  exit 0
elif [ "${1:-}" = "--uninstall" ] || [ "${1:-}" = "--unregister-desktop" ]; then
  TARGET_APP_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/applications"
  TARGET_ICON_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/icons/hicolor/256x256/apps"
  TARGET_MIME_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/mime/packages"
  rm -f "$TARGET_APP_DIR/dev.readaway.desktop"
  rm -f "$TARGET_ICON_DIR/readaway.png" "$TARGET_ICON_DIR/dev.readaway.png"
  rm -f "$TARGET_MIME_DIR/dev.readaway.xml"
  update-desktop-database "$TARGET_APP_DIR" 2>/dev/null || true
  update-mime-database "${XDG_DATA_HOME:-$HOME/.local/share}/mime" 2>/dev/null || true
  echo "[OK] Readaway desktop integration removed."
  exit 0
fi

exec "${HERE}/Readaway" "$@"
EOF
chmod +x "$TEMP_APPDIR/AppRun"

# Check for appimagetool or download standalone
TOOL_DIR="$ROOT_DIR/build/tools"
mkdir -p "$TOOL_DIR"

if command -v appimagetool >/dev/null 2>&1; then
  TOOL_EXEC="appimagetool"
else
  APPIMAGETOOL_IMAGE="$TOOL_DIR/appimagetool-x86_64.AppImage"
  APPIMAGETOOL_EXTRACTED="$TOOL_DIR/squashfs-root/AppRun"

  if [ ! -f "$APPIMAGETOOL_EXTRACTED" ]; then
    if [ ! -f "$APPIMAGETOOL_IMAGE" ]; then
      echo "  [INFO] Downloading appimagetool..."
      curl -sSL -o "$APPIMAGETOOL_IMAGE" "https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-x86_64.AppImage"
      chmod +x "$APPIMAGETOOL_IMAGE"
    fi
    echo "  [INFO] Extracting appimagetool for FUSE-less execution..."
    (cd "$TOOL_DIR" && "$APPIMAGETOOL_IMAGE" --appimage-extract >/dev/null 2>&1 || true)
  fi

  if [ -f "$APPIMAGETOOL_EXTRACTED" ]; then
    TOOL_EXEC="$APPIMAGETOOL_EXTRACTED"
  else
    TOOL_EXEC="$APPIMAGETOOL_IMAGE"
  fi
fi

UPDATE_INFO="gh-releases-zsync|DrkXo|readaway|latest|readaway-*-linux-x86_64.AppImage.zsync"

echo "  [INFO] Building AppImage with appimagetool (with zsync update info)..."
ARCH=x86_64 "$TOOL_EXEC" -u "$UPDATE_INFO" "$TEMP_APPDIR" "$OUT_DIR/$APPIMAGE_NAME" || {
  ARCH=x86_64 "$TOOL_EXEC" -u "$UPDATE_INFO" --appimage-extract-and-run "$TEMP_APPDIR" "$OUT_DIR/$APPIMAGE_NAME" || {
    ARCH=x86_64 "$TOOL_EXEC" "$TEMP_APPDIR" "$OUT_DIR/$APPIMAGE_NAME"
  }
}

rm -rf "$(dirname "$TEMP_APPDIR")"

if [ -f "$OUT_DIR/$APPIMAGE_NAME" ]; then
  echo "  [OK] Created: $APPIMAGE_NAME ($(du -h "$OUT_DIR/$APPIMAGE_NAME" | cut -f1))"
  COUNT=$((COUNT + 1))
  
  # Check companion .zsync file
  if [ -f "$OUT_DIR/$ZSYNC_NAME" ]; then
    echo "  [OK] Created: $ZSYNC_NAME ($(du -h "$OUT_DIR/$ZSYNC_NAME" | cut -f1))"
    COUNT=$((COUNT + 1))
  elif [ -f "$OUT_DIR/$APPIMAGE_NAME.zsync" ]; then
    echo "  [OK] Created: $APPIMAGE_NAME.zsync ($(du -h "$OUT_DIR/$APPIMAGE_NAME.zsync" | cut -f1))"
    COUNT=$((COUNT + 1))
  elif command -v zsyncmake >/dev/null 2>&1; then
    zsyncmake -u "https://github.com/DrkXo/readaway/releases/latest/download/$APPIMAGE_NAME" -o "$OUT_DIR/$ZSYNC_NAME" "$OUT_DIR/$APPIMAGE_NAME"
    if [ -f "$OUT_DIR/$ZSYNC_NAME" ]; then
      echo "  [OK] Created via zsyncmake: $ZSYNC_NAME ($(du -h "$OUT_DIR/$ZSYNC_NAME" | cut -f1))"
      COUNT=$((COUNT + 1))
    fi
  fi
else
  echo "  [WARN] Failed to generate AppImage."
  exit 1
fi

echo "=================================================="
echo "Successfully packaged $COUNT Linux artifact(s) into $OUT_DIR"
