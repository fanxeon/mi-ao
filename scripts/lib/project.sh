#!/bin/zsh

if [[ -z "${ROOT:-}" ]]; then
  echo "scripts/lib/project.sh 需要调用方先设置 ROOT" >&2
  return 1
fi

INFO_PLIST="$ROOT/Resources/Info.plist"

plist_value() {
  /usr/libexec/PlistBuddy -c "Print :$1" "$INFO_PLIST"
}

APP_NAME="$(plist_value CFBundleName)"
APP_BUNDLE_NAME="$APP_NAME.app"
BUNDLE_IDENTIFIER="$(plist_value CFBundleIdentifier)"
EXECUTABLE_NAME="$(plist_value CFBundleExecutable)"
PROJECT_VERSION="$(tr -d '[:space:]' < "$ROOT/VERSION")"

BUILD_BIN="$ROOT/.build/release/$EXECUTABLE_NAME"
BUILD_APP="$ROOT/dist/$APP_BUNDLE_NAME"
INSTALL_DIR="$HOME/Applications"
INSTALL_APP="$INSTALL_DIR/$APP_BUNDLE_NAME"
INSTALLED_BIN="$INSTALL_APP/Contents/MacOS/$EXECUTABLE_NAME"

# These two paths preserve the current prototype's data until the final product
# name is selected. Rename them once, together with the app and bundle ID.
MODEL_DIR="${VOICE_BRIDGE_MODEL_DIR:-$HOME/.cache/xiaomi-voice-bridge}"
MODEL_PATH="$MODEL_DIR/ggml-base.bin"
APP_DATA_DIR="${VOICE_BRIDGE_DATA_DIR:-$HOME/Library/Application Support/XiaomiVoiceBridge}"

SOURCE_SLUG="$(printf '%s' "$APP_NAME" | tr '[:upper:] ' '[:lower:]-' | tr -cd 'a-z0-9-')"
