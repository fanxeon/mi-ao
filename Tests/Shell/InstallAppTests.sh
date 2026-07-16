#!/bin/zsh
# Copyright (c) 2026 FanXeon@Poemcoder with Codex
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TEMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TEMP_ROOT"' EXIT

TEST_HOME="$TEMP_ROOT/home"
INSTALL_APP="$TEST_HOME/Applications/米遥.app"
CONTEXT_FILE="$TEST_HOME/Library/Application Support/mi-ao/install-context.plist"
mkdir -p "$TEST_HOME"

HOME="$TEST_HOME" "$ROOT/scripts/install-app.sh" >/dev/null
[[ -x "$INSTALL_APP/Contents/MacOS/mi-ao" ]]
[[ -f "$CONTEXT_FILE" ]]
codesign --verify --deep --strict "$INSTALL_APP"

MARKER="$INSTALL_APP/Contents/Resources/rollback-marker"
: > "$MARKER"
codesign --force --deep --sign - "$INSTALL_APP" >/dev/null
codesign --verify --deep --strict "$INSTALL_APP"

RUNTIME_LOCK="$TEST_HOME/Library/Application Support/mi-ao/runtime.lock"
mkdir -p "$RUNTIME_LOCK"
print -r -- "$$" > "$RUNTIME_LOCK/pid"
context_sha="$(/usr/bin/shasum -a 256 "$CONTEXT_FILE" | /usr/bin/awk '{print $1}')"
set +e
HOME="$TEST_HOME" "$ROOT/scripts/install-app.sh" >/dev/null 2>&1
running_exit_code=$?
set -e
[[ "$running_exit_code" == "1" ]]
[[ -f "$MARKER" ]]
[[ "$(/usr/bin/shasum -a 256 "$CONTEXT_FILE" | /usr/bin/awk '{print $1}')" == "$context_sha" ]]
rm -rf "$RUNTIME_LOCK"

FAIL_CODESIGN="$TEMP_ROOT/fail-final-codesign"
cat > "$FAIL_CODESIGN" <<'EOF'
#!/bin/zsh
set -euo pipefail
target="${argv[-1]}"
if [[ "$*" == *"--verify"* && "$target" == "$MI_AO_FAIL_FINAL_APP" ]]; then
  exit 17
fi
exec /usr/bin/codesign "$@"
EOF
chmod +x "$FAIL_CODESIGN"

set +e
HOME="$TEST_HOME" \
MI_AO_INSTALL_CODESIGN_BIN="$FAIL_CODESIGN" \
MI_AO_FAIL_FINAL_APP="$INSTALL_APP" \
  "$ROOT/scripts/install-app.sh" >/dev/null 2>&1
exit_code=$?
set -e

[[ "$exit_code" == "1" ]]
[[ -f "$MARKER" ]]
[[ -x "$INSTALL_APP/Contents/MacOS/mi-ao" ]]
codesign --verify --deep --strict "$INSTALL_APP"
[[ -z "$(find "$TEST_HOME/Applications" -maxdepth 1 -name '.*米遥.app.*' -print -quit)" ]]

echo "Atomic install and rollback shell tests: OK"
