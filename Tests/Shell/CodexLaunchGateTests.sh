#!/bin/zsh
# Copyright (c) 2026 FanXeon@Poemcoder with Codex
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TEMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TEMP_ROOT"' EXIT

APP_BIN="$TEMP_ROOT/Applications/米遥.app/Contents/MacOS/mi-ao"
GATE="$TEMP_ROOT/codex-gate"
GATE_LOG="$TEMP_ROOT/gate.log"
APP_LOG="$TEMP_ROOT/app.log"
mkdir -p "${APP_BIN:h}"

cat > "$GATE" <<'EOF'
#!/bin/zsh
print -r -- "${1:-}" >> "$MI_AO_TEST_GATE_LOG"
exit "${MI_AO_TEST_GATE_EXIT:-0}"
EOF

cat > "$APP_BIN" <<'EOF'
#!/bin/zsh
print -r -- "$*" >> "$MI_AO_TEST_APP_LOG"
EOF
chmod +x "$GATE" "$APP_BIN"

export HOME="$TEMP_ROOT"
export MI_AO_CODEX_ACCESSIBILITY_SCRIPT="$GATE"
export MI_AO_TEST_GATE_LOG="$GATE_LOG"
export MI_AO_TEST_APP_LOG="$APP_LOG"

MI_AO_TEST_GATE_EXIT=0 "$ROOT/scripts/run.sh" --no-buttons
[[ "$(cat "$GATE_LOG")" == "ensure" ]]
[[ "$(cat "$APP_LOG")" == "run --no-buttons" ]]

: > "$GATE_LOG"
: > "$APP_LOG"
set +e
MI_AO_TEST_GATE_EXIT=7 "$ROOT/scripts/run.sh" --no-buttons
exit_code=$?
set -e
[[ "$exit_code" == "7" ]]
[[ "$(cat "$GATE_LOG")" == "ensure" ]]
[[ ! -s "$APP_LOG" ]]

: > "$GATE_LOG"
MI_AO_TEST_GATE_EXIT=7 "$ROOT/scripts/run.sh" --no-submit --no-buttons
[[ ! -s "$GATE_LOG" ]]
[[ "$(cat "$APP_LOG")" == "run --no-submit --no-buttons" ]]

: > "$APP_LOG"
MI_AO_TEST_GATE_EXIT=7 "$ROOT/scripts/run.sh" --force-submit --no-buttons
[[ ! -s "$GATE_LOG" ]]
[[ "$(cat "$APP_LOG")" == "run --force-submit --no-buttons" ]]

echo "Codex launch gate shell tests: OK"
