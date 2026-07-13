#!/bin/zsh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP="$ROOT/dist/Xiaomi Voice Bridge.app"
CONTENTS="$APP/Contents"

cd "$ROOT"
swift build -c release

rm -rf "$APP"
mkdir -p "$CONTENTS/MacOS" "$CONTENTS/Resources"
cp "$ROOT/.build/release/xiaomi-voice-bridge" "$CONTENTS/MacOS/xiaomi-voice-bridge"
cp "$ROOT/Resources/Info.plist" "$CONTENTS/Info.plist"

codesign --force --deep --sign - "$APP"
codesign --verify --deep --strict "$APP"
echo "$APP"
