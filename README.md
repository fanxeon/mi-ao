# 米遥 MI-AO

[English](README_EN.md) · 中文

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-macOS%2014%2B-black.svg)](Package.swift)
[![Swift](https://img.shields.io/badge/Swift-6.0%2B-orange.svg)](Package.swift)

把兼容的蓝牙语音遥控器变成 macOS 上的 Codex 按住说话入口：按住说话，松手让 Agent 开工。

目标链路：

```text
遥控器麦克风 → BLE ATVV → ADPCM 解码 → 本地 Whisper → 当前 Codex 输入框 → Return 发送
```

它不是把 MacBook 麦克风伪装成遥控器，而是直接读取电视遥控器的 BLE 私有语音服务。

## 当前支持的协议

- Google ATV Voice over BLE v0.4
- Google ATV Voice over BLE v1.0
- IMA/DVI ADPCM 8 kHz 与 16 kHz
- `START_SEARCH` 开始
- `AUDIO_STOP`/松手结束
- 第二次语音键结束
- 缺少松手事件时静音自动结束
- 本地 `whisper.cpp` 中文转写
- 通过 macOS Accessibility 向 Codex 当前输入框粘贴并发送

## 真机兼容性

| 设备 | 固件 | 协议 | 已验证 |
| --- | --- | --- | --- |
| 小米蓝牙遥控器 2 Pro | 2671 | ATVV v1.0，ADPCM 16 kHz，120 B | 配对、已连接设备发现、GATT、按住/松手、WAV 解码、中文 Whisper 转写 |

> 项目状态：小米 2 Pro 的硬件、协议、音频解码和真实中文转写已打通；正在完成日常桥接、静音/断连恢复与 Codex 真实提交验收。

## 安装

```bash
chmod +x scripts/*.sh
./scripts/setup.sh
```

安装脚本会：

1. 安装 Homebrew `whisper-cpp`；
2. 下载多语言 `ggml-base.bin`；
3. 构建 release 二进制；
4. 生成固定 Bundle ID `com.fanx.miao` 的「米遥」App，安装到 `~/Applications`；
5. 如检测到早期原型，安全迁移模型与录音目录，并在新版安装成功后移除旧 App。

## 第一次真机联调

先给遥控器充电并让它进入配对模式，在 macOS“系统设置 → 蓝牙”里完成配对。小米旧款电视遥控器通常同时长按 Home + 菜单键进入配对，但 2 Pro 的准确组合键应以包装内说明书为准。

第一步生成附近设备的脱敏扫描报告：

```bash
./scripts/capture.sh --scan-seconds 30
```

终端仍会显示本机 UUID，报告中默认使用哈希 ID 并隐藏设备名。记下遥控器的 `id=<UUID>`，第二步连接目标并采集 60 秒：

```bash
./scripts/capture.sh --identifier <UUID> --capture-seconds 60 --debug
```

采集期间依次测试短按语音键、按住说话后松开、再次按键和静音。报告保存在 `~/Library/Application Support/mi-ao/captures`。确认设备协议后，再启动日常桥接：

```bash
./scripts/run.sh --identifier <UUID> --debug
```

完整步骤和证据判定见 [真机 Bring-up 指南](docs/HARDWARE_BRINGUP.md)。

第一次使用需要允许：

- 系统设置 → 隐私与安全性 → 蓝牙
- 系统设置 → 隐私与安全性 → 辅助功能

辅助功能列表里应选择安装脚本输出的 App，不要选择 `.build` 目录里的临时二进制。

可以主动触发授权提示：

```bash
./scripts/authorize.sh
```

本机没有可用的 Apple Developer 签名证书，因此 App 当前采用本机 ad-hoc 签名。平时不要反复执行 `install-app.sh`；如果重新构建并覆盖 App，macOS 可能要求再次确认辅助功能权限。

保持 Codex 当前任务的输入框获得焦点。按遥控器语音键说话，录音结束后会转写并发送。

## 本机验证记录（2026-07-14）

- macOS 26.5.2 / Apple Silicon release 构建通过；
- `whisper-cpp` 1.9.1 与多语言 `ggml-base.bin` 已安装；
- ATVV v0.4/v1.0 capabilities、ADPCM 解码和 8→16 kHz 重采样测试通过；
- 使用 macOS 中文合成语音验证，识别结果为“请检查当前项目，然后继续工作”；
- CoreBluetooth 扫描和正常退出已通过，扫描到 20 个附近设备；
- `capture` 的脱敏报告、JSONL 原始事件、权限保护和无目标超时收口已通过；
- 小米 2 Pro 固件 2671 真机确认为 ATVV v1.0 / ADPCM 16 kHz / Hold-to-Talk / 120 字节帧；
- 真实遥控器语音已识别为“这是第二次语音测试”，按住开始与松手停止均有原始控制帧佐证。

## 安全边界

- transcript 为空时不发送。
- Codex 未运行时不发送，只复制到剪贴板。
- 无辅助功能权限时不发送，只复制到剪贴板。
- 无法验证当前焦点为文本输入框时不发送；只有明确传入 `--force-submit` 才跳过焦点检查。
- 每次原始 WAV 和 transcript 都保存在 `~/Library/Application Support/mi-ao/recordings`，便于复核。
- `capture` 默认哈希化设备 UUID、隐藏设备名，但会在本机保存原始 GATT payload；分享采集目录前必须人工复核。

## 诊断

```bash
./scripts/bridge.sh doctor
```

如果设备没有暴露 `AB5E0001-5A21-4F05-BC7D-AF01F617B664`，程序会输出全部 services 和 characteristics。此时需要针对小米协议增加新的 transport，而不是伪造成功。

## 开发

```bash
make test
make release
make app
make check
```

架构、协议和路线图分别见：

- [架构说明](docs/ARCHITECTURE.md)
- [ATVV 协议说明](docs/PROTOCOL.md)
- [真机 Bring-up 指南](docs/HARDWARE_BRINGUP.md)
- [路线图](docs/ROADMAP.md)
- [开源发布检查表](docs/OPEN_SOURCE_CHECKLIST.md)
- [名称与产品身份](docs/NAMING.md)
- [无正式签名的源码分发方案](docs/DISTRIBUTION.md)

提交代码前请阅读 [CONTRIBUTING.md](CONTRIBUTING.md)。安全问题请按 [SECURITY.md](SECURITY.md) 私下报告。

## 调研来源

- [小米商城：小米蓝牙遥控器 2 Pro](https://www.mi.com/shop/buy?cfrom=search&product_id=1230800738)
- [小米官方：蓝牙遥控器配对排查](https://www.mi.com/tw/support/faq/details/KA-05732/)
- [b0o/ATVVoice：Linux 上已工作的 Google TV 语音遥控器实现](https://github.com/b0o/ATVVoice)
- [BlueZ #1086：Voice-over-BLE/ATVV 上游讨论](https://github.com/bluez/bluez/issues/1086)
- [Infineon BLE HID Voice Remote 参考实现](https://github.com/Infineon/mtb-example-btsdk-hid-ble-remote)

## 许可证

[MIT](LICENSE)。第三方协议研究来源与许可证说明见 [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)。

「米遥 / MI-AO」是独立开源项目名称。本项目并非小米官方产品，也不受小米公司、Google 或 OpenAI 背书；相关商标归各自权利人所有。
