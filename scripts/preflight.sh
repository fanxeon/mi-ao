#!/bin/zsh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$ROOT/scripts/lib/project.sh"

failures=0

pass() { printf '✓ %s\n' "$1"; }
fail() { printf '✗ %s\n' "$1" >&2; failures=$((failures + 1)); }

[[ "$(uname -s)" == "Darwin" ]] && pass "macOS" || fail "仅支持 macOS"

if xcode-select -p >/dev/null 2>&1 && command -v swift >/dev/null 2>&1; then
  swift_version_output="$(swift --version 2>&1)"
  swift_version_line="$(printf '%s\n' "$swift_version_output" | sed -n '/Apple Swift version/p' | head -1)"
  swift_major="$(printf '%s\n' "$swift_version_line" | sed -n 's/.*Apple Swift version \([0-9][0-9]*\).*/\1/p')"
  if [[ -n "$swift_major" && "$swift_major" -ge 6 ]]; then
    pass "$swift_version_line"
  else
    fail "需要 Swift 6.0 或更高版本"
  fi
else
  fail "缺少 Xcode Command Line Tools"
fi

for command_name in curl codesign plutil; do
  command -v "$command_name" >/dev/null 2>&1 \
    && pass "$command_name" \
    || fail "缺少 $command_name"
done

if command -v whisper-cli >/dev/null 2>&1; then
  pass "whisper-cli 已安装"
elif command -v brew >/dev/null 2>&1; then
  pass "Homebrew 可用于安装 whisper-cpp"
else
  fail "缺少 whisper-cli 和 Homebrew"
fi

[[ -f "$INFO_PLIST" ]] && pass "App 元数据可读取：$APP_NAME" || fail "缺少 Resources/Info.plist"

if (( failures > 0 )); then
  echo "预检失败：$failures 项" >&2
  exit 1
fi

echo "预检通过"
