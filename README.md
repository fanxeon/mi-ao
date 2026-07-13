# 项目名称待定：蓝牙语音遥控器 → AI Agent

[English](README_EN.md) · 中文

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-macOS%2014%2B-black.svg)](Package.swift)
[![Swift](https://img.shields.io/badge/Swift-6.0%2B-orange.svg)](Package.swift)

把小米/Google TV 蓝牙语音遥控器变成 macOS 上的 Codex 按住说话入口。

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

小米蓝牙遥控器 2 Pro 是否使用 ATVV，需要真机枚举后确认。如果它使用另一套 UUID，`scan --debug` 会保留完整 GATT 证据，后续在现有协议层增加适配器，不会推倒重来。

这款 2 Pro 是 2026 年发布的新硬件，公开资料确认它具备蓝牙 5.4、独立 AI 语音键和近场麦克风，但目前没有找到公开的 2 Pro GATT 抓包或配对组合键文档。因此本项目采用已有 Google/Android TV 语音遥控器的 ATVV 合同，并把真机 service 枚举保留为兼容性门。

> 项目状态：早期硬件适配阶段。软件链路和 ATVV 参考实现已经可运行；小米蓝牙遥控器 2 Pro 的真机 GATT 与音频帧仍等待实测确认。

## 安装

```bash
chmod +x scripts/*.sh
./scripts/setup.sh
```

安装脚本会：

1. 安装 Homebrew `whisper-cpp`；
2. 下载多语言 `ggml-base.bin`；
3. 构建 release 二进制；
4. 生成固定 Bundle ID 的 App，安装到 `~/Applications`。当前仍保留原型身份，定名后只迁移一次，避免反复触发辅助功能授权。

## 第一次真机联调

先给遥控器充电并让它进入配对模式，在 macOS“系统设置 → 蓝牙”里完成配对。小米旧款电视遥控器通常同时长按 Home + 菜单键进入配对，但 2 Pro 的准确组合键应以包装内说明书为准。然后运行：

```bash
./scripts/bridge.sh scan --scan-seconds 30 --debug
```

记下遥控器的 `id=<UUID>`，随后启动：

```bash
./scripts/run.sh --identifier <UUID> --debug
```

也可以按名称过滤：

```bash
./scripts/run.sh --name "Xiaomi" --debug
```

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

## 本机验证记录（2026-07-13）

- macOS 26.5.2 / Apple Silicon release 构建通过；
- `whisper-cpp` 1.9.1 与多语言 `ggml-base.bin` 已安装；
- ATVV v0.4/v1.0 capabilities、ADPCM 解码和 8→16 kHz 重采样测试通过；
- 使用 macOS 中文合成语音验证，识别结果为“请检查当前项目，然后继续工作”；
- CoreBluetooth 扫描和正常退出已通过，扫描到 20 个附近设备；
- 当前扫描时遥控器没有进入广播/配对状态，因此尚未取得 2 Pro 的真实 UUID、GATT service 和音频帧。这是剩余的唯一硬件兼容性验收门，不能伪装成已经打通。

## 安全边界

- transcript 为空时不发送。
- Codex 未运行时不发送，只复制到剪贴板。
- 无辅助功能权限时不发送，只复制到剪贴板。
- 无法验证当前焦点为文本输入框时不发送；只有明确传入 `--force-submit` 才跳过焦点检查。
- 每次原始 WAV 和 transcript 都保存在 `~/Library/Application Support/XiaomiVoiceBridge/recordings`，便于复核。

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
- [路线图](docs/ROADMAP.md)
- [开源发布检查表](docs/OPEN_SOURCE_CHECKLIST.md)
- [名称候选与初步检索](docs/NAMING.md)
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
