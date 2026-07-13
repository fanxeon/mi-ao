#!/bin/zsh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$ROOT/scripts/lib/project.sh"

"$ROOT/scripts/build-app.sh"
mkdir -p "$INSTALL_DIR"
rm -rf "$INSTALL_APP"
ditto "$BUILD_APP" "$INSTALL_APP"
codesign --verify --deep --strict "$INSTALL_APP"

echo "已安装：$INSTALL_APP"
echo "请在 系统设置 → 隐私与安全性 → 辅助功能 中允许 $APP_NAME。"
