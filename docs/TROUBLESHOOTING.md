<!-- Copyright (c) 2026 FanXeon@Poemcoder with Codex -->

# 故障排查

[English](TROUBLESHOOTING_EN.md) · [配对与连接](PAIRING.md) · [快速开始](QUICKSTART.md)

## 先运行诊断

```bash
./scripts/verify-install.sh
```

它会检查 App、Bundle ID、签名、Codex 进程、蓝牙权限、辅助功能、`whisper-cli` 和模型。

同时检查遥控器映射状态：

```bash
./scripts/remote-mapping.sh status
```

如果异常退出后仍显示“米遥中性映射”，保持遥控器连接并运行 `./scripts/remote-mapping.sh restore`。脚本检测到其他用户映射时会拒绝删除。

若终端任务显示 `suspended`，说明误按了 `Control + Z`。新版一键脚本会捕获暂停信号，终止子进程并恢复映射；正常停止请使用 `Control + C`。

## macOS 蓝牙页看不到遥控器

1. 打开“系统设置 → 蓝牙”；
2. 在小米蓝牙遥控器 2 Pro 上同时长按菜单键 + `HOME`；
3. 设备出现后点击“连接”，等待“已连接”状态。

如果仍不出现，检查电池，把遥控器放到 Mac 附近，并临时关闭原电视或机顶盒的蓝牙。完整的忽略设备、重新配对和首次安全测试步骤见 [配对与首次连接指南](PAIRING.md)。

## 启动后找不到遥控器

- 先区分问题所在：macOS 未显示“已连接”时，先重做系统配对；macOS 已连接但终端找不到时，再检查设备名、权限和米遥进程；
- 确认 macOS 蓝牙页显示设备已连接；
- 已连接设备可能停止普通广播，优先使用 `--name`；
- 设备名称必须与 macOS 显示名称的一部分匹配；
- 不要同时启动两个米遥进程。

```bash
./scripts/run.sh --name "小米蓝牙语音遥控器"
```

## 按键后完全没反应

终端应先显示“桥接已就绪”。如果没有：

1. 按 `Control + C` 停止；
2. 重新确认蓝牙连接；
3. 运行 `./scripts/verify-install.sh`；
4. 用 `--debug` 重启并查看是否出现 `AUDIO_START`。

## 有转写，但没有发送到 Codex

米遥会在安全检查失败时把 transcript 复制到剪贴板。常见日志：

- `Codex 未运行`：先打开 Codex App；
- `尚未授予辅助功能权限`：给 `~/Applications/米遥.app` 授权；
- `无法安全聚焦唯一的 Codex 输入框`：关闭 Codex 的重叠弹窗或多编辑器状态后重试。

不要把 `--force-submit` 当作日常解决方案。它会跳过编辑器唯一性检查。

## 语音可用，但鼠标模式没有启动

这是安全降级，不代表语音故障。先看终端给出的具体原因：

- “缺少人工确认校准”：运行 `./scripts/debug-buttons.sh --name "小米蓝牙语音遥控器"`，至少确认方向四键、中间确认和返回；
- “按键校准冲突”：两个实体按钮被确认成同一 Usage，分别使用 `--button <标识>` 重测；
- “需要辅助功能权限”：运行 `./scripts/authorize.sh`，在系统设置中授权已安装的米遥 App 后重启；
- 指定 `--button-profile` 后失败：确认它是 `captureMode=confirmed_calibration` 的新格式完整档案，而不是 `learn-buttons` 自动学习报告。

只使用语音、暂不处理鼠标问题：

```bash
./scripts/run.sh --name "小米蓝牙语音遥控器" --no-buttons
```

完整门禁和映射见 [按键预设与默认指针模式](BUTTON_PRESETS.md)。

## `TV` 不切换模式，或电源键不启动 Codex

这两个键不是基础六键门禁的一部分，必须分别校准：

```bash
./scripts/debug-buttons.sh --name "小米蓝牙语音遥控器" --button tv
./scripts/debug-buttons.sh --name "小米蓝牙语音遥控器" --button power
```

小米 2 Pro 固件 2671 的已验证结果是 `TV=0x07/0x35`、电源 `0x07/0x66`。如果同型号结果不同，先不要确认并检查固件；其他遥控器若始终没有电源键 HID 事件，则可能只发送红外信号。若终端显示“未找到 Codex App”，请确认官方 Codex macOS App 已安装且 bundle ID 为 `com.openai.codex`。

## 校准时前台 App 也响应了方向键

`debug-buttons` 不会合成米遥动作，但 macOS 仍可能处理遥控器原始 HID 键。请停止校准，聚焦到空白且不会因方向键、返回键丢失内容的窗口，再重新运行。不要在未保存的编辑器、文件列表或删除确认框中校准。

## 音量键不切换 Codex 会话

先确认 Codex 已运行，并在 Codex 的“View”菜单中能看到 `Previous Task` / `Next Task`。再分别运行 `debug-buttons.sh --button volume_up` 和 `--button volume_down`；小米 2 Pro 固件 2671 的确认值应为 `0x07/0x80`、`0x07/0x81`。米遥通过 Accessibility 直接执行菜单项，不会合成组合键；若键盘出现修饰键卡住，应立即停止并报告，不能视为正常行为。

## 指针动作和前台 App 同时响应

立即按 `Control + C` 停止，然后运行 `./scripts/remote-mapping.sh status`。正常状态应显示当前设备的十二个接管键均映射为 `No Event`，仅菜单不在映射内。若状态缺失或回读不一致，先执行 `./scripts/remote-mapping.sh restore`，再通过 `./scripts/run-with-mapping.sh` 启动；不要用全局键盘重映射作为绕过方案。

米遥不建立全局 Quartz 键盘事件 tap。若 Mac 实体键盘出现按键丢失或修饰键卡住，应立即停止米遥并提交脱敏日志，这是安全缺陷而不是可接受的已知限制。

## 中文术语识别错误

使用短词表，不要把长句当作 prompt：

```bash
./scripts/run.sh \
  --name "<设备名>" \
  --prompt "米遥。Codex。项目名。专有术语。"
```

长句 prompt 可能被小模型当成要续写的文本，导致重复尾句。

## 重新安装后权限失效

App 被重建或覆盖后，macOS 可能要求重新确认辅助功能。平时不要反复运行 `install-app.sh`。

## 转写文件在哪里

```text
~/Library/Application Support/mi-ao/recordings
```

每次运行会保留 WAV 和 `.txt` transcript，便于确认是音频、Whisper 还是 Codex 提交问题。这些文件可能含私人语音，不要上传到公开 Issue。

## 仍然无法解决

使用 Bug Report Issue 模板，提供版本、macOS、遥控器型号/固件和已脱敏日志。安全问题不要创建公开 Issue，请按 [SECURITY.md](../SECURITY.md) 报告。
