#!/bin/zsh
# Copyright (c) 2026 FanXeon@Poemcoder with Codex
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
VERSION="$(tr -d '[:space:]' < "$ROOT/VERSION")"
PLIST_VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$ROOT/Resources/Info.plist")"

[[ "$VERSION" == <->.<->.<-> ]]
[[ "$PLIST_VERSION" == "$VERSION" ]]
grep -Fq '// swift-tools-version: 6.0' "$ROOT/Package.swift"
grep -Fq 'swiftLanguageModes: [.v6]' "$ROOT/Package.swift"
grep -Fq 'run: make check' "$ROOT/.github/workflows/ci.yml"
grep -Fq "V2 / $VERSION" "$ROOT/README.md"
grep -Fq "V2 / $VERSION" "$ROOT/README_EN.md"
grep -Fq "当前版本：\`$VERSION\`" "$ROOT/docs/DEVELOPMENT_STATUS.md"
grep -Fq 'Tests/Shell/EnvironmentIsolationTests.sh' "$ROOT/Makefile"
grep -Fq 'Tests/Shell/AppLaunchTests.sh' "$ROOT/Makefile"
grep -Fq 'Tests/Shell/RepairRuntimeTests.sh' "$ROOT/Makefile"

ROOT="$ROOT"
source "$ROOT/scripts/lib/project.sh"
[[ "$PROJECT_VERSION" == "$VERSION" ]]
[[ -f "$ROOT/Resources/WhisperModel.sha256" ]]
[[ ${#MODEL_SHA256} -eq 64 ]]
[[ "$MODEL_SHA256" != *[^0-9a-f]* ]]
[[ "$MODEL_SHA256" == "$(tr -d '[:space:]' < "$ROOT/Resources/WhisperModel.sha256")" ]]
grep -Fq 'verify_model_integrity' "$ROOT/scripts/repair-runtime.sh"
grep -Fq 'verify_model_integrity' "$ROOT/scripts/verify-install.sh"
grep -Fq '"$INSTALL_CODESIGN_BIN" --verify --deep --strict "$STAGED_APP"' "$ROOT/scripts/install-app.sh"

echo "Release contract tests: OK ($VERSION)"
