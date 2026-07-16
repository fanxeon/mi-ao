#!/bin/zsh
# Copyright (c) 2026 FanXeon@Poemcoder with Codex
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$ROOT/scripts/lib/environment.sh"
BUNDLE_ID="com.openai.codex"
ACCESSIBILITY_SWITCH="--force-renderer-accessibility"

usage() {
  cat <<'EOF'
用法：
  ./scripts/codex-accessibility.sh status
  ./scripts/codex-accessibility.sh ensure
  ./scripts/codex-accessibility.sh enable [--restart]
  ./scripts/codex-accessibility.sh disable [--restart]

enable 使用 Codex 自带的 Chromium 启动参数公开当前网页控件的辅助功能树。
该参数只影响本次 Codex 进程，不修改 Codex 偏好设置；Codex 退出后即失效。
EOF
}

codex_pid() {
  /usr/bin/lsappinfo info -only pid -app "$BUNDLE_ID" 2>/dev/null \
    | /usr/bin/sed -n 's/.*=\([0-9][0-9]*\).*/\1/p' \
    | /usr/bin/head -n 1
}

codex_running() {
  local pid
  pid="$(codex_pid)"
  [[ "$pid" == <-> ]] && kill -0 "$pid" 2>/dev/null
}

is_enabled() {
  local pid
  pid="$(codex_pid)"
  [[ -n "$pid" ]] || return 1
  /bin/ps -p "$pid" -ww -o command= | /usr/bin/grep -F -- "$ACCESSIBILITY_SWITCH" >/dev/null
}

print_status() {
  if ! codex_running; then
    print -r -- "Codex 辅助功能兼容：未运行"
  elif is_enabled; then
    print -r -- "Codex 辅助功能兼容：已开启（仅当前进程）"
  else
    print -r -- "Codex 辅助功能兼容：未开启"
  fi
}

quit_codex() {
  codex_running || return 0
  /usr/bin/osascript -e 'tell application id "com.openai.codex" to quit'
  for _ in {1..100}; do
    codex_running || return 0
    sleep 0.1
  done
  print -u2 -- "Codex 未在 10 秒内退出，已取消。"
  exit 1
}

launch_enabled() {
  mi_ao_run_external /usr/bin/open -b "$BUNDLE_ID" --args "$ACCESSIBILITY_SWITCH"
  for _ in {1..100}; do
    if codex_running; then
      if is_enabled; then
        print -r -- "Codex 辅助功能兼容：已开启（仅当前进程）"
        return 0
      fi
      print -u2 -- "Codex 已启动，但兼容参数未生效。"
      return 1
    fi
    sleep 0.1
  done
  print -u2 -- "Codex 未在 10 秒内启动。"
  return 1
}

mode="${1:-status}"
restart="${2:-}"
if [[ -n "$restart" && "$restart" != "--restart" ]]; then
  usage
  exit 2
fi

case "$mode" in
  status)
    print_status
    ;;
  ensure)
    if codex_running; then
      if is_enabled; then
        print -r -- "Codex 辅助功能兼容：已就绪"
      else
        print -u2 -- "Codex 正在运行，但本次进程未开启输入区兼容；米遥不会擅自重启正在工作的 Codex。"
        print -u2 -- "请在空闲时运行：$0 enable --restart"
        exit 3
      fi
    else
      print -r -- "Codex 未运行，正在使用本次进程兼容参数启动…"
      launch_enabled
    fi
    ;;
  enable|disable)
    if codex_running; then
      if [[ "$restart" != "--restart" ]]; then
        print -u2 -- "Codex 正在运行。请先退出 Codex，或显式运行：$0 $mode --restart"
        exit 1
      fi
      quit_codex
    fi
    if [[ "$mode" == "enable" ]]; then
      launch_enabled
      print -r -- "已使用 Codex 原生辅助功能参数启动；该设置只在本次进程有效。"
      print -r -- "提示：渲染完整辅助功能树可能略微增加 Codex 的资源占用。"
    else
      mi_ao_run_external /usr/bin/open -b "$BUNDLE_ID"
      print -r -- "已按原生方式启动 Codex；辅助功能兼容参数未启用。"
    fi
    ;;
  --help|-h|help)
    usage
    ;;
  *)
    usage
    exit 2
    ;;
esac
