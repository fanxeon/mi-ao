#!/bin/zsh
# Copyright (c) 2026 FanXeon@Poemcoder with Codex
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TEMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TEMP_ROOT"' EXIT

MODEL_DIR="$TEMP_ROOT/model"
MODEL_PATH="$MODEL_DIR/ggml-base.bin"
FAKE_WHISPER="$TEMP_ROOT/whisper-cli"
FAKE_CURL="$TEMP_ROOT/curl"
mkdir -p "$MODEL_DIR"
print -r -- "existing-model-must-survive" > "$MODEL_PATH"
original_sha="$(/usr/bin/shasum -a 256 "$MODEL_PATH" | /usr/bin/awk '{print $1}')"

cat > "$FAKE_WHISPER" <<'EOF'
#!/bin/zsh
exit 0
EOF

cat > "$FAKE_CURL" <<'EOF'
#!/bin/zsh
set -euo pipefail
output=""
while (( $# > 0 )); do
  if [[ "$1" == "-o" ]]; then
    shift
    output="$1"
  fi
  shift
done
[[ -n "$output" ]]
print -r -- "tampered-download" > "$output"
EOF
/bin/chmod 0755 "$FAKE_WHISPER" "$FAKE_CURL"

set +e
output="$(
  VOICE_BRIDGE_MODEL_DIR="$MODEL_DIR" \
  VOICE_BRIDGE_WHISPER="$FAKE_WHISPER" \
  MI_AO_REPAIR_CURL_BIN="$FAKE_CURL" \
    "$ROOT/scripts/repair-runtime.sh" 2>&1
)"
exit_code=$?
set -e

[[ "$exit_code" == "1" ]]
[[ "$output" == *"语音模型校验失败，未替换现有文件"* ]]
[[ "$(/usr/bin/shasum -a 256 "$MODEL_PATH" | /usr/bin/awk '{print $1}')" == "$original_sha" ]]
[[ -z "$(find "$MODEL_DIR" -maxdepth 1 -name 'ggml-base.bin.part.*' -print -quit)" ]]

echo "Repair runtime integrity shell tests: OK"
