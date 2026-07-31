#!/usr/bin/env bash
# prepare-release-assets-carbonfusion.sh
#
# CarbonFusion 专用 — 简化版 Release 资产准备脚本
# 只验证实际构建的 4 个平台产物，不检查 web-cli 和 updater 元数据
#
# Usage:
#   ./scripts/prepare-release-assets-carbonfusion.sh [ARTIFACTS_DIR] [OUTPUT_DIR]
#
# Defaults:
#   ARTIFACTS_DIR = build-artifacts
#   OUTPUT_DIR    = release-assets

set -euo pipefail

ARTIFACTS_DIR="${1:-build-artifacts}"
OUTPUT_DIR="${2:-release-assets}"

rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"

# ---------------------------------------------------------------------------
# 1) Copy all distributables
# ---------------------------------------------------------------------------
echo "==> Copying distributables from $ARTIFACTS_DIR ..."
DISTRIBUTABLES=()
while IFS= read -r file; do
  DISTRIBUTABLES+=("$file")
done < <(find "$ARTIFACTS_DIR" -type f \( \
  -name "*.exe" -o \
  -name "*.msi" -o \
  -name "*.dmg" -o \
  -name "*.deb" -o \
  -name "*.zip" \
\) | sort)

DUPLICATE_BASENAMES=$(for file in "${DISTRIBUTABLES[@]}"; do basename "$file"; done | sort | uniq -d || true)
if [ -n "$DUPLICATE_BASENAMES" ]; then
  echo "::error::Found duplicate distributable basenames that would be overwritten in flat output:"
  echo "$DUPLICATE_BASENAMES"
  exit 1
fi

for file in "${DISTRIBUTABLES[@]}"; do
  cp -f "$file" "$OUTPUT_DIR/"
done

# ---------------------------------------------------------------------------
# 2) Copy updater metadata (optional — only if present, won't fail)
# ---------------------------------------------------------------------------
echo "==> Collecting updater metadata (optional) ..."

WIN_X64_LATEST=$(find "$ARTIFACTS_DIR" -type f -path "*/windows-build-x64/*" -name "latest.yml" | sort | head -n 1 || true)
WIN_ARM64_LATEST=$(find "$ARTIFACTS_DIR" -type f -path "*/windows-build-arm64/*" -name "latest.yml" | sort | head -n 1 || true)
MAC_ARM64_LATEST=$(find "$ARTIFACTS_DIR" -type f -path "*/macos-build-arm64/*" -name "latest-mac.yml" | sort | head -n 1 || true)
LINUX_X64_LATEST=$(find "$ARTIFACTS_DIR" -type f -path "*/linux-build-x64/*" -name "latest-linux.yml" | sort | head -n 1 || true)

[ -n "$WIN_X64_LATEST" ]    && cp -f "$WIN_X64_LATEST"    "$OUTPUT_DIR/latest.yml"
[ -n "$MAC_ARM64_LATEST" ]  && cp -f "$MAC_ARM64_LATEST"  "$OUTPUT_DIR/latest-mac.yml"
[ -n "$LINUX_X64_LATEST" ]  && cp -f "$LINUX_X64_LATEST"  "$OUTPUT_DIR/latest-linux.yml"
[ -n "$WIN_ARM64_LATEST" ]  && cp -f "$WIN_ARM64_LATEST"  "$OUTPUT_DIR/latest-win-arm64.yml"

# ---------------------------------------------------------------------------
# 3) Validate desktop release assets (only check what we built)
# ---------------------------------------------------------------------------
echo "==> Validating desktop release assets ..."

VERSION="${MOCK_VERSION:-$(node -p "require('./package.json').version")}"
MISSING=0

# macOS ARM64
if [ -f "$OUTPUT_DIR/CarbonFusion-${VERSION}-mac-arm64.dmg" ]; then
  echo "  ✅ macOS ARM64: CarbonFusion-${VERSION}-mac-arm64.dmg"
else
  echo "  ⚠️  macOS ARM64 DMG not found (optional)"
fi

# Windows x64
if ls "$OUTPUT_DIR"/CarbonFusion-*-win-x64.exe 1>/dev/null 2>&1; then
  echo "  ✅ Windows x64: $(ls "$OUTPUT_DIR"/CarbonFusion-*-win-x64.exe)"
else
  echo "  ❌ Windows x64 installer not found"
  MISSING=1
fi

# Windows ARM64
if ls "$OUTPUT_DIR"/CarbonFusion-*-win-arm64.exe 1>/dev/null 2>&1; then
  echo "  ✅ Windows ARM64: $(ls "$OUTPUT_DIR"/CarbonFusion-*-win-arm64.exe)"
else
  echo "  ❌ Windows ARM64 installer not found"
  MISSING=1
fi

# Linux x64
if ls "$OUTPUT_DIR"/CarbonFusion-*-linux-amd64.deb 1>/dev/null 2>&1; then
  echo "  ✅ Linux x64: $(ls "$OUTPUT_DIR"/CarbonFusion-*-linux-amd64.deb)"
else
  echo "  ❌ Linux x64 installer not found"
  MISSING=1
fi

if [ "$MISSING" -ne 0 ]; then
  echo "::error::Missing required desktop release assets"
  exit 1
fi

echo ""
echo "==> Prepared release assets:"
ls -lh "$OUTPUT_DIR"
echo ""
echo "==> Done."