#!/bin/zsh
# Copyright (c) 2026 FanXeon@Poemcoder with Codex
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
source "$ROOT/scripts/lib/environment.sh"

export MI_AO_APP_BUNDLE="/stale"
export MI_AO_FUTURE_INTERNAL_STATE="must-not-leak"
export MI_AO_RUNTIME_TOKEN="secret"
export VOICE_BRIDGE_MODEL_DIR="/tmp/model"

captured="$(mi_ao_run_external /usr/bin/env)"
[[ "$captured" != *"MI_AO_"* ]]
[[ "$captured" == *"VOICE_BRIDGE_MODEL_DIR=/tmp/model"* ]]

echo "Environment isolation shell tests: OK"
