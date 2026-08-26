#!/usr/bin/env bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DIR"

SRC_IMAGE="$1"
if [ -z "$SRC_IMAGE" ] || [ ! -f "$SRC_IMAGE" ]; then
    echo "Usage: bash generate_icon.sh <path-to-image>"
    exit 1
fi

ICONSET="AppIcon.iconset"
rm -rf "$ICONSET"
mkdir -p "$ICONSET"

echo "🎨 正在生成各尺寸图标..."

# Generate standard macOS icon set sizes with format png
sips -s format png -z 16 16     "$SRC_IMAGE" --out "$ICONSET/icon_16x16.png" >/dev/null
sips -s format png -z 32 32     "$SRC_IMAGE" --out "$ICONSET/icon_16x16@2x.png" >/dev/null
sips -s format png -z 32 32     "$SRC_IMAGE" --out "$ICONSET/icon_32x32.png" >/dev/null
sips -s format png -z 64 64     "$SRC_IMAGE" --out "$ICONSET/icon_32x32@2x.png" >/dev/null
sips -s format png -z 128 128   "$SRC_IMAGE" --out "$ICONSET/icon_128x128.png" >/dev/null
sips -s format png -z 256 256   "$SRC_IMAGE" --out "$ICONSET/icon_128x128@2x.png" >/dev/null
sips -s format png -z 256 256   "$SRC_IMAGE" --out "$ICONSET/icon_256x256.png" >/dev/null
sips -s format png -z 512 512   "$SRC_IMAGE" --out "$ICONSET/icon_256x256@2x.png" >/dev/null
sips -s format png -z 512 512   "$SRC_IMAGE" --out "$ICONSET/icon_512x512.png" >/dev/null
sips -s format png -z 1024 1024 "$SRC_IMAGE" --out "$ICONSET/icon_512x512@2x.png" >/dev/null

echo "📦 正在打包为 AppIcon.icns..."
iconutil -c icns "$ICONSET" -o AppIcon.icns
rm -rf "$ICONSET"

echo "✅ AppIcon.icns 生成成功！"
