#!/bin/zsh
# Copyright (c) 2026 FanXeon@Poemcoder with Codex
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$ROOT/scripts/lib/project.sh"
CONTENTS="$BUILD_APP/Contents"
RUNTIME_ROOT="$CONTENTS/Resources/Runtime"

cd "$ROOT"
swift build -c release

rm -rf "$BUILD_APP"
mkdir -p \
  "$CONTENTS/MacOS" \
  "$CONTENTS/Resources" \
  "$RUNTIME_ROOT/Resources" \
  "$RUNTIME_ROOT/scripts/lib"
cp "$BUILD_BIN" "$CONTENTS/MacOS/$EXECUTABLE_NAME"
cp "$ROOT/Resources/Info.plist" "$CONTENTS/Info.plist"
ditto "$ROOT/Resources/HardwareProfiles" "$CONTENTS/Resources/HardwareProfiles"
ditto "$ROOT/Resources/Brand" "$CONTENTS/Resources/Brand"
"$ROOT/scripts/build-icon.sh" "$CONTENTS/Resources/AppIcon.icns" >/dev/null

cp "$ROOT/Resources/Info.plist" "$RUNTIME_ROOT/Resources/Info.plist"
ditto "$ROOT/Resources/HardwareProfiles" "$RUNTIME_ROOT/Resources/HardwareProfiles"
cp "$ROOT/VERSION" "$RUNTIME_ROOT/VERSION"
for script in \
  start.sh \
  stop.sh \
  run.sh \
  run-with-mapping.sh \
  check-buttons.sh \
  remote-mapping.sh \
  codex-accessibility.sh \
  repair-runtime.sh; do
  cp "$ROOT/scripts/$script" "$RUNTIME_ROOT/scripts/$script"
done
cp "$ROOT/scripts/lib/project.sh" "$RUNTIME_ROOT/scripts/lib/project.sh"
chmod 0755 "$RUNTIME_ROOT/scripts"/*.sh

BUILD_NUMBER="$(git -C "$ROOT" rev-list --count HEAD 2>/dev/null || echo 1)"
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $PROJECT_VERSION" "$CONTENTS/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $BUILD_NUMBER" "$CONTENTS/Info.plist"

codesign --force --deep --sign - "$BUILD_APP"
codesign --verify --deep --strict "$BUILD_APP"
echo "$BUILD_APP"
