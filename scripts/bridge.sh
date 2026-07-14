#!/bin/zsh
# Copyright (c) 2026 FanXeon@Poemcoder with Codex
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$ROOT/scripts/lib/project.sh"

if [[ ! -x "$BUILD_BIN" ]]; then
  cd "$ROOT"
  swift build -c release
fi

exec "$BUILD_BIN" "$@"
