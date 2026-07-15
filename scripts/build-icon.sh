#!/bin/zsh
# Copyright (c) 2026 FanXeon@Poemcoder with Codex
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SOURCE="$ROOT/Resources/AppIcon/AppIcon-1024.png"
OUTPUT="${1:-$ROOT/dist/AppIcon.icns}"

if [[ ! -f "$SOURCE" ]]; then
  echo "缺少 App 图标源文件：$SOURCE" >&2
  exit 1
fi

WIDTH="$(/usr/bin/sips -g pixelWidth "$SOURCE" | awk '/pixelWidth/ { print $2 }')"
HEIGHT="$(/usr/bin/sips -g pixelHeight "$SOURCE" | awk '/pixelHeight/ { print $2 }')"
if [[ "$WIDTH" != "1024" || "$HEIGHT" != "1024" ]]; then
  echo "App 图标源文件必须是 1024×1024 PNG，当前为 ${WIDTH}×${HEIGHT}。" >&2
  exit 1
fi

TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/mi-ao-app-icon.XXXXXX")"
ICONSET="$TMP_ROOT/AppIcon.iconset"
trap 'rm -rf "$TMP_ROOT"' EXIT
mkdir -p "$ICONSET" "$(dirname "$OUTPUT")"

typeset -a ICON_TARGETS=(
  "16 icon_16x16.png"
  "32 icon_16x16@2x.png"
  "32 icon_32x32.png"
  "64 icon_32x32@2x.png"
  "128 icon_128x128.png"
  "256 icon_128x128@2x.png"
  "256 icon_256x256.png"
  "512 icon_256x256@2x.png"
  "512 icon_512x512.png"
  "1024 icon_512x512@2x.png"
)

for target in "${ICON_TARGETS[@]}"; do
  SIZE="${target%% *}"
  NAME="${target#* }"
  /usr/bin/sips -z "$SIZE" "$SIZE" "$SOURCE" --out "$ICONSET/$NAME" >/dev/null
done

/usr/bin/iconutil -c icns "$ICONSET" -o "$OUTPUT"
echo "$OUTPUT"
