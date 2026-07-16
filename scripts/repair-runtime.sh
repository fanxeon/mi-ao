#!/bin/zsh
# Copyright (c) 2026 FanXeon@Poemcoder with Codex
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$ROOT/scripts/lib/project.sh"
REPAIR_CURL_BIN="${MI_AO_REPAIR_CURL_BIN:-/usr/bin/curl}"

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
if ! verify_model_integrity; then
  temporary="$MODEL_PATH.part.$$"
  rm -f "$temporary"
  "$REPAIR_CURL_BIN" -fL --progress-bar \
    "$MODEL_URL" \
    -o "$temporary"
  downloaded_sha="$(/usr/bin/shasum -a 256 "$temporary" | /usr/bin/awk '{print $1}')"
  if [[ "$downloaded_sha" != "$MODEL_SHA256" ]]; then
    rm -f "$temporary"
    echo "错误：语音模型校验失败，未替换现有文件。" >&2
    echo "预期：$MODEL_SHA256" >&2
    echo "实际：$downloaded_sha" >&2
    exit 1
  fi
  mv "$temporary" "$MODEL_PATH"
fi
chmod 0600 "$MODEL_PATH"

echo "本地语音引擎已就绪：$whisper_bin"
echo "语音模型已就绪：$MODEL_PATH"
