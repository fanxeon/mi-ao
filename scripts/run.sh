#!/bin/zsh
# Copyright (c) 2026 FanXeon@Poemcoder with Codex
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$ROOT/scripts/lib/project.sh"
CODEX_ACCESSIBILITY_SCRIPT="${MI_AO_CODEX_ACCESSIBILITY_SCRIPT:-$ROOT/scripts/codex-accessibility.sh}"

needs_codex_compatibility=true
for argument in "$@"; do
  case "$argument" in
    --help|-h|--no-submit|--force-submit)
      needs_codex_compatibility=false
      ;;
  esac
done

if $needs_codex_compatibility && [[ "${MI_AO_CODEX_ACCESSIBILITY_READY:-0}" != "1" ]]; then
  "$CODEX_ACCESSIBILITY_SCRIPT" ensure
fi

if [[ ! -x "$INSTALLED_BIN" ]]; then
  "$ROOT/scripts/install-app.sh"
fi

exec "$INSTALLED_BIN" run "$@"
