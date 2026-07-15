#!/bin/zsh
# Copyright (c) 2026 FanXeon@Poemcoder with Codex
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$ROOT/scripts/lib/project.sh"

"$ROOT/scripts/build-app.sh"
mkdir -p "$INSTALL_DIR"
rm -rf "$INSTALL_APP"
ditto "$BUILD_APP" "$INSTALL_APP"
codesign --verify --deep --strict "$INSTALL_APP"

mkdir -p "$APP_DATA_DIR"
CONTEXT_FILE="$APP_DATA_DIR/install-context.plist"
CONTEXT_TEMP="$CONTEXT_FILE.tmp"
rm -f "$CONTEXT_TEMP"
plutil -create xml1 "$CONTEXT_TEMP"
plutil -insert repositoryRoot -string "$ROOT" "$CONTEXT_TEMP"
plutil -insert version -string "$PROJECT_VERSION" "$CONTEXT_TEMP"
plutil -insert installedAt -string "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$CONTEXT_TEMP"
mv "$CONTEXT_TEMP" "$CONTEXT_FILE"
chmod 0600 "$CONTEXT_FILE"

echo "已安装：$INSTALL_APP"
echo "已记录安全启动来源：$ROOT"
echo "下一步请打开 $APP_NAME 设置向导，按卡片完成系统授权与首次启动。"
echo "打开方式：open \"$INSTALL_APP\""
