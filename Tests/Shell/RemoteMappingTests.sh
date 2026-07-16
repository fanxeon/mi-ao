#!/bin/zsh
# Copyright (c) 2026 FanXeon@Poemcoder with Codex
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TEMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TEMP_ROOT"' EXIT

export VOICE_BRIDGE_DATA_DIR="$TEMP_ROOT/data"
export FAKE_HID_STATE="$TEMP_ROOT/hid-state"
export HIDUTIL_BIN="$TEMP_ROOT/hidutil"

cat > "$HIDUTIL_BIN" <<'EOF'
#!/bin/zsh
set -euo pipefail

case "${1:-}" in
  list)
    echo '{"Product":"小米蓝牙语音遥控器","VendorID":10007,"ProductID":12984,"type":"service","Transport":"Bluetooth Low Energy"}'
    ;;
  property)
    if [[ " $* " == *" --get UserKeyMapping "* ]]; then
      echo 'RegistryID  Key                   Value'
      case "$(cat "$FAKE_HID_STATE")" in
        empty)
          echo '10001df64   UserKeyMapping   ('
          echo ')'
          ;;
        expected)
          cat <<'MAPPING'
10001df64   UserKeyMapping   (
  {
    HIDKeyboardModifierMappingDst = 30064771072;
    HIDKeyboardModifierMappingSrc = 30064771154;
  },
  {
    HIDKeyboardModifierMappingDst = 30064771072;
    HIDKeyboardModifierMappingSrc = 30064771153;
  },
  {
    HIDKeyboardModifierMappingDst = 30064771072;
    HIDKeyboardModifierMappingSrc = 30064771152;
  },
  {
    HIDKeyboardModifierMappingDst = 30064771072;
    HIDKeyboardModifierMappingSrc = 30064771151;
  },
  {
    HIDKeyboardModifierMappingDst = 30064771072;
    HIDKeyboardModifierMappingSrc = 30064771112;
  },
  {
    HIDKeyboardModifierMappingDst = 30064771072;
    HIDKeyboardModifierMappingSrc = 30064771313;
  },
  {
    HIDKeyboardModifierMappingDst = 30064771072;
    HIDKeyboardModifierMappingSrc = 30064771146;
  },
  {
    HIDKeyboardModifierMappingDst = 30064771072;
    HIDKeyboardModifierMappingSrc = 30064771125;
  },
  {
    HIDKeyboardModifierMappingDst = 30064771072;
    HIDKeyboardModifierMappingSrc = 30064771174;
  },
  {
    HIDKeyboardModifierMappingDst = 30064771072;
    HIDKeyboardModifierMappingSrc = 30064771134;
  },
  {
    HIDKeyboardModifierMappingDst = 30064771072;
    HIDKeyboardModifierMappingSrc = 30064771200;
  },
  {
    HIDKeyboardModifierMappingDst = 30064771072;
    HIDKeyboardModifierMappingSrc = 30064771201;
  }
)
MAPPING
          ;;
        v3)
          cat <<'MAPPING'
10001df64   UserKeyMapping   (
  {
    HIDKeyboardModifierMappingDst = 30064771072;
    HIDKeyboardModifierMappingSrc = 30064771154;
  },
  {
    HIDKeyboardModifierMappingDst = 30064771072;
    HIDKeyboardModifierMappingSrc = 30064771153;
  },
  {
    HIDKeyboardModifierMappingDst = 30064771072;
    HIDKeyboardModifierMappingSrc = 30064771152;
  },
  {
    HIDKeyboardModifierMappingDst = 30064771072;
    HIDKeyboardModifierMappingSrc = 30064771151;
  },
  {
    HIDKeyboardModifierMappingDst = 30064771072;
    HIDKeyboardModifierMappingSrc = 30064771112;
  },
  {
    HIDKeyboardModifierMappingDst = 30064771072;
    HIDKeyboardModifierMappingSrc = 30064771313;
  },
  {
    HIDKeyboardModifierMappingDst = 30064771072;
    HIDKeyboardModifierMappingSrc = 30064771146;
  },
  {
    HIDKeyboardModifierMappingDst = 30064771072;
    HIDKeyboardModifierMappingSrc = 30064771125;
  },
  {
    HIDKeyboardModifierMappingDst = 30064771072;
    HIDKeyboardModifierMappingSrc = 30064771174;
  },
  {
    HIDKeyboardModifierMappingDst = 30064771072;
    HIDKeyboardModifierMappingSrc = 30064771134;
  }
)
MAPPING
          ;;
        v2)
          cat <<'MAPPING'
10001df64   UserKeyMapping   (
  {
    HIDKeyboardModifierMappingDst = 30064771072;
    HIDKeyboardModifierMappingSrc = 30064771154;
  },
  {
    HIDKeyboardModifierMappingDst = 30064771072;
    HIDKeyboardModifierMappingSrc = 30064771153;
  },
  {
    HIDKeyboardModifierMappingDst = 30064771072;
    HIDKeyboardModifierMappingSrc = 30064771152;
  },
  {
    HIDKeyboardModifierMappingDst = 30064771072;
    HIDKeyboardModifierMappingSrc = 30064771151;
  },
  {
    HIDKeyboardModifierMappingDst = 30064771072;
    HIDKeyboardModifierMappingSrc = 30064771112;
  },
  {
    HIDKeyboardModifierMappingDst = 30064771072;
    HIDKeyboardModifierMappingSrc = 30064771313;
  },
  {
    HIDKeyboardModifierMappingDst = 30064771072;
    HIDKeyboardModifierMappingSrc = 30064771125;
  },
  {
    HIDKeyboardModifierMappingDst = 30064771072;
    HIDKeyboardModifierMappingSrc = 30064771174;
  }
)
MAPPING
          ;;
        legacy)
          cat <<'MAPPING'
10001df64   UserKeyMapping   (
  {
    HIDKeyboardModifierMappingDst = 30064771183;
    HIDKeyboardModifierMappingSrc = 30064771125;
  },
  {
    HIDKeyboardModifierMappingDst = 30064771184;
    HIDKeyboardModifierMappingSrc = 30064771174;
  }
)
MAPPING
          ;;
        foreign)
          cat <<'MAPPING'
10001df64   UserKeyMapping   (
  {
    HIDKeyboardModifierMappingDst = 30064771180;
    HIDKeyboardModifierMappingSrc = 30064771125;
  }
)
MAPPING
          ;;
      esac
    elif [[ " $* " == *' --set '* ]]; then
      if [[ "$*" == *'"UserKeyMapping":[]'* ]]; then
        echo empty > "$FAKE_HID_STATE"
      else
        echo expected > "$FAKE_HID_STATE"
      fi
    else
      echo "unexpected fake hidutil arguments: $*" >&2
      exit 2
    fi
    ;;
  *)
    echo "unexpected fake hidutil command: $*" >&2
    exit 2
    ;;
esac
EOF
chmod +x "$HIDUTIL_BIN"

echo empty > "$FAKE_HID_STATE"
mapping_status_output="$("$ROOT/scripts/remote-mapping.sh" status)"
grep -q '映射：原始状态（空）' <<< "$mapping_status_output"
"$ROOT/scripts/remote-mapping.sh" apply >/dev/null
[[ "$(cat "$FAKE_HID_STATE")" == "expected" ]]
[[ -f "$VOICE_BRIDGE_DATA_DIR/system-mapping/xiaomi-remote-2717-32b8.active" ]]
"$ROOT/scripts/remote-mapping.sh" apply >/dev/null
"$ROOT/scripts/remote-mapping.sh" restore >/dev/null
[[ "$(cat "$FAKE_HID_STATE")" == "empty" ]]
[[ ! -f "$VOICE_BRIDGE_DATA_DIR/system-mapping/xiaomi-remote-2717-32b8.active" ]]

echo expected > "$FAKE_HID_STATE"
mkdir -p "$VOICE_BRIDGE_DATA_DIR/system-mapping"
cat > "$VOICE_BRIDGE_DATA_DIR/system-mapping/xiaomi-remote-2717-32b8.active" <<'EOF'
owner=mi-ao
baseline=empty
vendor_id=0x2717
product_id=0x32b8
profile=custom-no-event-v4
up=0x700000052->0x700000000
down=0x700000051->0x700000000
left=0x700000050->0x700000000
right=0x70000004f->0x700000000
center=0x700000028->0x700000000
back=0x7000000f1->0x700000000
home=0x70000004a->0x700000000
tv=0x700000035->0x700000000
power=0x700000066->0x700000000
voice=0x70000003e->0x700000000
volume_up=0x700000080->0x700000000
volume_down=0x700000081->0x700000000
EOF
"$ROOT/scripts/remote-mapping.sh" apply >/dev/null
grep -q '^profile=xiaomi-remote-2-pro-2671$' \
  "$VOICE_BRIDGE_DATA_DIR/system-mapping/xiaomi-remote-2717-32b8.active"
grep -q '^dpad_up=0x700000052->0x700000000$' \
  "$VOICE_BRIDGE_DATA_DIR/system-mapping/xiaomi-remote-2717-32b8.active"
"$ROOT/scripts/remote-mapping.sh" restore >/dev/null

echo expected > "$FAKE_HID_STATE"
if "$ROOT/scripts/remote-mapping.sh" apply >/dev/null 2>&1; then
  echo "expected apply to reject an orphaned MI-AO mapping" >&2
  exit 1
fi
"$ROOT/scripts/remote-mapping.sh" restore --force >/dev/null
[[ "$(cat "$FAKE_HID_STATE")" == "empty" ]]

echo expected > "$FAKE_HID_STATE"
mkdir -p "$VOICE_BRIDGE_DATA_DIR/system-mapping"
echo 'owner=someone-else' \
  > "$VOICE_BRIDGE_DATA_DIR/system-mapping/xiaomi-remote-2717-32b8.active"
if "$ROOT/scripts/remote-mapping.sh" restore >/dev/null 2>&1; then
  echo "expected restore to reject an invalid ownership file" >&2
  exit 1
fi
[[ "$(cat "$FAKE_HID_STATE")" == "expected" ]]
"$ROOT/scripts/remote-mapping.sh" restore --force >/dev/null

echo legacy > "$FAKE_HID_STATE"
mkdir -p "$VOICE_BRIDGE_DATA_DIR/system-mapping"
cat > "$VOICE_BRIDGE_DATA_DIR/system-mapping/xiaomi-remote-2717-32b8.active" <<'EOF'
owner=mi-ao
baseline=empty
vendor_id=0x2717
product_id=0x32b8
tv=0x700000035->0x70000006f
power=0x700000066->0x700000070
EOF
"$ROOT/scripts/remote-mapping.sh" apply >/dev/null
[[ "$(cat "$FAKE_HID_STATE")" == "expected" ]]
grep -q '^profile=xiaomi-remote-2-pro-2671$' \
  "$VOICE_BRIDGE_DATA_DIR/system-mapping/xiaomi-remote-2717-32b8.active"
"$ROOT/scripts/remote-mapping.sh" restore >/dev/null

echo v2 > "$FAKE_HID_STATE"
mkdir -p "$VOICE_BRIDGE_DATA_DIR/system-mapping"
cat > "$VOICE_BRIDGE_DATA_DIR/system-mapping/xiaomi-remote-2717-32b8.active" <<'EOF'
owner=mi-ao
baseline=empty
vendor_id=0x2717
product_id=0x32b8
profile=core-no-event-v2
up=0x700000052->0x700000000
down=0x700000051->0x700000000
left=0x700000050->0x700000000
right=0x70000004f->0x700000000
center=0x700000028->0x700000000
back=0x7000000f1->0x700000000
tv=0x700000035->0x700000000
power=0x700000066->0x700000000
EOF
"$ROOT/scripts/remote-mapping.sh" apply >/dev/null
[[ "$(cat "$FAKE_HID_STATE")" == "expected" ]]
grep -q '^profile=xiaomi-remote-2-pro-2671$' \
  "$VOICE_BRIDGE_DATA_DIR/system-mapping/xiaomi-remote-2717-32b8.active"
"$ROOT/scripts/remote-mapping.sh" restore >/dev/null

echo v3 > "$FAKE_HID_STATE"
mkdir -p "$VOICE_BRIDGE_DATA_DIR/system-mapping"
cat > "$VOICE_BRIDGE_DATA_DIR/system-mapping/xiaomi-remote-2717-32b8.active" <<'EOF'
owner=mi-ao
baseline=empty
vendor_id=0x2717
product_id=0x32b8
profile=custom-no-event-v3
up=0x700000052->0x700000000
down=0x700000051->0x700000000
left=0x700000050->0x700000000
right=0x70000004f->0x700000000
center=0x700000028->0x700000000
back=0x7000000f1->0x700000000
home=0x70000004a->0x700000000
tv=0x700000035->0x700000000
power=0x700000066->0x700000000
voice=0x70000003e->0x700000000
EOF
"$ROOT/scripts/remote-mapping.sh" apply >/dev/null
[[ "$(cat "$FAKE_HID_STATE")" == "expected" ]]
grep -q '^profile=xiaomi-remote-2-pro-2671$' \
  "$VOICE_BRIDGE_DATA_DIR/system-mapping/xiaomi-remote-2717-32b8.active"
grep -q '^volume_up=0x700000080->0x700000000$' \
  "$VOICE_BRIDGE_DATA_DIR/system-mapping/xiaomi-remote-2717-32b8.active"
grep -q '^volume_down=0x700000081->0x700000000$' \
  "$VOICE_BRIDGE_DATA_DIR/system-mapping/xiaomi-remote-2717-32b8.active"
"$ROOT/scripts/remote-mapping.sh" restore >/dev/null

echo legacy > "$FAKE_HID_STATE"
"$ROOT/scripts/remote-mapping.sh" restore --force >/dev/null
[[ "$(cat "$FAKE_HID_STATE")" == "empty" ]]

echo foreign > "$FAKE_HID_STATE"
if "$ROOT/scripts/remote-mapping.sh" apply >/dev/null 2>&1; then
  echo "expected apply to reject a foreign mapping" >&2
  exit 1
fi
[[ "$(cat "$FAKE_HID_STATE")" == "foreign" ]]

cat > "$TEMP_ROOT/runner" <<'EOF'
#!/bin/zsh
exit "${FAKE_RUN_EXIT:-0}"
EOF
chmod +x "$TEMP_ROOT/runner"

cat > "$TEMP_ROOT/checker" <<'EOF'
#!/bin/zsh
if [[ "${1:-}" == "--emit-profile" ]]; then
  cp "${MI_AO_TEST_ROOT}/Resources/HardwareProfiles/xiaomi-remote-2-pro-2671.plist" "$2"
fi
exit "${FAKE_CHECK_EXIT:-0}"
EOF
chmod +x "$TEMP_ROOT/checker"
export MI_AO_BUTTON_CHECK_SCRIPT="$TEMP_ROOT/checker"
export MI_AO_TEST_ROOT="$ROOT"

cat > "$TEMP_ROOT/codex-accessibility" <<'EOF'
#!/bin/zsh
[[ "${1:-}" == "ensure" ]]
exit "${FAKE_CODEX_EXIT:-0}"
EOF
chmod +x "$TEMP_ROOT/codex-accessibility"
export MI_AO_CODEX_ACCESSIBILITY_SCRIPT="$TEMP_ROOT/codex-accessibility"

echo empty > "$FAKE_HID_STATE"
set +e
FAKE_CODEX_EXIT=8 MI_AO_RUN_SCRIPT="$TEMP_ROOT/runner" \
  "$ROOT/scripts/run-with-mapping.sh" --name test >/dev/null 2>&1
wrapper_status=$?
set -e
[[ "$wrapper_status" == "8" ]]
[[ "$(cat "$FAKE_HID_STATE")" == "empty" ]]
[[ ! -d "$VOICE_BRIDGE_DATA_DIR/runtime.lock" ]]

FAKE_CODEX_EXIT=8 MI_AO_RUN_SCRIPT="$TEMP_ROOT/runner" \
  "$ROOT/scripts/run-with-mapping.sh" --no-submit --no-buttons >/dev/null

echo empty > "$FAKE_HID_STATE"
set +e
FAKE_CHECK_EXIT=9 MI_AO_RUN_SCRIPT="$TEMP_ROOT/runner" \
  "$ROOT/scripts/run-with-mapping.sh" --name test >/dev/null 2>&1
wrapper_status=$?
set -e
[[ "$wrapper_status" == "1" ]]
[[ "$(cat "$FAKE_HID_STATE")" == "empty" ]]
[[ ! -f "$VOICE_BRIDGE_DATA_DIR/system-mapping/xiaomi-remote-2717-32b8.active" ]]

echo empty > "$FAKE_HID_STATE"
set +e
FAKE_RUN_EXIT=7 MI_AO_RUN_SCRIPT="$TEMP_ROOT/runner" \
  "$ROOT/scripts/run-with-mapping.sh" --name test >/dev/null
wrapper_status=$?
set -e
[[ "$wrapper_status" == "7" ]]
[[ "$(cat "$FAKE_HID_STATE")" == "empty" ]]
[[ ! -f "$VOICE_BRIDGE_DATA_DIR/system-mapping/xiaomi-remote-2717-32b8.active" ]]

echo empty > "$FAKE_HID_STATE"
MI_AO_RUN_SCRIPT="$TEMP_ROOT/runner" \
  "$ROOT/scripts/run-with-mapping.sh" --no-buttons >/dev/null
[[ "$(cat "$FAKE_HID_STATE")" == "empty" ]]

cat > "$TEMP_ROOT/waiting-runner" <<'EOF'
#!/bin/zsh
trap 'exit 0' TERM INT HUP
while true; do sleep 1; done
EOF
chmod +x "$TEMP_ROOT/waiting-runner"

echo empty > "$FAKE_HID_STATE"
set +e
MI_AO_RUN_SCRIPT="$TEMP_ROOT/waiting-runner" \
  "$ROOT/scripts/run-with-mapping.sh" --name test >/dev/null 2>&1 &
wrapper_pid=$!
for _ in {1..50}; do
  [[ "$(cat "$FAKE_HID_STATE")" == "expected" ]] && break
  sleep 0.02
done
MI_AO_RUN_SCRIPT="$TEMP_ROOT/waiting-runner" \
  "$ROOT/scripts/run-with-mapping.sh" --name test >/dev/null 2>&1
duplicate_status=$?
[[ "$duplicate_status" == "1" ]]
runtime_pid="$(<"$VOICE_BRIDGE_DATA_DIR/runtime.lock/pid")"
[[ "$runtime_pid" != "$wrapper_pid" ]]
kill -0 "$runtime_pid"
kill -TSTP "$wrapper_pid"
wait "$wrapper_pid"
wrapper_status=$?
set -e
[[ "$wrapper_status" == "148" ]]
[[ "$(cat "$FAKE_HID_STATE")" == "empty" ]]
[[ ! -f "$VOICE_BRIDGE_DATA_DIR/system-mapping/xiaomi-remote-2717-32b8.active" ]]
[[ ! -d "$VOICE_BRIDGE_DATA_DIR/runtime.lock" ]]

cat > "$TEMP_ROOT/open-wait-runner" <<'EOF'
#!/bin/zsh
/bin/sh -c '
  trap "exit 0" TERM INT HUP
  printf "%s\n" "$$" > "$MI_AO_RUNTIME_LOCK/pid"
  while :; do sleep 1; done
' &
app_pid=$!
trap 'kill -TERM "$app_pid" 2>/dev/null || true; wait "$app_pid" 2>/dev/null || true; exit 0' TERM INT HUP
wait "$app_pid"
EOF
chmod +x "$TEMP_ROOT/open-wait-runner"

MI_AO_LAUNCH_VIA_OPEN=1 MI_AO_RUN_SCRIPT="$TEMP_ROOT/open-wait-runner" \
  "$ROOT/scripts/run-with-mapping.sh" --no-submit --no-buttons >/dev/null 2>&1 &
open_wrapper_pid=$!
open_runtime_pid=""
for _ in {1..100}; do
  [[ -f "$VOICE_BRIDGE_DATA_DIR/runtime.lock/pid" ]] \
    && open_runtime_pid="$(<"$VOICE_BRIDGE_DATA_DIR/runtime.lock/pid")"
  [[ "$open_runtime_pid" == <-> && "$open_runtime_pid" != "$open_wrapper_pid" ]] && break
  sleep 0.02
done
[[ "$open_runtime_pid" == <-> ]]
[[ "$open_runtime_pid" != "$open_wrapper_pid" ]]
kill -0 "$open_runtime_pid"
set +e
kill -TERM "$open_wrapper_pid"
wait "$open_wrapper_pid"
open_wrapper_status=$?
set -e
[[ "$open_wrapper_status" == "143" ]]
for _ in {1..100}; do
  kill -0 "$open_runtime_pid" 2>/dev/null || break
  sleep 0.02
done
if kill -0 "$open_runtime_pid" 2>/dev/null; then
  echo "LaunchServices runtime child remained alive after wrapper exit" >&2
  exit 1
fi
[[ ! -d "$VOICE_BRIDGE_DATA_DIR/runtime.lock" ]]

cat > "$TEMP_ROOT/background-runner" <<'EOF'
#!/bin/zsh
trap 'exit 0' TERM INT HUP
echo '桥接已就绪：测试后台实例'
while true; do sleep 1; done
EOF
chmod +x "$TEMP_ROOT/background-runner"

MI_AO_RUN_SCRIPT="$TEMP_ROOT/background-runner" \
  "$ROOT/scripts/start.sh" --no-buttons >/dev/null
background_pid="$(<"$VOICE_BRIDGE_DATA_DIR/runtime.lock/pid")"
kill -0 "$background_pid"
duplicate_start_output="$(
  MI_AO_RUN_SCRIPT="$TEMP_ROOT/background-runner" \
    "$ROOT/scripts/start.sh" --no-buttons
)"
grep -q '已经在运行' <<< "$duplicate_start_output"
"$ROOT/scripts/stop.sh" >/dev/null
[[ ! -d "$VOICE_BRIDGE_DATA_DIR/runtime.lock" ]]
[[ "$(cat "$FAKE_HID_STATE")" == "empty" ]]

echo "Remote mapping shell tests: OK"
