#!/bin/zsh
# Copyright (c) 2026 FanXeon@Poemcoder with Codex
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
source "$ROOT/scripts/lib/project.sh"

[[ -x "$ROOT/scripts/start.sh" ]]
[[ -x "$ROOT/scripts/stop.sh" ]]
[[ -x "$ROOT/scripts/codex-accessibility.sh" ]]
zsh -n \
  "$ROOT/scripts/run.sh" \
  "$ROOT/scripts/run-with-mapping.sh" \
  "$ROOT/scripts/start.sh" \
  "$ROOT/scripts/stop.sh" \
  "$ROOT/scripts/codex-accessibility.sh"

"$ROOT/scripts/build-app.sh" >/dev/null

BUILT_PROFILE="$BUILD_APP/Contents/Resources/HardwareProfiles/xiaomi-remote-2-pro-2671.plist"
[[ -x "$BUILD_APP/Contents/MacOS/$EXECUTABLE_NAME" ]]
[[ -f "$BUILT_PROFILE" ]]
"$BUILD_APP/Contents/MacOS/$EXECUTABLE_NAME" --help | grep -q "setup"
cmp "$ROOT/Resources/HardwareProfiles/xiaomi-remote-2-pro-2671.plist" "$BUILT_PROFILE"
plutil -lint "$BUILD_APP/Contents/Info.plist" "$BUILT_PROFILE" >/dev/null
codesign --verify --deep --strict "$BUILD_APP"

echo "App bundle tests: OK"
