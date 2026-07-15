#!/bin/zsh
# Copyright (c) 2026 FanXeon@Poemcoder with Codex
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$ROOT/scripts/lib/project.sh"
RUNTIME_LOCK="$APP_DATA_DIR/runtime.lock"
LOG_DIR="$APP_DATA_DIR/logs"
LOG_FILE="$LOG_DIR/mi-ao.log"

existing_pid=""
[[ -f "$RUNTIME_LOCK/pid" ]] && existing_pid="$(<"$RUNTIME_LOCK/pid")"
if [[ "$existing_pid" == <-> ]] && kill -0 "$existing_pid" 2>/dev/null; then
  echo "米遥已经在运行（进程 $existing_pid）。"
  echo "日志：$LOG_FILE"
  exit 0
fi

mkdir -p "$LOG_DIR"
: > "$LOG_FILE"

arguments=("$@")
if (( ${#arguments[@]} == 0 )); then
  arguments=(--name "小米蓝牙语音遥控器")
fi

nohup "$ROOT/scripts/run-with-mapping.sh" "${arguments[@]}" >> "$LOG_FILE" 2>&1 &
launcher_pid=$!
disown "$launcher_pid" 2>/dev/null || true

for _ in {1..100}; do
  if ! kill -0 "$launcher_pid" 2>/dev/null; then
    echo "米遥启动失败，最近日志：" >&2
    tail -20 "$LOG_FILE" >&2
    exit 1
  fi
  if grep -q "桥接已就绪" "$LOG_FILE"; then
    echo "米遥已启动，菜单栏可查看状态和安全退出。"
    echo "日志：$LOG_FILE"
    exit 0
  fi
  sleep 0.1
done

echo "米遥已在后台启动，仍在连接遥控器；请查看菜单栏状态。"
echo "日志：$LOG_FILE"
