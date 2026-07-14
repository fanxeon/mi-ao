#!/bin/zsh
# Copyright (c) 2026 FanXeon@Poemcoder with Codex
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$ROOT/scripts/lib/project.sh"

"$ROOT/scripts/preflight.sh"
"$ROOT/scripts/migrate-prototype.sh"

if ! command -v whisper-cli >/dev/null 2>&1; then
  brew install whisper-cpp
fi

mkdir -p "$MODEL_DIR"
if [[ ! -f "$MODEL_PATH" ]]; then
  curl -fL --progress-bar \
    "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base.bin" \
    -o "$MODEL_PATH.part"
  mv "$MODEL_PATH.part" "$MODEL_PATH"
fi

cd "$ROOT"
"$ROOT/scripts/install-app.sh"
"$ROOT/scripts/migrate-prototype.sh"

echo ""
echo "安装完成：$BUILD_BIN"
echo "App：$INSTALL_APP"
echo "模型：$MODEL_PATH"
echo "下一步："
echo "  已验证的小米 2 Pro："
echo "  $ROOT/scripts/run.sh --name \"小米蓝牙语音遥控器\""
echo "  其他设备先采集脱敏证据："
echo "  $ROOT/scripts/capture.sh --scan-seconds 30"
