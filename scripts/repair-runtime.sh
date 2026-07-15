#!/bin/zsh
# Copyright (c) 2026 FanXeon@Poemcoder with Codex
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$ROOT/scripts/lib/project.sh"

find_brew() {
  local candidate
  for candidate in "${HOMEBREW_BIN:-}" /opt/homebrew/bin/brew /usr/local/bin/brew; do
    [[ -n "$candidate" && -x "$candidate" ]] || continue
    print -r -- "$candidate"
    return 0
  done
  command -v brew 2>/dev/null || true
}

find_whisper() {
  local candidate
  for candidate in "${VOICE_BRIDGE_WHISPER:-}" /opt/homebrew/bin/whisper-cli /usr/local/bin/whisper-cli; do
    [[ -n "$candidate" && -x "$candidate" ]] || continue
    print -r -- "$candidate"
    return 0
  done
  command -v whisper-cli 2>/dev/null || true
}

whisper_bin="$(find_whisper)"
if [[ -z "$whisper_bin" ]]; then
  brew_bin="$(find_brew)"
  if [[ -z "$brew_bin" ]]; then
    echo "错误：未找到 Homebrew，请先安装 Homebrew 后重试。" >&2
    echo "https://brew.sh/" >&2
    exit 1
  fi
  "$brew_bin" install whisper-cpp
  whisper_bin="$(find_whisper)"
fi

[[ -n "$whisper_bin" ]] || {
  echo "错误：whisper-cpp 安装后仍未找到 whisper-cli。" >&2
  exit 1
}

mkdir -p "$MODEL_DIR"
chmod 0700 "$MODEL_DIR"
if [[ ! -s "$MODEL_PATH" || "$(stat -f%z "$MODEL_PATH" 2>/dev/null || echo 0)" -le 1000000 ]]; then
  temporary="$MODEL_PATH.part"
  rm -f "$temporary"
  /usr/bin/curl -fL --progress-bar \
    "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base.bin" \
    -o "$temporary"
  mv "$temporary" "$MODEL_PATH"
fi
chmod 0600 "$MODEL_PATH"

echo "本地语音引擎已就绪：$whisper_bin"
echo "语音模型已就绪：$MODEL_PATH"
