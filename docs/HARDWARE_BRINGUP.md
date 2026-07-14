<!-- Copyright (c) 2026 FanXeon@Poemcoder with Codex -->

# 小米蓝牙遥控器 2 Pro 真机 Bring-up

这份流程用于取得可复核的 BLE 证据。完成全部门槛前，只能说“发现设备”或“发现某个服务”，不能宣称“已经兼容”。

## 0. 环境确认

```bash
make preflight
./scripts/bridge.sh doctor
```

确认蓝牙权限已授权。`capture` 不需要 Codex 获得焦点，也不会提交文字。

## 1. 配对与扫描

小米蓝牙遥控器 2 Pro 的已验证配对方式是：在 macOS“系统设置 → 蓝牙”中，同时长按遥控器的菜单键 + `HOME`，设备出现后点击“连接”，等待显示“已连接”。完整用户流程见 [配对与首次连接指南](PAIRING.md)。

其他遥控器的准确按键组合以设备说明书为准。

```bash
./scripts/capture.sh --scan-seconds 30
```

终端会显示真实的本机 peripheral UUID，便于下一步复制。落盘报告默认：

- UUID 与随机 session ID 一起哈希，生成仅在本次采集内稳定的 SHA-256 前缀假名；
- 设备广播名称写成 `(redacted)`；
- 不保存 manufacturer data；
- 文件权限为仅当前用户可读写。

已经连接并停止广播的遥控器，会通过 HID、Battery、Device Information 或 ATVV 服务被单独列为 `已连接` 设备。

如果为了本机排查确实需要原始身份，可显式增加：

```bash
--include-identifiers --include-device-names
```

不要把包含原始身份的报告直接提交到 Issue。

## 2. 目标设备采集

```bash
./scripts/capture.sh \
  --identifier <PERIPHERAL-UUID> \
  --capture-seconds 60 \
  --debug
```

连接后的 60 秒内依次执行：

1. 不按键等待 5 秒，取得空闲基线；
2. 短按一次语音键；
3. 按住语音键说“米遥测试一二三”，然后松开；
4. 再按一次语音键，观察第二次按键行为；
5. 开始一段语音后保持静音；
6. 若设备允许，最后关闭遥控器或主动断开，记录断连行为。

默认输出目录：

```text
~/Library/Application Support/mi-ao/captures/capture-<UTC>-<session>/
├── report.json
├── events.jsonl
└── audio-*.wav        # 仅 ATVV 成功解码时出现
```

`report.json` 保存设备、GATT 和统计摘要；`events.jsonl` 按时间记录读取、通知、已知协议写入和 payload。原始 payload 可能仍有隐私，分享前必须逐行复核。

## 3. 协议判定

### A. 标准 ATVV

满足以下证据才能进入现有 ATVV 链路：

- 存在 Service `AB5E0001-5A21-4F05-BC7D-AF01F617B664`；
- TX、RX audio、Control characteristic 与属性合理；
- `GET_CAPS` 获得可解析的 v0.4 或 v1.0 响应；
- 按键后出现 `START_SEARCH` / `AUDIO_START` 或符合 v0.4 的直接音频帧；
- 松手、第二次按键或 `AUDIO_STOP` 能结束会话；
- 至少一段 WAV 可听且时长、语速正常。

### B. 非标准协议

若没有 ATVV UUID，不要修改 `ATVVProtocol` 硬套数据。先从报告中建立：

- 哪个 characteristic 在按键时变化；
- 哪个 characteristic 持续产生高频通知；
- 帧长是否固定、是否存在 sequence；
- 开始、松手、静音和断连分别对应哪些字节；
- 是否必须先向某个 write characteristic 发送命令。

在证据明确后新增独立 transport/protocol adapter，并从真实采集数据制作脱敏 fixture 和自动化测试。

## 4. HID 实体按键学习

语音协议验证完成后，可独立采集遥控器作为 HID 键盘/Consumer Control 暴露的实体按钮：

```bash
./scripts/learn-buttons.sh --name "小米蓝牙语音遥控器"
```

学习器按 Vendor/Product 过滤目标设备，不接受主机键盘事件。若全键流程中出现漏按、延迟或标签错位，必须使用单键模式复测，不能手工猜测 Usage：

```bash
./scripts/learn-buttons.sh \
  --name "小米蓝牙语音遥控器" \
  --button back \
  --button-seconds 20
```

报告默认保存到 `~/Library/Application Support/mi-ao/button-profiles/`。小米 2 Pro 固件 2671 已取得以下独立证据：返回键 `0x07/0xF1`（旧格式确认），`TV` 键 `0x07/0x35`、电源键 `0x07/0x66`（新格式 `confirmed_calibration`），三项均观察到按下和松手。其他按钮必须分别复测后才能写入正式键码表。

`TV→F20`、`Power→F21` 的设备专属 `UserKeyMapping` 已完成可逆真机探针：映射启用时原始 IOHID Usage 不变，恢复后目标 service 的映射为空。该证据只验证中性化与恢复，不代表 Codex 启动动作已经验收。

六个必需按钮的新格式确认值为：上 `0x07/0x52`、下 `0x07/0x51`、左 `0x07/0x50`、右 `0x07/0x4F`、确认 `0x07/0x28`、返回 `0x07/0xF1`。方向上已通过运行期 HID 日志与系统坐标监测完成鼠标移动闭环；其余动作仍需分别验收。

建立可用于动作映射的正式档案时，必须改用人工确认调试模式：

```bash
./scripts/debug-buttons.sh --name "小米蓝牙语音遥控器"
```

该模式逐项显示 HID Usage 和当前预设动作，要求用户确认、重测、跳过或结束。调试器不合成米遥动作，但原始 HID 键仍可能被 macOS 或前台 App 处理，因此必须在安全窗口中校准。返回键 `0x07/0xF1` 的物理身份已通过旧格式报告真机确认；新动作运行时只接受带 `confirmed_calibration` 标记的新格式档案。硬件档案只保存 `back`，默认 `pointer` 预设再把它解释为 `pointer.right_click`。完整流程见 [按键预设与默认指针模式](BUTTON_PRESETS.md)。

## 5. 端到端验收

确认协议后运行：

```bash
./scripts/run.sh --identifier <PERIPHERAL-UUID> --debug
```

每项必须真实通过：

- 按住才录音，松手即结束；
- 短句、长句和连续多轮可用；
- 空语音不发送；
- Codex 未运行、无权限或焦点不是文本框时不误发；
- 断开后能重新发现；
- WAV、transcript 与 Codex 实际收到的文字一致。

### 已验证基线（2026-07-14）

小米蓝牙遥控器 2 Pro 固件 2671 已真实完成：按住语音键、松手停止、ADPCM 16 kHz 解码、本地 Whisper 转写“请回复米遥真实发送成功。”、发现并聚焦唯一 Codex `AXTextArea`、粘贴和回车发送。Codex 当前任务实际收到的文字与落盘 transcript 一致。
