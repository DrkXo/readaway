#!/usr/bin/env bash
set -euo pipefail

# Determine script & project root directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

RELEASE_DIR="${1:-$ROOT_DIR/build/release}"

if [ ! -d "$RELEASE_DIR" ]; then
  echo "Error: Release directory does not exist at $RELEASE_DIR" >&2
  exit 1
fi

CHECKSUM_FILE="$RELEASE_DIR/checksums.txt"

echo "=================================================="
echo "Generating SHA-256 Checksums"
echo "Directory: $RELEASE_DIR"
echo "=================================================="

rm -f "$CHECKSUM_FILE"

cd "$RELEASE_DIR"
FILES=$(find . -maxdepth 1 -type f \( -name "*.apk" -o -name "*.tar.gz" -o -name "*.AppImage" -o -name "*.zsync" -o -name "*.zip" -o -name "*.deb" -o -name "*.rpm" \) -printf "%f\n" | sort)

if [ -z "$FILES" ]; then
  echo "[INFO] No release binaries found in $RELEASE_DIR to checksum."
  exit 0
fi

for f in $FILES; do
  sha256sum "$f" >> checksums.txt
  echo "  [OK] $(sha256sum "$f")"
done

echo "=================================================="
echo "Saved checksums to $CHECKSUM_FILE"
