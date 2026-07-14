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
echo "安装验证通过：$INSTALL_APP"
