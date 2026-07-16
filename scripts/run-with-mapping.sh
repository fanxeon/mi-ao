#!/bin/zsh
# Copyright (c) 2026 FanXeon@Poemcoder with Codex
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$ROOT/scripts/lib/project.sh"
MAPPING_SCRIPT="$ROOT/scripts/remote-mapping.sh"
RUN_SCRIPT="${MI_AO_RUN_SCRIPT:-$ROOT/scripts/run.sh}"
BUTTON_CHECK_SCRIPT="${MI_AO_BUTTON_CHECK_SCRIPT:-$ROOT/scripts/check-buttons.sh}"
CODEX_ACCESSIBILITY_SCRIPT="${MI_AO_CODEX_ACCESSIBILITY_SCRIPT:-$ROOT/scripts/codex-accessibility.sh}"
mapping_active=false
child_pid=""
launcher_pid=""
resolved_profile=""
runtime_lock="$APP_DATA_DIR/runtime.lock"
owns_runtime_lock=false
skip_mapping=false
skip_codex_compatibility=false
runtime_token="$$-$RANDOM-$(date +%s)"

for argument in "$@"; do
  case "$argument" in
    --help|-h)
      exec "$RUN_SCRIPT" "$@"
      ;;
    --no-buttons)
      skip_mapping=true
      ;;
    --no-submit)
      skip_codex_compatibility=true
      ;;
    --force-submit)
      skip_codex_compatibility=true
      ;;
  esac
done

if ! $skip_codex_compatibility; then
  "$CODEX_ACCESSIBILITY_SCRIPT" ensure
  export MI_AO_CODEX_ACCESSIBILITY_READY=1
fi

acquire_runtime_lock() {
  mkdir -p "$APP_DATA_DIR"
  if mkdir "$runtime_lock" 2>/dev/null; then
    owns_runtime_lock=true
    print -r -- "$$" > "$runtime_lock/pid"
    print -r -- "$runtime_token" > "$runtime_lock/token"
    return 0
  fi

  local owner_pid=""
  [[ -f "$runtime_lock/pid" ]] && owner_pid="$(<"$runtime_lock/pid")"
  if [[ "$owner_pid" == <-> ]] && kill -0 "$owner_pid" 2>/dev/null; then
    echo "错误：米遥已经在运行（进程 $owner_pid）。请使用菜单栏退出，或运行 scripts/stop.sh。" >&2
    return 1
  fi

  rm -rf "$runtime_lock"
  mkdir "$runtime_lock"
  owns_runtime_lock=true
  print -r -- "$$" > "$runtime_lock/pid"
  print -r -- "$runtime_token" > "$runtime_lock/token"
}

stop_child() {
  if [[ -z "$child_pid" && "${MI_AO_LAUNCH_VIA_OPEN:-0}" == "1" ]]; then
    local registered_pid=""
    local registered_token=""
    [[ -f "$runtime_lock/pid" ]] && registered_pid="$(<"$runtime_lock/pid")"
    [[ -f "$runtime_lock/token" ]] && registered_token="$(<"$runtime_lock/token")"
    if [[ "$registered_token" == "$runtime_token" && "$registered_pid" == <-> \
      && "$registered_pid" != "$$" ]] && kill -0 "$registered_pid" 2>/dev/null; then
      child_pid="$registered_pid"
    fi
  fi

  if [[ -n "$child_pid" ]]; then
    if kill -0 "$child_pid" 2>/dev/null; then
      kill -CONT "$child_pid" 2>/dev/null || true
      kill -TERM "$child_pid" 2>/dev/null || true
      for _ in {1..700}; do
        kill -0 "$child_pid" 2>/dev/null || break
        sleep 0.05
      done
      if kill -0 "$child_pid" 2>/dev/null; then
        kill -KILL "$child_pid" 2>/dev/null || true
      fi
    fi
    if [[ "$child_pid" == "$launcher_pid" ]]; then
      wait "$child_pid" 2>/dev/null || true
    fi
    child_pid=""
  fi

  if [[ -n "$launcher_pid" ]]; then
    for _ in {1..100}; do
      kill -0 "$launcher_pid" 2>/dev/null || break
      sleep 0.02
    done
    if kill -0 "$launcher_pid" 2>/dev/null; then
      kill -TERM "$launcher_pid" 2>/dev/null || true
    fi
    wait "$launcher_pid" 2>/dev/null || true
    launcher_pid=""
  fi
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
  if $owns_runtime_lock; then
    local stored_token=""
    [[ -f "$runtime_lock/token" ]] && stored_token="$(<"$runtime_lock/token")"
    if [[ "$stored_token" == "$runtime_token" ]]; then
      rm -rf "$runtime_lock"
    fi
    owns_runtime_lock=false
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

acquire_runtime_lock
export MI_AO_MAPPING_RESTORE_SCRIPT="$MAPPING_SCRIPT"
export MI_AO_RUNTIME_LOCK="$runtime_lock"
export MI_AO_RUNTIME_TOKEN="$runtime_token"

if ! $skip_mapping; then
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
fi

set +e
"$RUN_SCRIPT" "$@" &
launcher_pid=$!
if [[ "${MI_AO_LAUNCH_VIA_OPEN:-0}" == "1" ]]; then
  for _ in {1..200}; do
    candidate_pid=""
    [[ -f "$runtime_lock/pid" ]] && candidate_pid="$(<"$runtime_lock/pid")"
    if [[ "$candidate_pid" == <-> && "$candidate_pid" != "$$" ]] \
      && kill -0 "$candidate_pid" 2>/dev/null; then
      child_pid="$candidate_pid"
      break
    fi
    kill -0 "$launcher_pid" 2>/dev/null || break
    sleep 0.05
  done
  if [[ -z "$child_pid" ]]; then
    echo "错误：LaunchServices 未在 10 秒内启动米遥运行进程。" >&2
    kill -TERM "$launcher_pid" 2>/dev/null || true
    wait "$launcher_pid" 2>/dev/null || true
    result_code=1
    launcher_pid=""
  else
    while kill -0 "$child_pid" 2>/dev/null; do
      sleep 0.05
    done
    wait "$launcher_pid"
    result_code=$?
    launcher_pid=""
  fi
else
  child_pid="$launcher_pid"
  print -r -- "$child_pid" > "$runtime_lock/pid"
  wait "$child_pid"
  result_code=$?
  child_pid=""
  launcher_pid=""
fi
child_pid=""
set -e
exit "$result_code"
