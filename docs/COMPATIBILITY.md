<!-- Copyright (c) 2026 FanXeon@Poemcoder with Codex -->

# 兼容性矩阵 / Compatibility Matrix

[返回中文首页](../README.md) · [Back to English README](../README_EN.md)

米遥只把“有真实硬件证据”的设备标记为兼容。代码里存在某个协议分支，不等于某款遥控器已经验证。

MI-AO marks a device compatible only when reproducible evidence exists from real hardware. A protocol implementation in source code is not a device compatibility claim.

## 状态 / Status

- ✅ **End-to-end verified**：配对、GATT、按键、音频、转写和 Codex 提交全部通过。
- 🧪 **Implementation only**：有代码和 fixture，但缺少指定设备真机证据。
- 🧩 **Community evidence needed**：协议待识别或适配。

## 设备 / Devices

| 设备 / Device | 固件 / Firmware | macOS 设备名 | 协议 / Protocol | 控制 / Control | 转写 | Codex | 状态 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 小米蓝牙遥控器 2 Pro | 2671 | `小米蓝牙语音遥控器` | ATVV v1.0, ADPCM 16 kHz, 120 B | Hold-to-Talk, release `AUDIO_STOP` | ✅ 中文 | ✅ 真实提交 | ✅ End-to-end |
| 通用 ATVV v0.4 遥控器 | 未指定 | 未指定 | ATVV v0.4, ADPCM 8/16 kHz | 代码支持 | 代码支持 | 未实测 | 🧪 Implementation only |
| 其他 ATVV v1.0 遥控器 | 未指定 | 未指定 | ATVV v1.0, ADPCM 8/16 kHz | 代码支持 | 代码支持 | 未实测 | 🧪 Implementation only |

## 已验证的小米 2 Pro 证据

- 标准 ATVV Service：`AB5E0001-5A21-4F05-BC7D-AF01F617B664`；
- ATVV v1.0 capabilities：ADPCM 16 kHz、Hold-to-Talk、120 字节帧；
- 按住后收到 `AUDIO_START`，松手收到 `AUDIO_STOP`；
- 连续音频 notify 解码为 16 kHz WAV；
- 本地 Whisper 可正确识别真实中文语音；
- Codex Accessibility 树中找到唯一 `AXTextArea` 后完成真实提交；
- 验证日期：2026-07-14。

### 实体按键证据

- HID 设备身份：Vendor `0x2717` / Product `0x32B8`；
- `learn-buttons` 会按该 Vendor/Product 精确过滤设备，不记录 Mac 键盘事件；
- 返回键已在独立 20 秒窗口中重复采集，Keyboard Usage Page `0x07` / Usage `0xF1`，按下与松手均已观察；
- 返回键物理 Usage 已通过旧格式 `debug-buttons` 人工确认；硬件档案只记录 `back`，默认 `pointer` 预设将其映射为右击；正式运行前仍需生成带 `confirmed_calibration` 标记的新格式档案；
- `TV` 键已通过新格式 `confirmed_calibration` 确认：Keyboard Usage Page `0x07` / Usage `0x35`，按下与松手完整；
- 电源键已通过新格式 `confirmed_calibration` 确认：Keyboard Usage Page `0x07` / Usage `0x66`（Keyboard Power），按下与松手完整；
- 全键首轮扫描曾观察到 12/13 项事件，但存在操作提示错位，因此除返回键外暂不把首轮标签写入正式键码表；
- 方向键、确认、主页、菜单、音量和语音键的 HID 标签仍需分别完成单键复测后再进入动作映射层。

不公开真机 MAC、CoreBluetooth peripheral UUID 或设备序列信息。

## 贡献新设备 / Contribute a device

1. 在 macOS 中配对设备；
2. 运行脱敏扫描和定向采集；
3. 人工复核 `report.json` 和 `events.jsonl`；
4. 使用 [Device support request](../.github/ISSUE_TEMPLATE/device_support.yml) 模板提交 Issue；
5. 只在证据充足后增加新 transport / protocol adapter 和脱敏 fixture。

```bash
./scripts/capture.sh --scan-seconds 30
./scripts/capture.sh --identifier <UUID> --capture-seconds 60 --debug
```

Required evidence: model, firmware, macOS version, service and characteristic UUIDs, control behavior, audio frame shape, a non-private test phrase, and redacted logs. Never upload personal speech, MAC addresses, peripheral UUIDs, serial numbers, usernames, or secrets.
