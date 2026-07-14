#!/bin/zsh
# Copyright (c) 2026 FanXeon@Poemcoder with Codex
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$ROOT/scripts/lib/project.sh"

if [[ ! -x "$INSTALLED_BIN" ]]; then
  "$ROOT/scripts/install-app.sh"
fi

exec "$INSTALLED_BIN" authorize
