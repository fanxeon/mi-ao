#!/bin/zsh
# Copyright (c) 2026 FanXeon@Poemcoder with Codex
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$ROOT/scripts/lib/project.sh"

HIDUTIL_BIN="${HIDUTIL_BIN:-/usr/bin/hidutil}"
MATCHING='{"VendorID":10007,"ProductID":12984,"Product":"小米蓝牙语音遥控器","Transport":"Bluetooth Low Energy"}'
MAPPING='{"UserKeyMapping":[{"HIDKeyboardModifierMappingSrc":0x700000035,"HIDKeyboardModifierMappingDst":0x70000006F},{"HIDKeyboardModifierMappingSrc":0x700000066,"HIDKeyboardModifierMappingDst":0x700000070}]}'
EMPTY_MAPPING='{"UserKeyMapping":[]}'
STATE_DIR="$APP_DATA_DIR/system-mapping"
STATE_FILE="$STATE_DIR/xiaomi-remote-2717-32b8.active"

TV_SOURCE_DECIMAL=30064771125
TV_DESTINATION_DECIMAL=30064771183
POWER_SOURCE_DECIMAL=30064771174
POWER_DESTINATION_DECIMAL=30064771184

usage() {
  cat <<'EOF'
用法：scripts/remote-mapping.sh <apply|restore|status>

  apply           只为小米蓝牙遥控器 2 Pro 应用 TV→F20、Power→F21
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
  source_count="$(grep -c 'HIDKeyboardModifierMappingSrc' <<< "$output" || true)"
  [[ "$source_count" == "2" ]] \
    && grep -q "HIDKeyboardModifierMappingSrc = $TV_SOURCE_DECIMAL" <<< "$output" \
    && grep -q "HIDKeyboardModifierMappingDst = $TV_DESTINATION_DECIMAL" <<< "$output" \
    && grep -q "HIDKeyboardModifierMappingSrc = $POWER_SOURCE_DECIMAL" <<< "$output" \
    && grep -q "HIDKeyboardModifierMappingDst = $POWER_DESTINATION_DECIMAL" <<< "$output"
}

write_state() {
  local temporary="$STATE_FILE.$$.tmp"
  umask 077
  mkdir -p "$STATE_DIR"
  printf '%s\n' \
    'owner=mi-ao' \
    'baseline=empty' \
    'vendor_id=0x2717' \
    'product_id=0x32b8' \
    'tv=0x700000035->0x70000006f' \
    'power=0x700000066->0x700000070' \
    > "$temporary"
  mv "$temporary" "$STATE_FILE"
}

state_is_owned() {
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
    echo "错误：发现与米遥相同但没有所有权状态文件的映射；为避免覆盖用户配置，已拒绝接管。" >&2
    echo "确认这是残留映射后运行：scripts/remote-mapping.sh restore --force" >&2
    exit 1
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
  echo "已启用设备专属中性映射：TV→F20，Power→F21。"
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
  if ! mapping_is_expected "$current"; then
    echo "错误：当前映射与米遥预期不一致；为避免删除用户配置，已拒绝恢复。" >&2
    exit 1
  fi
  if ! state_is_owned && [[ "$force" != "--force" ]]; then
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
  echo "设备：已连接（Vendor 0x2717 / Product 0x32B8）"
  if state_is_owned; then
    echo "米遥状态文件：有效"
  elif [[ -f "$STATE_FILE" ]]; then
    echo "米遥状态文件：无效（不会据此恢复）"
  else
    echo "米遥状态文件：不存在"
  fi
  if mapping_is_empty "$current"; then
    echo "映射：原始状态（空）"
  elif mapping_is_expected "$current"; then
    echo "映射：米遥中性映射（TV→F20，Power→F21）"
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
