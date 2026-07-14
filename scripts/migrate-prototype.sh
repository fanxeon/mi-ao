#!/bin/zsh
# Copyright (c) 2026 FanXeon@Poemcoder with Codex
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$ROOT/scripts/lib/project.sh"

OLD_APP="$HOME/Applications/Xiaomi Voice Bridge.app"
OLD_MODEL_DIR="$HOME/.cache/xiaomi-voice-bridge"
OLD_DATA_DIR="$HOME/Library/Application Support/XiaomiVoiceBridge"

migrate_directory() {
  local old_path="$1"
  local new_path="$2"
  local label="$3"

  if [[ ! -e "$old_path" ]]; then
    return
  fi

  if [[ -e "$new_path" ]]; then
    echo "$label 的新旧目录都存在，未覆盖："
    echo "  旧：$old_path"
    echo "  新：$new_path"
    return
  fi

  mkdir -p "$(dirname "$new_path")"
  mv "$old_path" "$new_path"
  echo "已迁移 $label：$new_path"
}

migrate_directory "$OLD_MODEL_DIR" "$MODEL_DIR" "Whisper 模型"
migrate_directory "$OLD_DATA_DIR" "$APP_DATA_DIR" "录音与转写数据"

if [[ -d "$OLD_APP" ]]; then
  if [[ -d "$INSTALL_APP" ]]; then
    rm -rf "$OLD_APP"
    echo "新版已安装，已移除旧原型 App：$OLD_APP"
  else
    echo "新版尚未安装，暂时保留旧原型 App：$OLD_APP"
  fi
fi
