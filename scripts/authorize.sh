#!/bin/zsh
# Copyright (c) 2026 FanXeon@Poemcoder with Codex
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$ROOT/scripts/lib/project.sh"

if [[ ! -x "$INSTALLED_BIN" ]]; then
  "$ROOT/scripts/install-app.sh"
fi

echo "正在打开米遥设置向导。请使用“米遥辅助功能”卡片完成授权；向导会自动刷新状态。"
open "$INSTALL_APP" --args setup
