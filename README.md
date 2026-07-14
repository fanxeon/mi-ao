<!-- Copyright (c) 2026 FanXeon@Poemcoder with Codex -->

# 米遥 MI-AO

**在 Vibe Coding 时代，把小米蓝牙遥控器 2 Pro 变成 Mac 上一根真正握在手里的 Codex 魔法仙女棒。**

**仅适用于 macOS 14 或更高版本，当前不支持 Windows / Linux。** 按住说话，松手发送。本地 Whisper 完成转写，Codex 立即开工。

由 **FanXeon@Poemcoder with Codex** 创建、真机验证并持续维护。“是的我只手写了这一行代码，出现任何bug我宣布有codex负责”

[中文](README.md) · [English](README_EN.md) · [配对与连接](docs/PAIRING.md) · [3 分钟快速开始](docs/QUICKSTART.md) · [按键预设](docs/BUTTON_PRESETS.md) · [使用说明](docs/USAGE.md) · [兼容设备](docs/COMPATIBILITY.md) · [参与贡献](CONTRIBUTING.md)

[![CI](https://github.com/fanxeon/mi-ao/actions/workflows/ci.yml/badge.svg)](https://github.com/fanxeon/mi-ao/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![macOS 14+](https://img.shields.io/badge/macOS-14%2B-black.svg)](Package.swift)
[![Swift 6](https://img.shields.io/badge/Swift-6-orange.svg)](Package.swift)
[![Hardware verified](https://img.shields.io/badge/hardware-verified-2ea44f.svg)](docs/COMPATIBILITY.md)

```text
按住遥控器 → 说“检查当前项目并继续工作” → 松手 → Codex 开工
```

米遥是为 macOS 构建的小米蓝牙遥控器 2 Pro → Codex 语音输入方案。它直接读取遥控器自带麦克风的 BLE 语音数据，在 Mac 上本地解码和转写，然后安全发送到当前 Codex 任务。它不是另一个 Mac 麦克风听写工具；它让抽屉里的语音遥控器成为一个有手感、拿起就能用的 Vibe Coding 入口。

> **真机状态：** 小米蓝牙遥控器 2 Pro（固件 2671）已完成从按住说话到 Codex 真实收到消息的端到端验证。

## 为什么它像一根真正的魔法仙女棒

- **一个动作。** 按住就说，松手就发，不用先找麦克风按钮。
- **硬件麦克风。** 语音来自遥控器本身，不是用 MacBook 麦克风做假入口。
- **本地语音链路。** ADPCM 解码和 `whisper.cpp` 转写都在本机完成。
- **默认不误发。** 只有找到唯一可用的 Codex 编辑器才发送；其他情况只复制文字。
- **面向兼容性贡献。** 内置脱敏 GATT 采集模式，可以用真实证据接入更多遥控器。
- **可确认的按键校准。** 按设备 Vendor/Product 精确过滤 HID 事件；调试模式逐项显示 Usage 与当前预设动作，确认后才写入物理档案，不采集 Mac 键盘输入，也不合成鼠标或键盘动作。

## 真实闭环证据

```text
AUDIO_START ADPCM 16 kHz
AUDIO_STOP reason=remote-release
转写：请回复米遥真实发送成功。
已发送到 Codex
```

真实硬件、协议和端到端验收记录见 [兼容性矩阵](docs/COMPATIBILITY.md) 和 [真机 Bring-up](docs/HARDWARE_BRINGUP.md)。

## 一支遥控器，多套映射

校准只识别实体按钮，映射套装决定按钮用途。默认 `pointer` 套装如下；未来可以加入 Codex 会话导航套装，无需重新校准硬件。

| 按钮 | 默认 `pointer` 动作 |
| --- | --- |
| 方向键 | 鼠标模式：移动指针；方向键模式：发送上下左右 |
| 中间确认 | 鼠标模式：左击；方向键模式：Return |
| 返回 | 鼠标模式：右击；方向键模式：Escape |
| 音量加减 | 上下滚动 |
| `TV` | 切换鼠标模式 / 方向键模式 |
| `HOME` | 聚焦 Codex |
| 菜单 | 切换映射套装 |
| 语音 | 保持原有按住说话 |
| 电源 | 启动 Codex；已运行时聚焦 |

> **状态边界：** 映射架构、双控制模式和执行器已经实现；语音链路与返回键物理 Usage 已有真机证据。方向四键、确认、返回六项完整校准，以及 `TV` / 电源键是否输出 HID 的单键验证仍未完成，因此实体按键动作目前是 implementation preview，不标记为端到端验证。

完整示意图、校准命令、安全回退和扩展合同见 [按键预设与默认指针模式](docs/BUTTON_PRESETS.md)。

## 3 分钟快速开始

### 1. 安装

```bash
git clone https://github.com/fanxeon/mi-ao.git
cd mi-ao
./scripts/setup.sh
```

`setup.sh` 会安装 `whisper-cpp`、下载多语言 base 模型、构建 release App，并安装到 `~/Applications/米遥.app`。

### 2. 配对与授权

打开“系统设置 → 蓝牙”，在小米蓝牙遥控器 2 Pro 上**同时长按菜单键 + `HOME`**，直到它出现在“附近设备”。点击“连接”，等待状态变为“已连接”，然后运行：

```bash
./scripts/authorize.sh
```

`authorize.sh` 会请求辅助功能权限；第一次启动桥接时 macOS 会另外请求蓝牙权限。两处都应允许已安装的“米遥” App。完整的按键、配对、连接、首次安全测试和重连流程见 [遥控器配对与首次连接指南](docs/PAIRING.md)。

### 3. 启动

已验证的小米 2 Pro：

```bash
./scripts/run.sh --name "小米蓝牙语音遥控器"
```

看到“桥接已就绪”后，按住遥控器语音键说话，说完松手。终端需保持运行；按 `Control + C` 停止。

其他遥控器请先按 [快速开始](docs/QUICKSTART.md) 采集脱敏协议证据，不要盲猜 UUID。

安装完成后的日常启动、成功日志、仅转写模式、项目术语、更新和数据清理见 [完整使用说明](docs/USAGE.md)。当前版本需要保持终端运行，双击 App 不是推荐入口。

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

实体按键采用另一条链路：`HID Usage → 人工确认的实体按钮 → 可切换预设 → 动作执行器`。硬件校准档案不保存鼠标或 Codex 动作，因此更换预设不会污染设备证据。

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
- 默认 pointer 套装的六键真机校准、事件抑制时序与多显示器验收；
- Codex 会话导航等第二套映射；
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
- [遥控器配对与首次连接](docs/PAIRING.md)
- [快速开始](docs/QUICKSTART.md)
- [完整使用说明](docs/USAGE.md)
- [按键预设与默认指针模式](docs/BUTTON_PRESETS.md)
- [兼容性矩阵](docs/COMPATIBILITY.md)
- [故障排查](docs/TROUBLESHOOTING.md)
- [架构说明](docs/ARCHITECTURE.md)
- [ATVV 协议说明](docs/PROTOCOL.md)
- [真机 Bring-up](docs/HARDWARE_BRINGUP.md)
- [路线图](docs/ROADMAP.md)

## 作者、致谢与许可证

米遥由 **FanXeon@Poemcoder with Codex** 创建。产品方向、工程决策、真实硬件验证与维护由 FanXeon@Poemcoder 负责，Codex 作为 AI 工程协作者参与代码、测试、文档与调试。完整版权和法律边界见 [NOTICE](NOTICE)。

米遥基于 Google ATV Voice over BLE 协议调研，使用 [`whisper.cpp`](https://github.com/ggml-org/whisper.cpp) 完成本地转写。协议参考和第三方声明见 [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)。

代码采用 [MIT License](LICENSE)，统一版权署名为 `Copyright (c) 2026 FanXeon@Poemcoder with Codex`。“米遥 / MI-AO”是独立开源项目，并非小米、Google 或 OpenAI 官方产品，也不受其背书。

---

如果你也相信 Vibe Coding 应该有一根真正握在手里的魔法仙女棒，欢迎 Star，并告诉我们下一款应该点亮哪支遥控器。
