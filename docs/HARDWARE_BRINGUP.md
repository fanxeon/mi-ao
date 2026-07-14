# 小米蓝牙遥控器 2 Pro 真机 Bring-up

这份流程用于取得可复核的 BLE 证据。完成全部门槛前，只能说“发现设备”或“发现某个服务”，不能宣称“已经兼容”。

## 0. 环境确认

```bash
make preflight
./scripts/bridge.sh doctor
```

确认蓝牙权限已授权。`capture` 不需要 Codex 获得焦点，也不会提交文字。

## 1. 配对与扫描

让遥控器进入配对模式，并先在 macOS“系统设置 → 蓝牙”中完成配对。准确按键组合以包装说明书为准。

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

## 4. 端到端验收

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
