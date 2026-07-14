<!-- Copyright (c) 2026 FanXeon@Poemcoder with Codex -->

# 3 分钟快速开始

[English](QUICKSTART_EN.md) · [返回首页](../README.md)

## 准备

- macOS 14 或更高版本；
- Xcode Command Line Tools 和 Homebrew；
- Codex macOS App；
- 一个 BLE 语音遥控器。

当前完整验证的设备是小米蓝牙遥控器 2 Pro（固件 2671）。其他设备先查看 [兼容性矩阵](COMPATIBILITY.md)。

## 1. 安装

```bash
git clone https://github.com/fanxeon/mi-ao.git
cd mi-ao
./scripts/setup.sh
```

安装结果：

- App：`~/Applications/米遥.app`
- Whisper 模型：`~/.cache/mi-ao/ggml-base.bin`
- 录音和转写：`~/Library/Application Support/mi-ao/recordings`

项目当前采用本地构建和 ad-hoc 签名，不要从非官方来源下载所谓“免签名” DMG。

## 2. 配对遥控器

1. 打开“系统设置 → 蓝牙”；
2. 在小米蓝牙遥控器 2 Pro 上，**同时长按菜单键 + `HOME`**；
3. 遥控器出现在“附近设备”后松开按键，点击“连接”；
4. 等待它进入“我的设备”并显示“已连接”。

其他遥控器的配对键以设备说明书为准。如果找不到设备，或需要分清“系统已连接”和“米遥已就绪”，请按 [完整配对与连接指南](PAIRING.md) 操作。

## 3. 授权

```bash
./scripts/authorize.sh
```

在“系统设置 → 隐私与安全性”中允许：

- 辅助功能。

请授权已安装的“米遥” App，不要选择 `.build` 里的临时二进制。蓝牙权限会在下一步首次启动桥接时请求，届时点击“允许”。

## 4A. 启动已验证的小米 2 Pro

```bash
./scripts/run.sh --name "小米蓝牙语音遥控器"
```

当终端显示：

```text
桥接已就绪：按遥控器语音键开始说话
```

就可以按住说话、说完松手。米遥会激活 Codex，只在找到唯一编辑器时粘贴并回车。

## 4B. 接入其他遥控器

先扫描：

```bash
./scripts/capture.sh --scan-seconds 30
```

记下终端中的 macOS peripheral UUID，然后采集：

```bash
./scripts/capture.sh --identifier <UUID> --capture-seconds 60 --debug
```

在 60 秒内测试短按、按住说话后松手、第二次按键和静音。报告保存在：

```text
~/Library/Application Support/mi-ao/captures
```

报告默认脱敏设备 UUID 和名称，但 `events.jsonl` 可能仍含原始设备数据。分享前必须人工复核。完整流程见 [真机 Bring-up](HARDWARE_BRINGUP.md)。

## 5. 可选：校准默认指针套装

先完成语音验证，再停止米遥并运行：

```bash
./scripts/debug-buttons.sh \
  --name "小米蓝牙语音遥控器" \
  --preset pointer
```

至少确认方向四键、中间确认和返回六项。完成后重新运行日常命令，米遥会自动合并人工确认档案并尝试启用默认 `pointer` 套装。缺少任何必需项或出现重复 Usage 时，指针动作不会启动，语音链路继续可用。

需要用 `TV` 切换“鼠标 / 方向键”或用电源键启动 Codex 时，再分别执行 `--button tv` 和 `--button power` 单键校准。小米 2 Pro 固件 2671 的已验证值是 `TV=0x07/0x35`、电源 `0x07/0x66`；其他遥控器若没有 HID 事件、只发红外信号，则无法由 Mac 映射。

当前指针模式仍是 implementation preview；需要完全禁用实体按键动作时增加 `--no-buttons`。完整映射表、逐键校准和 macOS 事件过滤边界见 [按键预设与默认指针模式](BUTTON_PRESETS.md)。

## 常用选项

```bash
# 只转写，不发送给 Codex
./scripts/run.sh --name "<设备名>" --no-submit

# 覆盖 Whisper 术语提示
./scripts/run.sh --name "<设备名>" --prompt "米遥。Codex。你的项目术语。"

# 打印原始 GATT 数据，仅用于调试
./scripts/run.sh --name "<设备名>" --debug

# 明确只使用语音链路
./scripts/run.sh --name "<设备名>" --no-buttons
```

## 验证、停止和卸载

```bash
./scripts/verify-install.sh
```

- 停止当前桥接：在运行终端按 `Control + C`。
- 卸载 App 但保留模型和录音：`./scripts/uninstall.sh`
- 删除所有本地数据：`./scripts/uninstall.sh --all-data`

安装完成后请继续阅读 [完整使用说明](USAGE.md)；遇到问题查看 [故障排查](TROUBLESHOOTING.md)。
