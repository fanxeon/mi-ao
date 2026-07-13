#!/bin/zsh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SOURCE_APP="$ROOT/dist/Xiaomi Voice Bridge.app"
TARGET_DIR="$HOME/Applications"
TARGET_APP="$TARGET_DIR/Xiaomi Voice Bridge.app"

"$ROOT/scripts/build-app.sh"
mkdir -p "$TARGET_DIR"
rm -rf "$TARGET_APP"
ditto "$SOURCE_APP" "$TARGET_APP"
codesign --verify --deep --strict "$TARGET_APP"

echo "已安装：$TARGET_APP"
echo "请在 系统设置 → 隐私与安全性 → 辅助功能 中允许 Xiaomi Voice Bridge。"
