#!/bin/zsh
# Copyright (c) 2026 FanXeon@Poemcoder with Codex
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MAPPING_SCRIPT="$ROOT/scripts/remote-mapping.sh"
RUN_SCRIPT="${MI_AO_RUN_SCRIPT:-$ROOT/scripts/run.sh}"
BUTTON_CHECK_SCRIPT="${MI_AO_BUTTON_CHECK_SCRIPT:-$ROOT/scripts/check-buttons.sh}"
mapping_active=false
child_pid=""
resolved_profile=""

for argument in "$@"; do
  case "$argument" in
    --no-buttons|--help|-h)
      exec "$RUN_SCRIPT" "$@"
      ;;
  esac
done

stop_child() {
  [[ -n "$child_pid" ]] || return 0
  if kill -0 "$child_pid" 2>/dev/null; then
    kill -CONT "$child_pid" 2>/dev/null || true
    kill -TERM "$child_pid" 2>/dev/null || true
    for _ in {1..20}; do
      kill -0 "$child_pid" 2>/dev/null || break
      sleep 0.05
    done
    if kill -0 "$child_pid" 2>/dev/null; then
      kill -KILL "$child_pid" 2>/dev/null || true
    fi
  fi
  wait "$child_pid" 2>/dev/null || true
  child_pid=""
}

cleanup_session() {
  stop_child
  if $mapping_active; then
    mapping_active=false
    "$MAPPING_SCRIPT" restore || {
      echo "警告：自动恢复失败。请保持遥控器连接并运行：" >&2
      echo "  $MAPPING_SCRIPT restore" >&2
    }
  fi
  if [[ -n "$resolved_profile" ]]; then
    rm -f "$resolved_profile"
  fi
}

handle_signal() {
  local exit_code="$1"
  local signal_name="$2"
  if [[ "$signal_name" == "TSTP" ]]; then
    echo "检测到 Control+Z：米遥不进入挂起状态，正在安全退出并恢复映射。" >&2
  fi
  stop_child
  exit "$exit_code"
}

trap cleanup_session EXIT
trap 'handle_signal 130 INT' INT
trap 'handle_signal 143 TERM' TERM
trap 'handle_signal 129 HUP' HUP
trap 'handle_signal 148 TSTP' TSTP

resolved_profile="$(mktemp "${TMPDIR:-/tmp}/mi-ao-resolved-profile.XXXXXX")"
if ! "$BUTTON_CHECK_SCRIPT" --emit-profile "$resolved_profile" "$@"; then
  echo "错误：按键运行时未就绪，未修改系统映射。" >&2
  exit 1
fi
export MI_AO_HARDWARE_PROFILE="$resolved_profile"

mapping_active=true
if ! "$MAPPING_SCRIPT" apply; then
  mapping_active=false
  exit 1
fi

set +e
"$RUN_SCRIPT" "$@" &
child_pid=$!
wait "$child_pid"
result_code=$?
child_pid=""
set -e
exit "$result_code"
