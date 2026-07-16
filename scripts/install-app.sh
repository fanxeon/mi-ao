#!/bin/zsh
# Copyright (c) 2026 FanXeon@Poemcoder with Codex
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$ROOT/scripts/lib/project.sh"
INSTALL_CODESIGN_BIN="${MI_AO_INSTALL_CODESIGN_BIN:-codesign}"
INSTALL_DITTO_BIN="${MI_AO_INSTALL_DITTO_BIN:-ditto}"

runtime_pid_file="$APP_DATA_DIR/runtime.lock/pid"
runtime_pid=""
[[ -f "$runtime_pid_file" ]] && runtime_pid="$(<"$runtime_pid_file")"
if [[ "$runtime_pid" == <-> ]] && kill -0 "$runtime_pid" 2>/dev/null; then
  echo "错误：米遥正在运行（进程 $runtime_pid）。请先安全退出，再安装更新。" >&2
  exit 1
fi

PREVIOUS_CODE_HASH=""
if [[ -d "$INSTALL_APP" ]]; then
  PREVIOUS_CODE_HASH="$("$INSTALL_CODESIGN_BIN" -dv --verbose=4 "$INSTALL_APP" 2>&1 | sed -n 's/^CDHash=//p' | head -n 1)"
fi

"$ROOT/scripts/build-app.sh"
mkdir -p "$INSTALL_DIR"
STAGED_APP="$INSTALL_DIR/.${APP_BUNDLE_NAME}.install.$$"
BACKUP_APP="$INSTALL_DIR/.${APP_BUNDLE_NAME}.backup.$$"
CONTEXT_FILE="$APP_DATA_DIR/install-context.plist"
CONTEXT_TEMP="$APP_DATA_DIR/.install-context.plist.$$"
had_previous=false
install_swapped=false
rollback_needed=false

rollback_install() {
  rm -rf "$STAGED_APP"
  rm -f "$CONTEXT_TEMP"
  if $rollback_needed; then
    if $install_swapped; then rm -rf "$INSTALL_APP"; fi
    if $had_previous && [[ -d "$BACKUP_APP" ]]; then
      mv "$BACKUP_APP" "$INSTALL_APP"
    fi
  else
    rm -rf "$BACKUP_APP"
  fi
}
trap rollback_install EXIT

rm -rf "$STAGED_APP" "$BACKUP_APP"
"$INSTALL_DITTO_BIN" "$BUILD_APP" "$STAGED_APP"
"$INSTALL_CODESIGN_BIN" --verify --deep --strict "$STAGED_APP"
CURRENT_CODE_HASH="$("$INSTALL_CODESIGN_BIN" -dv --verbose=4 "$STAGED_APP" 2>&1 | sed -n 's/^CDHash=//p' | head -n 1)"

mkdir -p "$APP_DATA_DIR"
RUNTIME_ROOT="$INSTALL_APP/Contents/Resources/Runtime"
rm -f "$CONTEXT_TEMP"
plutil -create xml1 "$CONTEXT_TEMP"
plutil -insert repositoryRoot -string "$ROOT" "$CONTEXT_TEMP"
plutil -insert runtimeRoot -string "$RUNTIME_ROOT" "$CONTEXT_TEMP"
plutil -insert version -string "$PROJECT_VERSION" "$CONTEXT_TEMP"
plutil -insert installedAt -string "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$CONTEXT_TEMP"
plutil -insert codeHash -string "$CURRENT_CODE_HASH" "$CONTEXT_TEMP"

if [[ -d "$INSTALL_APP" ]]; then
  mv "$INSTALL_APP" "$BACKUP_APP"
  had_previous=true
fi
rollback_needed=true

if ! mv "$STAGED_APP" "$INSTALL_APP"; then
  echo "错误：无法原子替换米遥 App；退出时会恢复旧版本。" >&2
  exit 1
fi
install_swapped=true

if ! "$INSTALL_CODESIGN_BIN" --verify --deep --strict "$INSTALL_APP"; then
  echo "错误：安装后签名校验失败；退出时会恢复旧版本。" >&2
  exit 1
fi

if ! mv "$CONTEXT_TEMP" "$CONTEXT_FILE"; then
  echo "错误：无法写入安装上下文；退出时会恢复旧版本。" >&2
  exit 1
fi
chmod 0600 "$CONTEXT_FILE"
rm -rf "$BACKUP_APP"
had_previous=false
install_swapped=false
rollback_needed=false
trap - EXIT

echo "已安装：$INSTALL_APP"
echo "已封装 App 内置运行组件：$RUNTIME_ROOT"
echo "已记录可选维护源码：$ROOT"
if [[ -n "$PREVIOUS_CODE_HASH" && "$PREVIOUS_CODE_HASH" != "$CURRENT_CODE_HASH" ]]; then
  echo "提示：本次源码更新改变了本地签名。macOS 辅助功能中的旧“米遥”授权需要移除并重新添加一次。"
fi
echo "下一步请打开 $APP_NAME 设置向导，按卡片完成系统授权与首次启动。"
echo "打开方式：open \"$INSTALL_APP\""
