#!/usr/bin/env bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DIR"

APP_NAME="BeijingClock"
APP_BUNDLE="${APP_NAME}.app"
CONTENTS_DIR="${APP_BUNDLE}/Contents"
MACOS_DIR="${CONTENTS_DIR}/MacOS"
RESOURCES_DIR="${CONTENTS_DIR}/Resources"
CACHE_DIR="${DIR}/.build_cache"

echo "🔨 正在编译 ${APP_NAME} (Universal Binary: Apple Silicon + Intel)..."

# Create directories
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"
mkdir -p "$CACHE_DIR"

# Copy Info.plist and AppIcon
cp Info.plist "$CONTENTS_DIR/Info.plist"
if [ -f "AppIcon.icns" ]; then
    cp AppIcon.icns "$RESOURCES_DIR/AppIcon.icns"
    echo "🎨 AppIcon.icns 装配完成"
fi

# Compile Universal Binary (arm64 + x86_64) for macOS 11.0+
swiftc -O -whole-module-optimization \
    -target arm64-apple-macos11.0 \
    -module-cache-path "$CACHE_DIR" \
    -Xclang-linker -fmodules-cache-path="$CACHE_DIR" \
    -framework AppKit \
    -framework Foundation \
    -framework ServiceManagement \
    main.swift \
    -o "${MACOS_DIR}/${APP_NAME}_arm64"

swiftc -O -whole-module-optimization \
    -target x86_64-apple-macos11.0 \
    -module-cache-path "$CACHE_DIR" \
    -Xclang-linker -fmodules-cache-path="$CACHE_DIR" \
    -framework AppKit \
    -framework Foundation \
    -framework ServiceManagement \
    main.swift \
    -o "${MACOS_DIR}/${APP_NAME}_x86"

# Create universal binary using lipo
lipo -create -output "${MACOS_DIR}/${APP_NAME}" "${MACOS_DIR}/${APP_NAME}_arm64" "${MACOS_DIR}/${APP_NAME}_x86"
rm -f "${MACOS_DIR}/${APP_NAME}_arm64" "${MACOS_DIR}/${APP_NAME}_x86"
chmod +x "${MACOS_DIR}/${APP_NAME}"

# Code sign locally for ad-hoc execution on macOS
codesign --force --deep --sign - "$APP_BUNDLE" 2>/dev/null || true

echo "✅ 编译完成！App 位于: ${DIR}/${APP_BUNDLE}"
