#!/bin/zsh
# Copyright (c) 2026 FanXeon@Poemcoder with Codex
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$ROOT/scripts/lib/project.sh"

runtime_pid_file="$APP_DATA_DIR/runtime.lock/pid"
runtime_pid=""
[[ -f "$runtime_pid_file" ]] && runtime_pid="$(<"$runtime_pid_file")"
if [[ "$runtime_pid" == <-> ]] && kill -0 "$runtime_pid" 2>/dev/null; then
  echo "检测到米遥正在运行，先安全退出并恢复遥控器…"
  "$ROOT/scripts/stop.sh"
fi

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
echo "  $ROOT/scripts/start.sh"
echo "  停止并恢复遥控器："
echo "  $ROOT/scripts/stop.sh"
echo "  仅使用语音、不修改按键映射："
echo "  $ROOT/scripts/run.sh --name \"小米蓝牙语音遥控器\" --no-buttons"
echo "  其他设备先采集脱敏证据："
echo "  $ROOT/scripts/capture.sh --scan-seconds 30"
