<!-- Copyright (c) 2026 FanXeon@Poemcoder with Codex -->

# 使用说明

[English](USAGE_EN.md) · [快速开始](QUICKSTART.md) · [故障排查](TROUBLESHOOTING.md)

这份文档从“已经安装完成”开始，说明如何日常启动米遥、按住说话、确认成功、选择安全模式、更新和清理数据。首次安装请先完成 [3 分钟快速开始](QUICKSTART.md)。

## 当前使用方式

米遥目前是 **source-first alpha**，推荐从项目目录运行脚本：

```bash
cd /path/to/mi-ao
./scripts/run.sh --name "小米蓝牙语音遥控器"
```

运行期间终端必须保持打开。当前版本还没有菜单栏、开机自启和可见录音浮层，不要把双击 `米遥.app` 当作日常启动方式，否则看不到连接、转写和失败信息。

## 每天使用：四个动作

### 1. 准备

- 在“系统设置 → 蓝牙”确认 `小米蓝牙语音遥控器` 已连接；
- 打开 Codex macOS App；
- 进入准备接收指令的 Codex 任务，关闭覆盖输入框的弹窗。

### 2. 启动米遥

```bash
cd /path/to/mi-ao
./scripts/run.sh --name "小米蓝牙语音遥控器"
```

等待终端显示：

```text
桥接已就绪：按遥控器语音键开始说话
```

没有出现“桥接已就绪”前不要开始说话。

### 3. 按住、说话、松手

1. 按住遥控器右上角的语音键；
2. 保持按住，完整说完指令；
3. 说完再松开；
4. 等待本地 Whisper 转写和 Codex 安全提交。

一次正常会话应依次出现类似日志：

```text
AUDIO_START ADPCM 16 kHz
AUDIO_STOP reason=0x00
录音完成 reason=remote-release
转写：检查当前项目并告诉我下一步
已发送到 Codex
桥接已就绪：按遥控器语音键继续
```

再次看到“桥接已就绪”后，才能开始下一条语音。过短的点击会显示“录音过短，取消”，不会发送空消息。

### 4. 停止

在运行米遥的终端按：

```text
Control + C
```

这只停止本次桥接，不会删除 App、模型、录音或权限。

## 米遥会如何发送

默认模式会：

1. 在本机把遥控器音频转写成文字；
2. 确认 Codex 正在运行；
3. 在当前 Codex 窗口中寻找唯一可用输入框；
4. 临时写入剪贴板，粘贴并按 Return；
5. 发送后恢复原剪贴板内容。

如果 Codex 未运行、辅助功能未授权或无法确认唯一输入框，米遥不会盲目回车，而是把 transcript 留在剪贴板并在终端说明原因。此时可以检查文字后手动粘贴。

## 推荐说法

短、明确、包含目标和动作的指令更稳定，例如：

```text
检查当前项目状态并告诉我下一步。
运行测试，定位第一个失败并解释原因。
阅读 README，找出和真实代码不一致的地方。
先审计当前实现，不要修改代码。
修复这个问题，完成后运行相关测试。
```

一次语音尽量只表达一个主任务。文件名、函数名和英文缩写要放慢一点说；高频项目术语可以通过 `--prompt` 提示 Whisper。

## 三种常用模式

### 默认：松手后发送到 Codex

```bash
./scripts/run.sh --name "小米蓝牙语音遥控器"
```

适合日常短指令。

### 安全检查：只转写，不发送

```bash
./scripts/run.sh \
  --name "小米蓝牙语音遥控器" \
  --no-submit
```

转写结果会显示在终端，并保存为 `.txt`，但不会进入 Codex。第一次测试新模型、环境或术语时建议先用这个模式。

### 项目术语：自定义 Whisper 提示

```bash
./scripts/run.sh \
  --name "小米蓝牙语音遥控器" \
  --prompt "米遥。Codex。项目名。函数名。专有术语。"
```

提示应是短词表，不要放完整命令或长段落，否则小模型可能把提示内容续写进结果。

英文转写示例：

```bash
./scripts/run.sh \
  --name "小米蓝牙语音遥控器" \
  --language en \
  --prompt "MI-AO. Codex. Swift. CoreBluetooth."
```

## 选择特定遥控器

正常情况优先使用稳定、可读的设备名：

```bash
./scripts/run.sh --name "小米蓝牙语音遥控器"
```

如果出现同名设备，可以先扫描：

```bash
./scripts/bridge.sh scan --scan-seconds 20
```

再使用本机 peripheral UUID：

```bash
./scripts/run.sh --identifier <UUID>
```

peripheral UUID 是本机设备标识，不要贴到公开 Issue、截图或日志中。

## 诊断模式

先运行完整安装检查：

```bash
./scripts/verify-install.sh
```

需要观察 BLE / GATT 事件时：

```bash
./scripts/run.sh \
  --name "小米蓝牙语音遥控器" \
  --debug
```

`--debug` 可能输出原始设备数据，只用于本地排查。公开分享前必须脱敏。更完整的错误处理见 [故障排查](TROUBLESHOOTING.md)。

## 数据保存在哪里

默认目录：

```text
~/Library/Application Support/mi-ao/recordings
```

每次有效语音会保留：

- `voice-*.wav`：解码并增益后的本地音频；
- `voice-*.txt`：最终 transcript；
- `voice-*.whisper.txt`：Whisper 原始文本输出。

这些文件可能含私人语音、项目名和代码术语。它们不会自动上传，但也不应提交到 Git 或公开 Issue。

自定义输出目录：

```bash
./scripts/run.sh \
  --name "小米蓝牙语音遥控器" \
  --output-dir "$HOME/Desktop/mi-ao-test"
```

## 更新米遥

先停止正在运行的桥接，然后：

```bash
cd /path/to/mi-ao
git pull --ff-only
./scripts/setup.sh
./scripts/verify-install.sh
```

`setup.sh` 会重新构建并覆盖 `~/Applications/米遥.app`，保留模型和录音。macOS 如果再次询问辅助功能权限，请只授权这个已安装 App。

## 卸载与清理

只删除 App，保留模型和历史录音：

```bash
./scripts/uninstall.sh
```

删除 App、Whisper 模型、录音和采集数据：

```bash
./scripts/uninstall.sh --all-data
```

`--all-data` 不可撤销，执行前先备份需要保留的 transcript。

## 当前边界

- 已完整验证：小米蓝牙遥控器 2 Pro，固件 2671；
- 当前正式入口只有语音键；方向键、确认、返回和指针模式仍在 [路线图](ROADMAP.md)；
- 当前必须保持终端运行；菜单栏、后台常驻和开机自启尚未实现；
- 默认只提交到 bundle ID 为 `com.openai.codex` 的 Codex macOS App；
- 不要把 `--force-submit` 作为日常选项，它会放宽输入框安全检查。

其他遥控器必须先按 [真机 Bring-up](HARDWARE_BRINGUP.md) 取得脱敏证据，再进入兼容矩阵。
