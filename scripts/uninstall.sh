#!/bin/zsh
# Copyright (c) 2026 FanXeon@Poemcoder with Codex
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$ROOT/scripts/lib/project.sh"

MAPPING_STATE_FILE="$APP_DATA_DIR/system-mapping/xiaomi-remote-2717-32b8.active"
if [[ -x "$ROOT/scripts/remote-mapping.sh" && -f "$MAPPING_STATE_FILE" ]]; then
  "$ROOT/scripts/remote-mapping.sh" restore
fi

remove_data=false
if [[ "${1:-}" == "--all-data" ]]; then
  remove_data=true
elif [[ $# -gt 0 ]]; then
  echo "用法：scripts/uninstall.sh [--all-data]" >&2
  exit 2
fi

if [[ -d "$INSTALL_APP" ]]; then
  rm -rf "$INSTALL_APP"
  echo "已移除 App：$INSTALL_APP"
else
  echo "App 未安装：$INSTALL_APP"
fi

if $remove_data; then
  rm -rf "$MODEL_DIR" "$APP_DATA_DIR"
  echo "已移除模型与本地录音数据"
else
  echo "已保留模型和录音。若要全部删除：scripts/uninstall.sh --all-data"
fi
