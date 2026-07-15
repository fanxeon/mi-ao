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
echo "下一步：跟随米遥设置向导完成配对、权限、Codex 检查和首次启动。"
echo "命令行备用启动：$ROOT/scripts/start.sh"
echo "命令行安全停止：$ROOT/scripts/stop.sh"

if [[ "${MI_AO_SKIP_SETUP_GUIDE:-0}" != "1" ]]; then
  echo ""
  echo "正在打开米遥设置向导…"
  open "$INSTALL_APP" --args setup
fi
