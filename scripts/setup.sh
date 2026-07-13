#!/bin/zsh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MODEL_DIR="$HOME/.cache/xiaomi-voice-bridge"
MODEL="$MODEL_DIR/ggml-base.bin"

if ! command -v whisper-cli >/dev/null 2>&1; then
  brew install whisper-cpp
fi

mkdir -p "$MODEL_DIR"
if [[ ! -f "$MODEL" ]]; then
  curl -fL --progress-bar \
    "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base.bin" \
    -o "$MODEL.part"
  mv "$MODEL.part" "$MODEL"
fi

cd "$ROOT"
"$ROOT/scripts/install-app.sh"

echo ""
echo "安装完成：$ROOT/.build/release/xiaomi-voice-bridge"
echo "App：$HOME/Applications/Xiaomi Voice Bridge.app"
echo "模型：$MODEL"
echo "下一步先运行："
echo "  $ROOT/.build/release/xiaomi-voice-bridge scan --scan-seconds 30"
