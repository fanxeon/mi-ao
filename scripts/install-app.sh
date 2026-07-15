#!/bin/zsh
# Copyright (c) 2026 FanXeon@Poemcoder with Codex
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$ROOT/scripts/lib/project.sh"

PREVIOUS_CODE_HASH=""
if [[ -d "$INSTALL_APP" ]]; then
  PREVIOUS_CODE_HASH="$(codesign -dv --verbose=4 "$INSTALL_APP" 2>&1 | sed -n 's/^CDHash=//p' | head -n 1)"
fi

"$ROOT/scripts/build-app.sh"
mkdir -p "$INSTALL_DIR"
rm -rf "$INSTALL_APP"
ditto "$BUILD_APP" "$INSTALL_APP"
codesign --verify --deep --strict "$INSTALL_APP"
CURRENT_CODE_HASH="$(codesign -dv --verbose=4 "$INSTALL_APP" 2>&1 | sed -n 's/^CDHash=//p' | head -n 1)"

mkdir -p "$APP_DATA_DIR"
CONTEXT_FILE="$APP_DATA_DIR/install-context.plist"
CONTEXT_TEMP="$CONTEXT_FILE.tmp"
rm -f "$CONTEXT_TEMP"
plutil -create xml1 "$CONTEXT_TEMP"
plutil -insert repositoryRoot -string "$ROOT" "$CONTEXT_TEMP"
plutil -insert version -string "$PROJECT_VERSION" "$CONTEXT_TEMP"
plutil -insert installedAt -string "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$CONTEXT_TEMP"
plutil -insert codeHash -string "$CURRENT_CODE_HASH" "$CONTEXT_TEMP"
mv "$CONTEXT_TEMP" "$CONTEXT_FILE"
chmod 0600 "$CONTEXT_FILE"

echo "已安装：$INSTALL_APP"
echo "已记录安全启动来源：$ROOT"
if [[ -n "$PREVIOUS_CODE_HASH" && "$PREVIOUS_CODE_HASH" != "$CURRENT_CODE_HASH" ]]; then
  echo "提示：本次源码更新改变了本地签名。macOS 辅助功能中的旧“米遥”授权需要移除并重新添加一次。"
fi
echo "下一步请打开 $APP_NAME 设置向导，按卡片完成系统授权与首次启动。"
echo "打开方式：open \"$INSTALL_APP\""
