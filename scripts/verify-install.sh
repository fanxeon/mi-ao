#!/bin/zsh
# Copyright (c) 2026 FanXeon@Poemcoder with Codex
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$ROOT/scripts/lib/project.sh"

[[ -d "$INSTALL_APP" ]] || { echo "未安装：$INSTALL_APP" >&2; exit 1; }
[[ -x "$INSTALLED_BIN" ]] || { echo "缺少可执行文件：$INSTALLED_BIN" >&2; exit 1; }

codesign --verify --deep --strict "$INSTALL_APP"
installed_bundle_id="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$INSTALL_APP/Contents/Info.plist")"
[[ "$installed_bundle_id" == "$BUNDLE_IDENTIFIER" ]] \
  || { echo "Bundle ID 不一致：$installed_bundle_id" >&2; exit 1; }

"$INSTALLED_BIN" doctor
"$ROOT/scripts/remote-mapping.sh" status
runtime_lock="$APP_DATA_DIR/runtime.lock/pid"
runtime_pid=""
[[ -f "$runtime_lock" ]] && runtime_pid="$(<"$runtime_lock")"
if [[ "$runtime_pid" == <-> ]] && kill -0 "$runtime_pid" 2>/dev/null; then
  echo "运行状态：米遥正在后台运行（进程 $runtime_pid）"
else
  echo "运行状态：未启动；运行 $ROOT/scripts/start.sh"
fi
echo "安装验证通过：$INSTALL_APP"
