#!/bin/zsh
# Copyright (c) 2026 FanXeon@Poemcoder with Codex
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

for forbidden_symbol in \
  'CGEvent\.tapCreate' \
  'CGEventTapCreate' \
  'cgSessionEventTap'
do
  if /usr/bin/grep -R -n -E "$forbidden_symbol" "$ROOT/Sources"; then
    echo "Keyboard isolation contract failed: global Quartz keyboard event taps are forbidden." >&2
    exit 1
  fi
done

echo "Keyboard isolation shell tests: OK"
