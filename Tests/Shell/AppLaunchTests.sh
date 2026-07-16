#!/bin/zsh
# Copyright (c) 2026 FanXeon@Poemcoder with Codex
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TEMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TEMP_ROOT"' EXIT
export HOME="$TEMP_ROOT/home"
export MI_AO_OPEN_BIN="$TEMP_ROOT/fake-open"
export MI_AO_OPEN_ARGUMENTS="$TEMP_ROOT/open-arguments"
export MI_AO_RUNTIME_LOG_FILE="$TEMP_ROOT/mi-ao.log"
INSTALL_APP="$HOME/Applications/米遥.app"
INSTALLED_BIN="$INSTALL_APP/Contents/MacOS/mi-ao"

mkdir -p "${INSTALLED_BIN:h}"
touch "$INSTALLED_BIN"
chmod 0755 "$INSTALLED_BIN"

cat > "$MI_AO_OPEN_BIN" <<'EOF'
#!/bin/zsh
print -rl -- "$@" > "$MI_AO_OPEN_ARGUMENTS"
EOF
chmod 0755 "$MI_AO_OPEN_BIN"

MI_AO_LAUNCH_VIA_OPEN=1 \
  "$ROOT/scripts/run.sh" --no-submit --no-buttons --name test

expected=(
  -n
  -W
  -g
  --stdout
  "$MI_AO_RUNTIME_LOG_FILE"
  --stderr
  "$MI_AO_RUNTIME_LOG_FILE"
  "$INSTALL_APP"
  --args
  run
  --no-submit
  --no-buttons
  --name
  test
)
actual=("${(@f)$(<"$MI_AO_OPEN_ARGUMENTS")}")
[[ "${(j:\n:)actual}" == "${(j:\n:)expected}" ]]

echo "App LaunchServices tests: OK"
