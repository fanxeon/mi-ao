<!-- Copyright (c) 2026 FanXeon@Poemcoder with Codex -->

# 使用说明

[English](USAGE_EN.md) · [配对与连接](PAIRING.md) · [快速开始](QUICKSTART.md) · [故障排查](TROUBLESHOOTING.md)

这份文档从“已经安装完成”开始，说明如何日常启动米遥、按住说话、确认成功、选择安全模式、更新和清理数据。首次安装请先完成 [3 分钟快速开始](QUICKSTART.md)。

## 当前使用方式

米遥 V2 / 0.2.1 目前是 **source-first beta**。安装后在 Finder 中双击 `~/Applications/米遥.app`。

首次使用时，双击会打开设置向导。它按“开始 → 控制偏好 → 权限与连接 → 启动”的真实路径组织：先选择“自动发送”和“按键控制”，再只处理当前功能真正需要的项目；“按键指南”页提供内置的默认按键图。登录时启动始终可选。第一次成功启动后，手动双击或可选登录项会读取同一份偏好并调用同一条真实启动门禁。完整边界见 [权限与可选功能](PERMISSIONS.md)。

启动时会先检查 Codex：未运行则自动按兼容方式启动；已运行但参数缺失则直接停止，不修改遥控器映射，也不重启正在工作的 Codex。只使用 `--no-submit` 做安全转写时跳过这项检查。

后台日志保存在 `~/Library/Application Support/mi-ao/logs/mi-ao.log`。日常不需要打开它；只有排错或提交脱敏 Issue 时再查看。

## 每天使用：四个动作

### 1. 准备

- 在“系统设置 → 蓝牙”确认 `小米蓝牙语音遥控器` 已连接；如果尚未出现，同时长按遥控器的菜单键 + `HOME` 后按 [配对与首次连接指南](PAIRING.md) 处理；
- 打开 Codex macOS App；
- 进入准备接收指令的 Codex 任务，关闭覆盖输入框的弹窗。
- 首次使用、Codex 重开或升级后，双击米遥 App 查看“Codex 输入区”检查；如果需要准备，先保存当前工作，再明确确认重启。

### 2. 启动米遥

双击 `~/Applications/米遥.app`。首次使用时确认所有“必须”和“当前功能必需”项目通过，再点击“连接遥控器并开始”；完成设置后，双击会直接执行已保存的安全启动。普通用户无需再进入项目目录。

一键脚本只匹配 Vendor `0x2717` / Product `0x32B8` 的目标遥控器，启动前把方向键、确认、返回、HOME、TV、电源、语音和音量加减共十二键中性化为 HID `No Event`；菜单不进入映射并沿用 macOS 原生鼠标右键。音量 `+/-` 分别切换 Codex 上一个/下一个会话。退出时恢复。只使用语音时可改用普通 `run.sh --no-buttons`，它不会修改 `UserKeyMapping`。

点击菜单栏图标，等待面板显示：

```text
状态：已就绪 · 按住语音键说话
```

没有出现“桥接已就绪”前不要开始说话。

> **刘海屏边界：** 右侧常驻项过多时，米遥状态项可能已创建却被刘海或可用宽度遮挡。再次双击 App 若显示“米遥当前已经运行”，说明运行态仍在；请参照 [故障排查](TROUBLESHOOTING.md) 释放菜单栏空间，不要反复启动第二个实例。

就绪后，方向、滚动、Return/Escape、快捷键、HOME、模式/配置切换和 Codex 操作会让菜单栏短暂显示对应图标。蓝色圆角底色表示指令正在反馈，绿色表示已确认成功，红色表示真实失败；约 1.2 秒后回到最新运行状态。录音、后台转写、断连和错误优先显示，不会被普通按键覆盖。

### 3. 按住、说话、松手

1. 按住遥控器右上角的语音键；
2. 保持按住，完整说完指令；
3. 说完再松开；
4. 松手后录音立即进入后台 Whisper 转写和 Codex 安全提交；此时可以继续使用方向键，也可以录下一条。

一次正常会话应依次出现类似日志：

```text
AUDIO_START ADPCM 16 kHz
AUDIO_STOP reason=0x00
录音完成 reason=remote-release
录音结束 reason=remote-release，已进入后台转写队列（待处理 1）
转写：检查当前项目并告诉我下一步
已发送到 Codex
```

队列最多容纳“一条处理中 + 一条等待中”。因此上一条转写时可以继续录一条；若连续第三条快到超过本机处理速度，米遥会明确提示队列已满并不提交第三条，避免旧命令无限积压。过短的点击会显示“录音过短，取消”，不会发送空消息。

### 4. 停止

点击菜单栏图标，在面板选择：

```text
安全退出并恢复遥控器
```

也可以在项目目录运行 `./scripts/stop.sh`。安全退出会等待已经接收的语音处理完成，再停止桥接并恢复遥控器系统映射；不会删除 App、模型、录音或权限。前台调试模式仍可用 `Control + C` 停止。

同一面板还提供“聚焦 Codex”“录音与文字记录”和“设置与诊断”。这些按钮读取或触发真实运行状态，不会把未连接显示成成功。

## 米遥会如何发送

默认模式会：

1. 在本机把遥控器音频转写成文字；
2. 确认 Codex 正在运行；
3. 在当前 Codex 进程公开的辅助功能树中寻找并聚焦唯一可用输入区；
4. 临时写入剪贴板，粘贴并按 Return；
5. 发送后仅在剪贴板仍是米遥注入内容时恢复原内容。

兼容参数不开放调试端口，也不让米遥读取对话内容；语音文本仍通过剪贴板进入 Codex。如果提交期间你复制了新内容，米遥会保留这个新剪贴板，不会用旧快照覆盖。如果 Codex 未运行、权限未授予或无法确认唯一输入区，米遥不会盲目回车，而是把 transcript 留在剪贴板并说明原因。

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
./scripts/start.sh
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

运行模式下 `--debug` 还会打印 `HID 按下/松手 → 实体按钮`，可用于判断问题发生在硬件识别、预设映射还是动作执行层。

`--debug` 可能输出原始设备数据，只用于本地排查。公开分享前必须脱敏。更完整的错误处理见 [故障排查](TROUBLESHOOTING.md)。

## 学习实体按钮

按键学习器只监听指定遥控器的 HID Vendor/Product，不采集 Mac 内置键盘输入。完整扫描小米蓝牙遥控器 2 Pro：

```bash
./scripts/learn-buttons.sh \
  --name "小米蓝牙语音遥控器"
```

按终端提示逐个短按并松开按钮。需要排除提示错位或复核某一项时，使用单键模式：

```bash
./scripts/learn-buttons.sh \
  --name "小米蓝牙语音遥控器" \
  --button back \
  --button-seconds 20
```

推荐使用带人工确认门的校准调试模式建立正式键码表：

```bash
./scripts/debug-buttons.sh \
  --name "小米蓝牙语音遥控器"
```

每次松手后，终端会显示“实体按钮 → HID Usage → 当前预设动作”。调试器不会执行米遥的鼠标、Codex 或系统动作。由于普通用户进程不能独占这支 HID 设备，校准期间原始按键仍可能被 macOS 或前台 App 处理；请先聚焦到不会因方向键、返回键而丢失内容的安全窗口。输入：

- `回车` 或 `y`：确认结果并写入档案；
- `r`：丢弃本次结果并重测当前按钮；
- `s`：将当前按钮标记为跳过；
- `q`：结束并只保存此前已确认项目。

例如返回键会显示 Usage Page `0x07` / Usage `0xF1`；在默认 `pointer` 套装中预览为 `keyboard.escape`。用户确认后，JSON 只保存“这个 Usage 是 `back`”的物理关系，不保存 Escape 动作语义。

可用按钮标识为 `voice`、`dpad_up`、`dpad_down`、`dpad_left`、`dpad_right`、`center`、`back`、`home`、`menu`、`volume_up`、`volume_down`、`tv`、`power`。

报告保存在：

```text
~/Library/Application Support/mi-ao/button-profiles/
```

报告记录规范化后的 HID Usage、原始值、按下、松手、重复证据和人工确认结果，不保存动作预设、MAC、CoreBluetooth UUID、序列号或主机键盘事件。小米 2 Pro 固件 2671 的返回键已经通过独立单键复测与人工确认，结果为 Keyboard Usage Page `0x07` / Usage `0xF1`，按下与松手均可观察；由于旧报告没有新格式的 `captureMode` 信任标记，启用指针模式前仍需重新确认。其他按钮也必须逐项校准，不能仅凭一次全键扫描宣称映射完成。

## 启用默认指针模式

完成方向四键、中间确认和返回六项人工确认后，重新执行日常启动命令即可。`pointer` 是默认预设：

```bash
./scripts/run.sh --name "小米蓝牙语音遥控器"
```

需要固定某份完整档案时使用 `--button-profile "/path/to/buttons-*.json"`；只需要语音时使用 `--no-buttons`。缺键、重复 Usage 或辅助功能权限失败时，米遥会拒绝启动实体按键动作并打印原因，语音输入仍继续可用。

映射状态与手动恢复：

```bash
./scripts/remote-mapping.sh status
./scripts/remote-mapping.sh restore
```

`HOME` 单击会在 350 ms 双击时间窗结束后发送 Page Down；时间窗内再按一次则取消待执行的 Page Down，只发送一次 Page Up。这样双击不会造成页面先下后上。

若进程被强制终止且所有权状态文件丢失，但 `status` 显示的映射与米遥完全一致，可明确执行 `restore --force`。脚本遇到任何其他既有映射都会拒绝覆盖或删除。

启动后默认是鼠标模式；按已校准的 `TV` 键只会把方向环切换为上下左右，再按一次恢复移动鼠标。中间确认始终发送 Return，返回始终发送 Escape，其他按键不随模式变化。已校准的电源键会启动 Codex，Codex 已运行时则聚焦现有窗口。小米 2 Pro 固件 2671 已真机确认 `TV=0x07/0x35`、电源 `0x07/0x66`，按下与松手完整；其他遥控器仍需独立校准。

完整两层映射示意图、默认按键表和安全边界见 [按键预设与默认指针模式](BUTTON_PRESETS.md)。六个必需按钮已完成真机校准，四个方向已完成直接光标定位和真实坐标验收；模式切换和电源动作仍属于 implementation preview。

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
录音目录权限是 `0700`，上述语音和文字文件权限是 `0600`，默认仅当前 macOS 用户可访问。

自定义输出目录：

```bash
./scripts/run.sh \
  --name "小米蓝牙语音遥控器" \
  --output-dir "$HOME/Desktop/mi-ao-test"
```

## 更新米遥

先通过菜单栏安全退出，或运行 `./scripts/stop.sh`，然后：

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

卸载脚本会先恢复米遥拥有的遥控器中性映射，再删除 App 或数据。

## 当前边界

- 已完整验证：小米蓝牙遥控器 2 Pro，固件 2671；
- 语音键已完成真机端到端验收；六个必需按钮已完成校准，四个方向已完成鼠标动作闭环，其余实体动作仍在 [路线图](ROADMAP.md)；
- 已支持 Preferences v1、按功能分级的权限门禁、可选登录启动、首次设置向导、App 内置日常运行组件、菜单栏 GUI 和安全后台启停；登录启动仍需安装版真机验收；
- 默认只提交到 bundle ID 为 `com.openai.codex` 的 Codex macOS App；
- 不要把 `--force-submit` 作为日常选项，它会放宽输入框安全检查。

其他遥控器必须先按 [真机 Bring-up](HARDWARE_BRINGUP.md) 取得脱敏证据，再进入兼容矩阵。
