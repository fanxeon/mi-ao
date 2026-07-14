<!-- Copyright (c) 2026 FanXeon@Poemcoder with Codex -->

# 故障排查

[English](TROUBLESHOOTING_EN.md) · [快速开始](QUICKSTART.md)

## 先运行诊断

```bash
./scripts/verify-install.sh
```

它会检查 App、Bundle ID、签名、Codex 进程、蓝牙权限、辅助功能、`whisper-cli` 和模型。

## 启动后找不到遥控器

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
