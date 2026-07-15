<!-- Copyright (c) 2026 FanXeon@Poemcoder with Codex -->

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
- transcript 为空、Codex 未运行、辅助功能未授权或无法证明当前输入区唯一时不发送；
- 用户关闭自动发送与按键控制后，辅助功能与 Codex 都降为可选；蓝牙和本地语音引擎仍为核心必需；
- 当前 Codex 版本需要通过 `--force-renderer-accessibility` 公开当前进程的网页辅助功能树；米遥仍只在其中存在唯一可用文本输入控件时发送；
- `codex-accessibility.sh enable` 只使用 Codex 自带的本次进程启动参数，不修改偏好设置、不开放远程调试端口，Codex 退出后自然失效；`disable --restart` 会按原生方式重启；
- 文本仍通过受保护的剪贴板粘贴链路进入 Codex，米遥不读取会话正文；
- `--force-submit` 会放宽焦点验证，只应在受控环境使用；
- 原始 WAV 和 transcript 可能含隐私，默认保存在本机，不应提交到 Git。
- 录音目录设置为 `0700`，WAV、最终 transcript 和 Whisper 原始文本设置为 `0600`。它们仍属于敏感本地数据，用户应自行决定保留周期。
- `preferences.json` 使用 schema v1、原子写入和 `0600`；损坏配置会隔离而不是执行，未来 schema 不会被旧版覆盖。
- 自动提交只在短时间内临时替换剪贴板；恢复前检查 `changeCount`。若用户或其他 App 已写入新内容，米遥保留新剪贴板而不会覆盖。
- `capture` 默认哈希化 peripheral UUID 并隐藏设备名；只有显式传入 `--include-identifiers` / `--include-device-names` 才保留原值。
- `events.jsonl` 包含未知 GATT payload，这些字节可能承载按键、音频或设备数据；即使身份已脱敏，也必须人工复核后才能公开分享。
- 已验证的小米 2 Pro 默认加载仓库内置固件 2671 真机档案；本地人工确认档案按时间覆盖基线。显式失效、Usage 冲突或辅助功能权限失败都会阻止实体按键运行。
- `run-with-mapping.sh` 在写入前先执行 `check-buttons`；运行时未就绪时不修改系统。通过后只修改精确匹配的小米遥控器 HID service，要求原映射为空、写入后回读验证，并用本地所有权状态控制恢复。未知或用户自定义映射既不会被覆盖，也不会被清除。
- 正常提交启动还会先执行 Codex 兼容门禁：未运行时可按兼容方式启动，已运行但缺少参数时拒绝继续，不会为米遥擅自重启正在工作的 Codex；`--no-submit` 不需要该门禁。
- `run-with-mapping.sh` 使用带会话 token 的单实例锁，锁中记录真实 App PID；`start.sh`、`stop.sh`、菜单栏安全退出、App 正常退出和外层包装器都执行所有权校验恢复，避免两个进程争用蓝牙和映射所有权。
- `--no-buttons`、`--help` 和普通 `run.sh` 不会应用中性映射；卸载会先尝试恢复米遥拥有的映射。
- 实体按键模式会接管方向、确认、返回、HOME、TV、电源、语音和音量加减共十二键，通过设备专属 HID `No Event` 阻止原生副作用；菜单不会被覆盖并沿用 macOS 原生鼠标右键。米遥不建立全局键盘 event tap，也不会监听或拦截 Mac 实体键盘按键。敏感编辑工作中请使用 `--no-buttons`。
- 登录启动永远可选，只使用系统 `SMAppService.mainApp`，不写自建 LaunchAgent、不请求管理员权限；ServiceManagement 是唯一真相来源。
- 登录与手动启动调用同一 App 内置门禁，不绕过辅助功能、按键检查或映射恢复；ad-hoc 更新改变身份时允许注册失败并提示重新注册，不使用宽松代码要求绕过系统。
