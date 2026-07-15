#!/bin/zsh
# Copyright (c) 2026 FanXeon@Poemcoder with Codex
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$ROOT/scripts/lib/project.sh"

HIDUTIL_BIN="${HIDUTIL_BIN:-/usr/bin/hidutil}"
PLIST_BUDDY="${PLIST_BUDDY:-/usr/libexec/PlistBuddy}"
HARDWARE_PROFILE="${MI_AO_HARDWARE_PROFILE:-$ROOT/Resources/HardwareProfiles/xiaomi-remote-2-pro-2671.plist}"

[[ -f "$HARDWARE_PROFILE" ]] || {
  echo "错误：找不到硬件档案：$HARDWARE_PROFILE" >&2
  exit 1
}

profile_value() {
  "$PLIST_BUDDY" -c "Print :$1" "$HARDWARE_PROFILE"
}

PROFILE_ID="$(profile_value id)"
PROFILE_VENDOR_ID="$(profile_value vendorID)"
PROFILE_PRODUCT_ID="$(profile_value productID)"
PROFILE_PRODUCT_NAME="$(profile_value productName)"
PROFILE_TRANSPORT="$(profile_value transport)"
PROFILE_STATE_FILE="$(profile_value stateFile)"
PROFILE_VENDOR_HEX="$(printf '0x%x' "$PROFILE_VENDOR_ID")"
PROFILE_PRODUCT_HEX="$(printf '0x%x' "$PROFILE_PRODUCT_ID")"

typeset -a PROFILE_BUTTON_NAMES PROFILE_SOURCE_DECIMALS INTERCEPTED_BUTTON_NAMES INTERCEPTED_SOURCE_DECIMALS
button_index=0
while button_name="$(profile_value "buttons:${button_index}:button" 2>/dev/null)"; do
  usage_page_value="$(profile_value "buttons:${button_index}:usagePage")"
  usage_value="$(profile_value "buttons:${button_index}:usage")"
  intercept="$(profile_value "buttons:${button_index}:intercept")"
  source_decimal=$((usage_page_value * 4294967296 + usage_value))
  PROFILE_BUTTON_NAMES+=("$button_name")
  PROFILE_SOURCE_DECIMALS+=("$source_decimal")
  if [[ "$intercept" == "true" ]]; then
    INTERCEPTED_BUTTON_NAMES+=("$button_name")
    INTERCEPTED_SOURCE_DECIMALS+=("$source_decimal")
  fi
  button_index=$((button_index + 1))
done

[[ "${#INTERCEPTED_SOURCE_DECIMALS[@]}" -gt 0 ]] || {
  echo "错误：硬件档案没有可接管按键：$HARDWARE_PROFILE" >&2
  exit 1
}

profile_source_for() {
  local wanted="$1"
  local index
  for ((index = 1; index <= ${#PROFILE_BUTTON_NAMES[@]}; index++)); do
    if [[ "${PROFILE_BUTTON_NAMES[$index]}" == "$wanted" ]]; then
      echo "${PROFILE_SOURCE_DECIMALS[$index]}"
      return 0
    fi
  done
  echo "错误：硬件档案缺少按键 $wanted" >&2
  exit 1
}

MATCHING="{\"VendorID\":$PROFILE_VENDOR_ID,\"ProductID\":$PROFILE_PRODUCT_ID,\"Product\":\"$PROFILE_PRODUCT_NAME\",\"Transport\":\"$PROFILE_TRANSPORT\"}"
mapping_entries=""
for source_decimal in "${INTERCEPTED_SOURCE_DECIMALS[@]}"; do
  source_hex="$(printf '0x%X' "$source_decimal")"
  mapping_entries+="{\"HIDKeyboardModifierMappingSrc\":$source_hex,\"HIDKeyboardModifierMappingDst\":0x700000000},"
done
MAPPING="{\"UserKeyMapping\":[${mapping_entries%,}]}"
EMPTY_MAPPING='{"UserKeyMapping":[]}'
STATE_DIR="$APP_DATA_DIR/system-mapping"
STATE_FILE="$STATE_DIR/$PROFILE_STATE_FILE"

NO_EVENT_DECIMAL=30064771072
UP_SOURCE_DECIMAL="$(profile_source_for dpad_up)"
DOWN_SOURCE_DECIMAL="$(profile_source_for dpad_down)"
LEFT_SOURCE_DECIMAL="$(profile_source_for dpad_left)"
RIGHT_SOURCE_DECIMAL="$(profile_source_for dpad_right)"
CENTER_SOURCE_DECIMAL="$(profile_source_for center)"
BACK_SOURCE_DECIMAL="$(profile_source_for back)"
HOME_SOURCE_DECIMAL="$(profile_source_for home)"
TV_SOURCE_DECIMAL="$(profile_source_for tv)"
POWER_SOURCE_DECIMAL="$(profile_source_for power)"
VOICE_SOURCE_DECIMAL="$(profile_source_for voice)"
VOLUME_UP_SOURCE_DECIMAL="$(profile_source_for volume_up)"
VOLUME_DOWN_SOURCE_DECIMAL="$(profile_source_for volume_down)"

LEGACY_TV_DESTINATION_DECIMAL=30064771183
LEGACY_POWER_DESTINATION_DECIMAL=30064771184

usage() {
  cat <<'EOF'
用法：scripts/remote-mapping.sh <apply|restore|status>

  apply           按内置硬件档案中性化米遥接管键；菜单保留 macOS 原生右键
  restore         恢复脚本自己应用的映射
  restore --force 在状态文件丢失但映射与米遥完全一致时强制恢复
  status          只读显示设备、所有权与当前映射状态
EOF
}

require_hidutil() {
  if [[ ! -x "$HIDUTIL_BIN" ]]; then
    echo "错误：找不到 hidutil：$HIDUTIL_BIN" >&2
    exit 1
  fi
}

device_connected() {
  "$HIDUTIL_BIN" list --ndjson --matching "$MATCHING" 2>/dev/null \
    | grep -q '"type":"service"'
}

read_mapping() {
  "$HIDUTIL_BIN" property --matching "$MATCHING" --get UserKeyMapping 2>&1
}

mapping_is_empty() {
  local output="$1"
  ! grep -q 'HIDKeyboardModifierMappingSrc' <<< "$output"
}

mapping_is_expected() {
  local output="$1"
  local source_count
  local destination_count
  source_count="$(grep -c 'HIDKeyboardModifierMappingSrc' <<< "$output" || true)"
  destination_count="$(grep -c "HIDKeyboardModifierMappingDst = $NO_EVENT_DECIMAL" <<< "$output" || true)"
  [[ "$source_count" == "${#INTERCEPTED_SOURCE_DECIMALS[@]}" ]] || return 1
  [[ "$destination_count" == "${#INTERCEPTED_SOURCE_DECIMALS[@]}" ]] || return 1
  local source_decimal
  for source_decimal in "${INTERCEPTED_SOURCE_DECIMALS[@]}"; do
    grep -q "HIDKeyboardModifierMappingSrc = $source_decimal" <<< "$output" || return 1
  done
}

mapping_is_v3() {
  local output="$1"
  local source_count
  local destination_count
  source_count="$(grep -c 'HIDKeyboardModifierMappingSrc' <<< "$output" || true)"
  destination_count="$(grep -c "HIDKeyboardModifierMappingDst = $NO_EVENT_DECIMAL" <<< "$output" || true)"
  [[ "$source_count" == "10" ]] \
    && [[ "$destination_count" == "10" ]] \
    && grep -q "HIDKeyboardModifierMappingSrc = $UP_SOURCE_DECIMAL" <<< "$output" \
    && grep -q "HIDKeyboardModifierMappingSrc = $DOWN_SOURCE_DECIMAL" <<< "$output" \
    && grep -q "HIDKeyboardModifierMappingSrc = $LEFT_SOURCE_DECIMAL" <<< "$output" \
    && grep -q "HIDKeyboardModifierMappingSrc = $RIGHT_SOURCE_DECIMAL" <<< "$output" \
    && grep -q "HIDKeyboardModifierMappingSrc = $CENTER_SOURCE_DECIMAL" <<< "$output" \
    && grep -q "HIDKeyboardModifierMappingSrc = $BACK_SOURCE_DECIMAL" <<< "$output" \
    && grep -q "HIDKeyboardModifierMappingSrc = $HOME_SOURCE_DECIMAL" <<< "$output" \
    && grep -q "HIDKeyboardModifierMappingSrc = $TV_SOURCE_DECIMAL" <<< "$output" \
    && grep -q "HIDKeyboardModifierMappingSrc = $POWER_SOURCE_DECIMAL" <<< "$output" \
    && grep -q "HIDKeyboardModifierMappingSrc = $VOICE_SOURCE_DECIMAL" <<< "$output"
}

mapping_is_v2() {
  local output="$1"
  local source_count
  local destination_count
  source_count="$(grep -c 'HIDKeyboardModifierMappingSrc' <<< "$output" || true)"
  destination_count="$(grep -c "HIDKeyboardModifierMappingDst = $NO_EVENT_DECIMAL" <<< "$output" || true)"
  [[ "$source_count" == "8" ]] \
    && [[ "$destination_count" == "8" ]] \
    && grep -q "HIDKeyboardModifierMappingSrc = $UP_SOURCE_DECIMAL" <<< "$output" \
    && grep -q "HIDKeyboardModifierMappingSrc = $DOWN_SOURCE_DECIMAL" <<< "$output" \
    && grep -q "HIDKeyboardModifierMappingSrc = $LEFT_SOURCE_DECIMAL" <<< "$output" \
    && grep -q "HIDKeyboardModifierMappingSrc = $RIGHT_SOURCE_DECIMAL" <<< "$output" \
    && grep -q "HIDKeyboardModifierMappingSrc = $CENTER_SOURCE_DECIMAL" <<< "$output" \
    && grep -q "HIDKeyboardModifierMappingSrc = $BACK_SOURCE_DECIMAL" <<< "$output" \
    && grep -q "HIDKeyboardModifierMappingSrc = $TV_SOURCE_DECIMAL" <<< "$output" \
    && grep -q "HIDKeyboardModifierMappingSrc = $POWER_SOURCE_DECIMAL" <<< "$output"
}

mapping_is_legacy() {
  local output="$1"
  local source_count
  source_count="$(grep -c 'HIDKeyboardModifierMappingSrc' <<< "$output" || true)"
  [[ "$source_count" == "2" ]] \
    && grep -q "HIDKeyboardModifierMappingSrc = $TV_SOURCE_DECIMAL" <<< "$output" \
    && grep -q "HIDKeyboardModifierMappingDst = $LEGACY_TV_DESTINATION_DECIMAL" <<< "$output" \
    && grep -q "HIDKeyboardModifierMappingSrc = $POWER_SOURCE_DECIMAL" <<< "$output" \
    && grep -q "HIDKeyboardModifierMappingDst = $LEGACY_POWER_DESTINATION_DECIMAL" <<< "$output"
}

write_state() {
  local temporary="$STATE_FILE.$$.tmp"
  local index
  umask 077
  mkdir -p "$STATE_DIR"
  printf '%s\n' \
    'owner=mi-ao' \
    'baseline=empty' \
    "vendor_id=$PROFILE_VENDOR_HEX" \
    "product_id=$PROFILE_PRODUCT_HEX" \
    "profile=$PROFILE_ID" \
    > "$temporary"
  for ((index = 1; index <= ${#INTERCEPTED_BUTTON_NAMES[@]}; index++)); do
    printf '%s=0x%x->0x700000000\n' \
      "${INTERCEPTED_BUTTON_NAMES[$index]}" \
      "${INTERCEPTED_SOURCE_DECIMALS[$index]}" \
      >> "$temporary"
  done
  mv "$temporary" "$STATE_FILE"
}

state_is_owned() {
  [[ -f "$STATE_FILE" ]] || return 1
  grep -qx 'owner=mi-ao' "$STATE_FILE" || return 1
  grep -qx 'baseline=empty' "$STATE_FILE" || return 1
  grep -qx "vendor_id=$PROFILE_VENDOR_HEX" "$STATE_FILE" || return 1
  grep -qx "product_id=$PROFILE_PRODUCT_HEX" "$STATE_FILE" || return 1
  grep -qx "profile=$PROFILE_ID" "$STATE_FILE" || return 1
  local index
  local expected
  for ((index = 1; index <= ${#INTERCEPTED_BUTTON_NAMES[@]}; index++)); do
    expected="${INTERCEPTED_BUTTON_NAMES[$index]}=$(printf '0x%x' "${INTERCEPTED_SOURCE_DECIMALS[$index]}")->0x700000000"
    grep -qx "$expected" "$STATE_FILE" || return 1
  done
}

v4_state_is_owned() {
  [[ -f "$STATE_FILE" ]] \
    && grep -qx 'owner=mi-ao' "$STATE_FILE" \
    && grep -qx 'baseline=empty' "$STATE_FILE" \
    && grep -qx 'vendor_id=0x2717' "$STATE_FILE" \
    && grep -qx 'product_id=0x32b8' "$STATE_FILE" \
    && grep -qx 'profile=custom-no-event-v4' "$STATE_FILE" \
    && grep -qx 'up=0x700000052->0x700000000' "$STATE_FILE" \
    && grep -qx 'down=0x700000051->0x700000000' "$STATE_FILE" \
    && grep -qx 'left=0x700000050->0x700000000' "$STATE_FILE" \
    && grep -qx 'right=0x70000004f->0x700000000' "$STATE_FILE" \
    && grep -qx 'center=0x700000028->0x700000000' "$STATE_FILE" \
    && grep -qx 'back=0x7000000f1->0x700000000' "$STATE_FILE" \
    && grep -qx 'home=0x70000004a->0x700000000' "$STATE_FILE" \
    && grep -qx 'tv=0x700000035->0x700000000' "$STATE_FILE" \
    && grep -qx 'power=0x700000066->0x700000000' "$STATE_FILE" \
    && grep -qx 'voice=0x70000003e->0x700000000' "$STATE_FILE" \
    && grep -qx 'volume_up=0x700000080->0x700000000' "$STATE_FILE" \
    && grep -qx 'volume_down=0x700000081->0x700000000' "$STATE_FILE"
}

v3_state_is_owned() {
  [[ -f "$STATE_FILE" ]] \
    && grep -qx 'owner=mi-ao' "$STATE_FILE" \
    && grep -qx 'baseline=empty' "$STATE_FILE" \
    && grep -qx 'vendor_id=0x2717' "$STATE_FILE" \
    && grep -qx 'product_id=0x32b8' "$STATE_FILE" \
    && grep -qx 'profile=custom-no-event-v3' "$STATE_FILE" \
    && grep -qx 'up=0x700000052->0x700000000' "$STATE_FILE" \
    && grep -qx 'down=0x700000051->0x700000000' "$STATE_FILE" \
    && grep -qx 'left=0x700000050->0x700000000' "$STATE_FILE" \
    && grep -qx 'right=0x70000004f->0x700000000' "$STATE_FILE" \
    && grep -qx 'center=0x700000028->0x700000000' "$STATE_FILE" \
    && grep -qx 'back=0x7000000f1->0x700000000' "$STATE_FILE" \
    && grep -qx 'home=0x70000004a->0x700000000' "$STATE_FILE" \
    && grep -qx 'tv=0x700000035->0x700000000' "$STATE_FILE" \
    && grep -qx 'power=0x700000066->0x700000000' "$STATE_FILE" \
    && grep -qx 'voice=0x70000003e->0x700000000' "$STATE_FILE"
}

v2_state_is_owned() {
  [[ -f "$STATE_FILE" ]] \
    && grep -qx 'owner=mi-ao' "$STATE_FILE" \
    && grep -qx 'baseline=empty' "$STATE_FILE" \
    && grep -qx 'vendor_id=0x2717' "$STATE_FILE" \
    && grep -qx 'product_id=0x32b8' "$STATE_FILE" \
    && grep -qx 'profile=core-no-event-v2' "$STATE_FILE" \
    && grep -qx 'up=0x700000052->0x700000000' "$STATE_FILE" \
    && grep -qx 'down=0x700000051->0x700000000' "$STATE_FILE" \
    && grep -qx 'left=0x700000050->0x700000000' "$STATE_FILE" \
    && grep -qx 'right=0x70000004f->0x700000000' "$STATE_FILE" \
    && grep -qx 'center=0x700000028->0x700000000' "$STATE_FILE" \
    && grep -qx 'back=0x7000000f1->0x700000000' "$STATE_FILE" \
    && grep -qx 'tv=0x700000035->0x700000000' "$STATE_FILE" \
    && grep -qx 'power=0x700000066->0x700000000' "$STATE_FILE"
}

legacy_state_is_owned() {
  [[ -f "$STATE_FILE" ]] \
    && grep -qx 'owner=mi-ao' "$STATE_FILE" \
    && grep -qx 'baseline=empty' "$STATE_FILE" \
    && grep -qx 'vendor_id=0x2717' "$STATE_FILE" \
    && grep -qx 'product_id=0x32b8' "$STATE_FILE" \
    && grep -qx 'tv=0x700000035->0x70000006f' "$STATE_FILE" \
    && grep -qx 'power=0x700000066->0x700000070' "$STATE_FILE"
}

apply_mapping() {
  if ! device_connected; then
    echo "错误：未找到已连接的小米蓝牙语音遥控器，未修改任何映射。" >&2
    exit 1
  fi

  local before
  before="$(read_mapping)"
  if mapping_is_expected "$before"; then
    if state_is_owned; then
      echo "遥控器中性映射已经由米遥启用。"
      return
    fi
    if v4_state_is_owned; then
      write_state
      echo "已把米遥 v4 所有权状态迁移到硬件档案 $PROFILE_ID。"
      return
    fi
    echo "错误：发现与米遥相同但没有所有权状态文件的映射；为避免覆盖用户配置，已拒绝接管。" >&2
    echo "确认这是残留映射后运行：scripts/remote-mapping.sh restore --force" >&2
    exit 1
  fi
  if mapping_is_v3 "$before"; then
    if ! v3_state_is_owned; then
      echo "错误：发现十键旧版映射但缺少对应所有权状态；已拒绝自动迁移。" >&2
      echo "确认这是米遥残留后运行：scripts/remote-mapping.sh restore --force" >&2
      exit 1
    fi
    "$HIDUTIL_BIN" property --matching "$MATCHING" --set "$EMPTY_MAPPING" >/dev/null
    rm -f "$STATE_FILE"
    before="$(read_mapping)"
  fi
  if mapping_is_v2 "$before"; then
    if ! v2_state_is_owned; then
      echo "错误：发现八键旧版映射但缺少对应所有权状态；已拒绝自动迁移。" >&2
      echo "确认这是米遥残留后运行：scripts/remote-mapping.sh restore --force" >&2
      exit 1
    fi
    "$HIDUTIL_BIN" property --matching "$MATCHING" --set "$EMPTY_MAPPING" >/dev/null
    rm -f "$STATE_FILE"
    before="$(read_mapping)"
  fi
  if mapping_is_legacy "$before"; then
    if ! legacy_state_is_owned; then
      echo "错误：发现旧版米遥映射但缺少对应所有权状态；已拒绝自动迁移。" >&2
      echo "确认这是米遥残留后运行：scripts/remote-mapping.sh restore --force" >&2
      exit 1
    fi
    "$HIDUTIL_BIN" property --matching "$MATCHING" --set "$EMPTY_MAPPING" >/dev/null
    rm -f "$STATE_FILE"
    before="$(read_mapping)"
  fi
  if ! mapping_is_empty "$before"; then
    echo "错误：这支遥控器已有其他 UserKeyMapping；米遥不会覆盖用户配置。" >&2
    exit 1
  fi

  "$HIDUTIL_BIN" property --matching "$MATCHING" --set "$MAPPING" >/dev/null
  local after
  after="$(read_mapping)"
  if ! mapping_is_expected "$after"; then
    "$HIDUTIL_BIN" property --matching "$MATCHING" --set "$EMPTY_MAPPING" >/dev/null || true
    echo "错误：映射写入后的回读验证失败，已尝试恢复为空。" >&2
    exit 1
  fi

  if ! write_state; then
    "$HIDUTIL_BIN" property --matching "$MATCHING" --set "$EMPTY_MAPPING" >/dev/null || true
    echo "错误：无法写入所有权状态文件，已尝试恢复为空。" >&2
    exit 1
  fi
  echo "已启用硬件档案 $PROFILE_ID：${#INTERCEPTED_SOURCE_DECIMALS[@]} 个米遥按键→No Event；菜单保持 macOS 原生右键。"
}

restore_mapping() {
  local force="${1:-}"
  if [[ "$force" != "" && "$force" != "--force" ]]; then
    usage >&2
    exit 2
  fi

  if ! device_connected; then
    rm -f "$STATE_FILE"
    echo "遥控器当前未连接；对应 HID 服务不存在，已清理米遥状态文件。"
    return
  fi

  local current
  current="$(read_mapping)"
  if mapping_is_empty "$current"; then
    rm -f "$STATE_FILE"
    echo "遥控器映射已经为空，无需恢复。"
    return
  fi
  if ! mapping_is_expected "$current" && ! mapping_is_v3 "$current" \
    && ! mapping_is_v2 "$current" \
    && ! mapping_is_legacy "$current"; then
    echo "错误：当前映射与米遥预期不一致；为避免删除用户配置，已拒绝恢复。" >&2
    exit 1
  fi
  if ! state_is_owned && ! v4_state_is_owned && ! v3_state_is_owned && ! v2_state_is_owned \
    && ! legacy_state_is_owned \
    && [[ "$force" != "--force" ]]; then
    echo "错误：缺少米遥所有权状态文件；未清除当前映射。" >&2
    echo "确认映射为米遥残留后运行：scripts/remote-mapping.sh restore --force" >&2
    exit 1
  fi

  "$HIDUTIL_BIN" property --matching "$MATCHING" --set "$EMPTY_MAPPING" >/dev/null
  local after
  after="$(read_mapping)"
  if ! mapping_is_empty "$after"; then
    echo "错误：恢复后的回读验证失败。请保持遥控器连接并重试。" >&2
    exit 1
  fi
  rm -f "$STATE_FILE"
  echo "已恢复遥控器原始映射。"
}

show_status() {
  if ! device_connected; then
    echo "设备：未连接"
    echo "米遥状态文件：$([[ -f "$STATE_FILE" ]] && echo 存在 || echo 不存在)"
    return
  fi

  local current
  current="$(read_mapping)"
  echo "设备：已连接（Vendor $PROFILE_VENDOR_HEX / Product $PROFILE_PRODUCT_HEX）"
  echo "硬件档案：$PROFILE_ID"
  if state_is_owned || v4_state_is_owned || v3_state_is_owned || v2_state_is_owned \
    || legacy_state_is_owned; then
    echo "米遥状态文件：有效"
  elif [[ -f "$STATE_FILE" ]]; then
    echo "米遥状态文件：无效（不会据此恢复）"
  else
    echo "米遥状态文件：不存在"
  fi
  if mapping_is_empty "$current"; then
    echo "映射：原始状态（空）"
  elif mapping_is_expected "$current"; then
    echo "映射：米遥中性映射（${#INTERCEPTED_SOURCE_DECIMALS[@]} 键→No Event；菜单为原生右键）"
  elif mapping_is_v3 "$current"; then
    echo "映射：米遥 v3 中性映射（十键→No Event；菜单/音量原生）"
  elif mapping_is_v2 "$current"; then
    echo "映射：米遥 v2 中性映射（八键→No Event）"
  elif mapping_is_legacy "$current"; then
    echo "映射：米遥旧版中性映射（TV→F20，Power→F21）"
  else
    echo "映射：检测到其他用户配置，米遥不会覆盖"
  fi
}

require_hidutil
case "${1:-}" in
  apply)
    [[ $# -eq 1 ]] || { usage >&2; exit 2; }
    apply_mapping
    ;;
  restore)
    [[ $# -le 2 ]] || { usage >&2; exit 2; }
    restore_mapping "${2:-}"
    ;;
  status)
    [[ $# -eq 1 ]] || { usage >&2; exit 2; }
    show_status
    ;;
  --help|-h|help)
    usage
    ;;
  *)
    usage >&2
    exit 2
    ;;
esac
