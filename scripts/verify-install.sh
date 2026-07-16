#!/bin/zsh
# Copyright (c) 2026 FanXeon@Poemcoder with Codex
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$ROOT/scripts/lib/project.sh"

[[ -d "$INSTALL_APP" ]] || { echo "未安装：$INSTALL_APP" >&2; exit 1; }
[[ -x "$INSTALLED_BIN" ]] || { echo "缺少可执行文件：$INSTALLED_BIN" >&2; exit 1; }
verify_model_integrity \
  || { echo "语音模型完整性校验失败，请先执行 scripts/repair-runtime.sh" >&2; exit 1; }
echo "语音模型：SHA-256 已验证"

codesign --verify --deep --strict "$INSTALL_APP"
installed_bundle_id="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$INSTALL_APP/Contents/Info.plist")"
[[ "$installed_bundle_id" == "$BUNDLE_IDENTIFIER" ]] \
  || { echo "Bundle ID 不一致：$installed_bundle_id" >&2; exit 1; }

"$INSTALLED_BIN" doctor
"$ROOT/scripts/codex-accessibility.sh" status
"$ROOT/scripts/remote-mapping.sh" status

CONTEXT_FILE="$APP_DATA_DIR/install-context.plist"
if [[ ! -f "$CONTEXT_FILE" ]]; then
  echo "安装来源记录缺失：$CONTEXT_FILE" >&2
  exit 1
fi
plutil -extract repositoryRoot raw -o - "$CONTEXT_FILE" | grep -Fxq "$ROOT"
RUNTIME_ROOT="$INSTALL_APP/Contents/Resources/Runtime"
plutil -extract runtimeRoot raw -o - "$CONTEXT_FILE" | grep -Fxq "$RUNTIME_ROOT"
[[ -x "$RUNTIME_ROOT/scripts/start.sh" ]]
[[ -x "$RUNTIME_ROOT/scripts/repair-runtime.sh" ]]
[[ -x "$RUNTIME_ROOT/scripts/codex-accessibility.sh" ]]
echo "App 内置运行组件：已验证"
stored_code_hash="$(plutil -extract codeHash raw -o - "$CONTEXT_FILE")"
installed_code_hash="$(codesign -dv --verbose=4 "$INSTALL_APP" 2>&1 | sed -n 's/^CDHash=//p' | head -n 1)"
[[ "$stored_code_hash" == "$installed_code_hash" ]] \
  || { echo "安装签名指纹与设置向导记录不一致" >&2; exit 1; }
echo "安装签名指纹：已验证"
runtime_lock="$APP_DATA_DIR/runtime.lock/pid"
runtime_pid=""
[[ -f "$runtime_lock" ]] && runtime_pid="$(<"$runtime_lock")"
if [[ "$runtime_pid" == <-> ]] && kill -0 "$runtime_pid" 2>/dev/null; then
  echo "运行状态：米遥正在后台运行（进程 $runtime_pid）"
else
  echo "运行状态：未启动；打开 $INSTALL_APP 即可从设置向导启动"
fi
echo "安装验证通过：$INSTALL_APP"
