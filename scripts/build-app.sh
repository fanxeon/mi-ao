#!/bin/zsh
# Copyright (c) 2026 FanXeon@Poemcoder with Codex
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$ROOT/scripts/lib/project.sh"
CONTENTS="$BUILD_APP/Contents"

cd "$ROOT"
swift build -c release

rm -rf "$BUILD_APP"
mkdir -p "$CONTENTS/MacOS" "$CONTENTS/Resources"
cp "$BUILD_BIN" "$CONTENTS/MacOS/$EXECUTABLE_NAME"
cp "$ROOT/Resources/Info.plist" "$CONTENTS/Info.plist"
ditto "$ROOT/Resources/HardwareProfiles" "$CONTENTS/Resources/HardwareProfiles"

BUILD_NUMBER="$(git -C "$ROOT" rev-list --count HEAD 2>/dev/null || echo 1)"
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $PROJECT_VERSION" "$CONTENTS/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $BUILD_NUMBER" "$CONTENTS/Info.plist"

codesign --force --deep --sign - "$BUILD_APP"
codesign --verify --deep --strict "$BUILD_APP"
echo "$BUILD_APP"
