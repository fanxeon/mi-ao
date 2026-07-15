#!/bin/zsh
# Copyright (c) 2026 FanXeon@Poemcoder with Codex
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
source "$ROOT/scripts/lib/project.sh"
TEMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TEMP_ROOT"' EXIT

[[ -x "$ROOT/scripts/start.sh" ]]
[[ -x "$ROOT/scripts/stop.sh" ]]
[[ -x "$ROOT/scripts/codex-accessibility.sh" ]]
[[ -x "$ROOT/scripts/build-icon.sh" ]]
[[ -x "$ROOT/scripts/repair-runtime.sh" ]]
zsh -n \
  "$ROOT/scripts/authorize.sh" \
  "$ROOT/scripts/build-icon.sh" \
  "$ROOT/scripts/install-app.sh" \
  "$ROOT/scripts/run.sh" \
  "$ROOT/scripts/run-with-mapping.sh" \
  "$ROOT/scripts/repair-runtime.sh" \
  "$ROOT/scripts/start.sh" \
  "$ROOT/scripts/stop.sh" \
  "$ROOT/scripts/codex-accessibility.sh"

"$ROOT/scripts/build-app.sh" >/dev/null

BUILT_PROFILE="$BUILD_APP/Contents/Resources/HardwareProfiles/xiaomi-remote-2-pro-2671.plist"
BUILT_ICON="$BUILD_APP/Contents/Resources/AppIcon.icns"
BUILT_RUNTIME="$BUILD_APP/Contents/Resources/Runtime"
[[ -x "$BUILD_APP/Contents/MacOS/$EXECUTABLE_NAME" ]]
[[ -f "$BUILT_PROFILE" ]]
[[ -s "$BUILT_ICON" ]]
[[ -x "$BUILT_RUNTIME/scripts/start.sh" ]]
[[ -x "$BUILT_RUNTIME/scripts/stop.sh" ]]
[[ -x "$BUILT_RUNTIME/scripts/run-with-mapping.sh" ]]
[[ -x "$BUILT_RUNTIME/scripts/repair-runtime.sh" ]]
"$BUILD_APP/Contents/MacOS/$EXECUTABLE_NAME" --help | grep -q "setup"
MI_AO_APP_BUNDLE="$BUILD_APP" "$BUILT_RUNTIME/scripts/run.sh" --help | grep -q "setup"

RELOCATED_APP="$TEMP_ROOT/Relocated/米遥.app"
mkdir -p "${RELOCATED_APP:h}"
ditto "$BUILD_APP" "$RELOCATED_APP"
MI_AO_APP_BUNDLE="$RELOCATED_APP" \
  "$RELOCATED_APP/Contents/Resources/Runtime/scripts/run.sh" --help \
  | grep -q "setup"
codesign --verify --deep --strict "$RELOCATED_APP"

cmp "$ROOT/Resources/HardwareProfiles/xiaomi-remote-2-pro-2671.plist" "$BUILT_PROFILE"
cmp \
  "$ROOT/Resources/HardwareProfiles/xiaomi-remote-2-pro-2671.plist" \
  "$BUILT_RUNTIME/Resources/HardwareProfiles/xiaomi-remote-2-pro-2671.plist"
plutil -lint "$BUILD_APP/Contents/Info.plist" "$BUILT_PROFILE" >/dev/null
plutil -lint "$BUILT_RUNTIME/Resources/Info.plist" >/dev/null
[[ "$(plutil -extract CFBundleIconFile raw "$BUILD_APP/Contents/Info.plist")" == "AppIcon" ]]
/usr/bin/sips -g format "$BUILT_ICON" | grep -q "icns"
codesign --verify --deep --strict "$BUILD_APP"

echo "App bundle tests: OK"
