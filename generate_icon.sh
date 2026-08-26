#!/usr/bin/env bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DIR"

SRC_IMAGE="$1"
if [ -z "$SRC_IMAGE" ] || [ ! -f "$SRC_IMAGE" ]; then
    echo "Usage: bash generate_icon.sh <path-to-image>"
    exit 1
fi

TEMP_IMG="${DIR}/.temp_icon.png"

# If it's an SVG or text file containing data:image/png;base64, or raw base64
if file "$SRC_IMAGE" | grep -qE "SVG|XML|ASCII text|text"; then
    echo "🔄 正在从 SVG / 文本提取图像..."
    if grep -q "data:image/png;base64," "$SRC_IMAGE"; then
        sed -n 's/.*data:image\/png;base64,\([A-Za-z0-9+/=]*\).*/\1/p' "$SRC_IMAGE" | head -n 1 | base64 -d > "$TEMP_IMG"
    else
        base64 -d "$SRC_IMAGE" > "$TEMP_IMG" 2>/dev/null || true
    fi
    if [ -s "$TEMP_IMG" ]; then
        SRC_IMAGE="$TEMP_IMG"
    fi
fi

ICONSET="AppIcon.iconset"
rm -rf "$ICONSET"
mkdir -p "$ICONSET"

echo "🎨 正在生成各尺寸图标..."

sips -s format png -z 16 16     "$SRC_IMAGE" --out "$ICONSET/icon_16x16.png" >/dev/null 2>&1 || true
sips -s format png -z 32 32     "$SRC_IMAGE" --out "$ICONSET/icon_16x16@2x.png" >/dev/null 2>&1 || true
sips -s format png -z 32 32     "$SRC_IMAGE" --out "$ICONSET/icon_32x32.png" >/dev/null 2>&1 || true
sips -s format png -z 64 64     "$SRC_IMAGE" --out "$ICONSET/icon_32x32@2x.png" >/dev/null 2>&1 || true
sips -s format png -z 128 128   "$SRC_IMAGE" --out "$ICONSET/icon_128x128.png" >/dev/null 2>&1 || true
sips -s format png -z 256 256   "$SRC_IMAGE" --out "$ICONSET/icon_128x128@2x.png" >/dev/null 2>&1 || true
sips -s format png -z 256 256   "$SRC_IMAGE" --out "$ICONSET/icon_256x256.png" >/dev/null 2>&1 || true
sips -s format png -z 512 512   "$SRC_IMAGE" --out "$ICONSET/icon_256x256@2x.png" >/dev/null 2>&1 || true
sips -s format png -z 512 512   "$SRC_IMAGE" --out "$ICONSET/icon_512x512.png" >/dev/null 2>&1 || true
sips -s format png -z 1024 1024 "$SRC_IMAGE" --out "$ICONSET/icon_512x512@2x.png" >/dev/null 2>&1 || true

echo "📦 正在打包为 AppIcon.icns..."
iconutil -c icns "$ICONSET" -o AppIcon.icns >/dev/null 2>&1 || true
rm -rf "$ICONSET" "$TEMP_IMG"

echo "✅ AppIcon.icns 处理完成！"
