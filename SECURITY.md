# 安全策略

[中文](SECURITY.md) · [English](SECURITY_EN.md)

## 支持范围

安全修复只保证覆盖 `main` 和最新正式版本。早期预览版可能要求先升级。

## 报告漏洞

请不要通过公开 Issue 披露可被利用的漏洞、录音内容、设备标识或权限绕过方法。仓库发布到 GitHub 前，维护者必须启用 **Private vulnerability reporting**；发布后请通过仓库的 Security 页面私下报告。

报告应包含：

- 受影响版本或 commit；
- macOS、Codex 和遥控器版本；
- 最小复现步骤；
- 影响范围；
- 已做的脱敏处理。

## 安全边界

- 默认只向 `com.openai.codex` 发送文本；
- transcript 为空、Codex 未运行、辅助功能未授权时不发送；
- 默认仅当 Codex 可访问性树中存在唯一可用文本输入控件时，才会主动聚焦并发送；
- `--force-submit` 会放宽焦点验证，只应在受控环境使用；
- 原始 WAV 和 transcript 可能含隐私，默认保存在本机，不应提交到 Git。
- `capture` 默认哈希化 peripheral UUID 并隐藏设备名；只有显式传入 `--include-identifiers` / `--include-device-names` 才保留原值。
- `events.jsonl` 包含未知 GATT payload，这些字节可能承载按键、音频或设备数据；即使身份已脱敏，也必须人工复核后才能公开分享。
