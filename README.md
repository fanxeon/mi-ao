# 米遥 MI-AO

**在 Vibe Coding 时代，把小米蓝牙遥控器 2 Pro 变成一根真正握在手里的 Codex 魔法仙女棒。**

按住说话，松手发送。本地 Whisper 完成转写，Codex 立即开工。

由 **[FanXeon@Poemcoder with Codex](AUTHORS.md)** 创建、真机验证并持续维护。

[中文](README.md) · [English](README_EN.md) · [3 分钟快速开始](docs/QUICKSTART.md) · [兼容设备](docs/COMPATIBILITY.md) · [参与贡献](CONTRIBUTING.md)

[![CI](https://github.com/fanxeon/mi-ao/actions/workflows/ci.yml/badge.svg)](https://github.com/fanxeon/mi-ao/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![macOS 14+](https://img.shields.io/badge/macOS-14%2B-black.svg)](Package.swift)
[![Swift 6](https://img.shields.io/badge/Swift-6-orange.svg)](Package.swift)
[![Hardware verified](https://img.shields.io/badge/hardware-verified-2ea44f.svg)](docs/COMPATIBILITY.md)

```text
按住遥控器 → 说“检查当前项目并继续工作” → 松手 → Codex 开工
```

米遥是使用小米蓝牙遥控器 2 Pro 构建的 Codex 语音输入方案。它直接读取遥控器自带麦克风的 BLE 语音数据，在 Mac 上本地解码和转写，然后安全发送到当前 Codex 任务。它不是另一个 Mac 麦克风听写工具；它让抽屉里的语音遥控器成为一个有手感、拿起就能用的 Vibe Coding 入口。

> **真机状态：** 小米蓝牙遥控器 2 Pro（固件 2671）已完成从按住说话到 Codex 真实收到消息的端到端验证。

## 为什么它像一根真正的魔法仙女棒

- **一个动作。** 按住就说，松手就发，不用先找麦克风按钮。
- **硬件麦克风。** 语音来自遥控器本身，不是用 MacBook 麦克风做假入口。
- **本地语音链路。** ADPCM 解码和 `whisper.cpp` 转写都在本机完成。
- **默认不误发。** 只有找到唯一可用的 Codex 编辑器才发送；其他情况只复制文字。
- **面向兼容性贡献。** 内置脱敏 GATT 采集模式，可以用真实证据接入更多遥控器。

## 真实闭环证据

```text
AUDIO_START ADPCM 16 kHz
AUDIO_STOP reason=remote-release
转写：请回复米遥真实发送成功。
已发送到 Codex
```

真实硬件、协议和端到端验收记录见 [兼容性矩阵](docs/COMPATIBILITY.md) 和 [真机 Bring-up](docs/HARDWARE_BRINGUP.md)。

## 3 分钟快速开始

### 1. 安装

```bash
git clone https://github.com/fanxeon/mi-ao.git
cd mi-ao
./scripts/setup.sh
```

`setup.sh` 会安装 `whisper-cpp`、下载多语言 base 模型、构建 release App，并安装到 `~/Applications/米遥.app`。

### 2. 配对与授权

先在“系统设置 → 蓝牙”中完成遥控器配对，然后运行：

```bash
./scripts/authorize.sh
```

macOS 会要求蓝牙和辅助功能权限。辅助功能列表中应允许已安装的“米遥” App。

### 3. 启动

已验证的小米 2 Pro：

```bash
./scripts/run.sh --name "小米蓝牙语音遥控器"
```

看到“桥接已就绪”后，按住遥控器语音键说话，说完松手。终端需保持运行；按 `Control + C` 停止。

其他遥控器请先按 [快速开始](docs/QUICKSTART.md) 采集脱敏协议证据，不要盲猜 UUID。

## 兼容性

| 设备 | 固件 | 协议 | 端到端 |
| --- | --- | --- | --- |
| 小米蓝牙遥控器 2 Pro | 2671 | ATVV v1.0 · ADPCM 16 kHz · 120 B | ✅ macOS → Whisper → Codex |
| 其他 Google / Android TV 语音遥控器 | 待贡献 | ATVV v0.4 / v1.0 参考实现 | 🧪 需要真机证据 |

完整状态、证据等级和新设备贡献方式见 [docs/COMPATIBILITY.md](docs/COMPATIBILITY.md)。

## 工作原理

```text
BLE 遥控器
  → Google ATV Voice over BLE
  → IMA/DVI ADPCM
  → 16 kHz PCM / WAV
  → 本地 whisper.cpp
  → macOS Accessibility
  → Codex 唯一编辑器
```

当前支持 ATVV v0.4 / v1.0、8 kHz / 16 kHz ADPCM、`AUDIO_STOP`、二次按键与静音超时收口。模块边界和扩展方式见 [架构说明](docs/ARCHITECTURE.md) 和 [ATVV 协议说明](docs/PROTOCOL.md)。

## 隐私与安全

- 语音转写默认在本机完成，不依赖语音云 API。
- WAV 和 transcript 保存在本机 `~/Library/Application Support/mi-ao/recordings`，用于用户复核。
- 转写为空、Codex 未运行、权限不足或编辑器不唯一时，不会自动发送。
- 采集报告默认哈希化设备 UUID 并隐藏名称，但原始 GATT payload 仍须在分享前人工复核。

完整边界见 [SECURITY.md](SECURITY.md)。

## 项目状态

核心真机链路已打通，当前是 **source-first alpha**：用户在自己的 Mac 上构建并使用 ad-hoc 签名 App。没有 Apple Developer ID 时，项目不会把未公证 DMG 包装成“一键安装”。

下一阶段聚焦：

- 菜单栏状态与启停反馈；
- 设备选择、配置持久化与自动重连；
- 实体按键学习、动作映射和方向键指针模式；
- 更多真实遥控器的兼容矩阵；
- 可配置输出目标，但不弱化默认安全边界。

见 [路线图](docs/ROADMAP.md) 和 [源码优先分发](docs/DISTRIBUTION.md)。

## 参与贡献

最有价值的贡献是“新硬件的可复核证据”。你可以：

- 提交一份脱敏 GATT 采集，帮助兼容新遥控器；
- 改进 ADPCM / ATVV 协议适配与测试 fixture；
- 完善 macOS 菜单栏、重连和日常体验；
- 改进中英文文档、排错和隐私审查。

请先阅读 [CONTRIBUTING.md](CONTRIBUTING.md)。没有真机证据的兼容性声明不会合并。

## 文档

- [文档导航](docs/README.md)
- [快速开始](docs/QUICKSTART.md)
- [兼容性矩阵](docs/COMPATIBILITY.md)
- [故障排查](docs/TROUBLESHOOTING.md)
- [架构说明](docs/ARCHITECTURE.md)
- [ATVV 协议说明](docs/PROTOCOL.md)
- [真机 Bring-up](docs/HARDWARE_BRINGUP.md)
- [路线图](docs/ROADMAP.md)

## 作者、致谢与许可证

米遥由 **FanXeon@Poemcoder with Codex** 创建。产品方向、工程决策、真实硬件验证与维护由 FanXeon@Poemcoder 负责，Codex 作为 AI 工程协作者参与代码、测试、文档与调试。完整署名和法律边界见 [AUTHORS.md](AUTHORS.md) 与 [NOTICE](NOTICE)。

米遥基于 Google ATV Voice over BLE 协议调研，使用 [`whisper.cpp`](https://github.com/ggml-org/whisper.cpp) 完成本地转写。协议参考和第三方声明见 [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)。

代码采用 [MIT License](LICENSE)，统一版权署名为 `Copyright (c) 2026 FanXeon@Poemcoder with Codex`。“米遥 / MI-AO”是独立开源项目，并非小米、Google 或 OpenAI 官方产品，也不受其背书。

---

如果你也相信 Vibe Coding 应该有一根真正握在手里的魔法仙女棒，欢迎 Star，并告诉我们下一款应该点亮哪支遥控器。
