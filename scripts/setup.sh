#!/bin/zsh
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
echo "下一步先运行："
echo "  $ROOT/scripts/bridge.sh scan --scan-seconds 30"
