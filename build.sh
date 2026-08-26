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

echo "🔨 正在编译 ${APP_NAME}..."

# Create directories
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"
mkdir -p "$CACHE_DIR"

# Generate AppIcon.icns if not present
if [ ! -f "AppIcon.icns" ] && [ -f "assets/icon.png" ]; then
    echo "🎨 正在从 assets/icon.png 生成 AppIcon.icns..."
    bash generate_icon.sh assets/icon.png
fi

# Copy Info.plist and AppIcon
cp Info.plist "$CONTENTS_DIR/Info.plist"
if [ -f "AppIcon.icns" ]; then
    cp AppIcon.icns "$RESOURCES_DIR/AppIcon.icns"
fi

# Compile Swift with local module cache
swiftc -O -whole-module-optimization \
    -module-cache-path "$CACHE_DIR" \
    -Xclang-linker -fmodules-cache-path="$CACHE_DIR" \
    -framework AppKit \
    -framework Foundation \
    -framework ServiceManagement \
    main.swift \
    -o "${MACOS_DIR}/${APP_NAME}"

# Code sign locally for ad-hoc execution on macOS
codesign --force --deep --sign - "$APP_BUNDLE" 2>/dev/null || true

echo "✅ 编译完成！App 位于: ${DIR}/${APP_BUNDLE}"
