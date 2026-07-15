#!/bin/zsh
# Copyright (c) 2026 FanXeon@Poemcoder with Codex
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$ROOT/scripts/lib/project.sh"
RUNTIME_LOCK="$APP_DATA_DIR/runtime.lock"

owner_pid=""
[[ -f "$RUNTIME_LOCK/pid" ]] && owner_pid="$(<"$RUNTIME_LOCK/pid")"
if [[ "$owner_pid" != <-> ]] || ! kill -0 "$owner_pid" 2>/dev/null; then
  rm -rf "$RUNTIME_LOCK"
  echo "米遥当前没有运行。"
  "$ROOT/scripts/remote-mapping.sh" restore >/dev/null
  echo "遥控器系统映射已确认恢复。"
  exit 0
fi

kill -TERM "$owner_pid"
for _ in {1..700}; do
  kill -0 "$owner_pid" 2>/dev/null || break
  sleep 0.05
done

if kill -0 "$owner_pid" 2>/dev/null; then
  echo "警告：米遥未能在 35 秒内安全退出，正在强制停止进程 $owner_pid。" >&2
  kill -KILL "$owner_pid" 2>/dev/null || true
fi

"$ROOT/scripts/remote-mapping.sh" restore >/dev/null
rm -rf "$RUNTIME_LOCK"
echo "米遥已退出，遥控器系统映射已恢复。"
