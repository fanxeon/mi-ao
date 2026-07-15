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
./scripts/run.sh --name "小米蓝牙语音遥控器" --no-buttons
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

## 5. 启用默认指针套装

小米蓝牙遥控器 2 Pro 固件 2671 已内置十二键真机档案，首次安装不需要重新校准。直接运行：

```bash
./scripts/start.sh
```

后台启动脚本会先执行 `check-buttons`。只有辅助功能权限和按键运行时都可用时，才会从同一份硬件档案生成并应用系统中性映射；检查失败时系统保持原状。启动后在菜单栏查看搜索、连接、录音、后台转写和发送状态。

如果同型号按键结果与文档不符、固件不同，或你要为其他遥控器建立档案，再停止米遥并运行校准：

```bash
./scripts/debug-buttons.sh \
  --name "小米蓝牙语音遥控器" \
  --preset pointer
```

本地确认结果会按时间覆盖内置基线。显式标记未观察到、缺少必需按钮或出现重复 Usage 时，米遥会拒绝接管按键并保持系统映射不变，不会悄悄退回可能错误的内置键码。

只复测某一个键时可使用 `--button tv` 或 `--button power`。小米 2 Pro 固件 2671 的已验证值是 `TV=0x07/0x35`、电源 `0x07/0x66`；其他遥控器若没有 HID 事件、只发红外信号，则无法由 Mac 映射。

四个方向已验证直接光标定位与真实坐标移动；模式切换和电源动作逐项验收完成前，整套按键模式仍是 implementation preview。需要完全禁用实体按键动作时增加 `--no-buttons`。脚本不会覆盖已有的用户级 `UserKeyMapping`，退出时自动恢复。完整映射表和 macOS 事件过滤边界见 [按键预设与默认指针模式](BUTTON_PRESETS.md)。

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

- 停止当前桥接：菜单栏选择“安全退出并恢复遥控器”，或运行 `./scripts/stop.sh`。
- 卸载 App 但保留模型和录音：`./scripts/uninstall.sh`
- 删除所有本地数据：`./scripts/uninstall.sh --all-data`

安装完成后请继续阅读 [完整使用说明](USAGE.md)；遇到问题查看 [故障排查](TROUBLESHOOTING.md)。
