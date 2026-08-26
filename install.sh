#!/usr/bin/env bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DIR"

# 1. Build if not already built or rebuild
bash build.sh

APP_NAME="BeijingClock.app"
DEST_DIR="/Applications"

# 2. Stop running instance if any
killall BeijingClock 2>/dev/null || true

# 3. Copy to /Applications
echo "📦 正在安装到 ${DEST_DIR}..."
rm -rf "${DEST_DIR}/${APP_NAME}"
cp -R "${APP_NAME}" "${DEST_DIR}/"

# 4. Launch app
echo "🚀 正在启动北京时钟..."
open "${DEST_DIR}/${APP_NAME}"

echo "🎉 安装并启动成功！请查看顶部菜单栏。"
