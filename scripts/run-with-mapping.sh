#!/bin/zsh
# Copyright (c) 2026 FanXeon@Poemcoder with Codex
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MAPPING_SCRIPT="$ROOT/scripts/remote-mapping.sh"
RUN_SCRIPT="${MI_AO_RUN_SCRIPT:-$ROOT/scripts/run.sh}"
mapping_active=false

for argument in "$@"; do
  case "$argument" in
    --no-buttons|--help|-h)
      exec "$RUN_SCRIPT" "$@"
      ;;
  esac
done

cleanup_mapping() {
  if $mapping_active; then
    mapping_active=false
    "$MAPPING_SCRIPT" restore || {
      echo "警告：自动恢复失败。请保持遥控器连接并运行：" >&2
      echo "  $MAPPING_SCRIPT restore" >&2
    }
  fi
}

trap cleanup_mapping EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
trap 'exit 129' HUP

mapping_active=true
if ! "$MAPPING_SCRIPT" apply; then
  mapping_active=false
  exit 1
fi

set +e
"$RUN_SCRIPT" "$@"
result_code=$?
set -e
exit "$result_code"
