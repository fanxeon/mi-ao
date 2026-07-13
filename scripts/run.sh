#!/bin/zsh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BIN="$HOME/Applications/Xiaomi Voice Bridge.app/Contents/MacOS/xiaomi-voice-bridge"

if [[ ! -x "$BIN" ]]; then
  "$ROOT/scripts/install-app.sh"
fi

exec "$BIN" run "$@"
