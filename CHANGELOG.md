<!-- Copyright (c) 2026 FanXeon@Poemcoder with Codex -->

# Changelog

本项目遵循 [Keep a Changelog](https://keepachangelog.com/en/1.1.0/)；稳定发布后采用语义化版本。

## [Unreleased]

### Added

- CoreBluetooth 扫描、连接和完整 GATT 枚举。
- ATVV v0.4/v1.0 能力协商与语音会话。
- IMA/DVI ADPCM 解码、增益、重采样和 WAV 输出。
- 本地 whisper.cpp 中文转写。
- Codex Accessibility 安全提交与剪贴板回退。
- macOS App 打包、诊断和授权命令。
- 开源项目治理、CI 和贡献模板。
- `capture` 真机采集模式：脱敏扫描报告、GATT service/characteristic/descriptor 枚举、可读特征读取和 notify/indicate 原始事件。
- 小米蓝牙遥控器 2 Pro 的分阶段真机 Bring-up 与证据判定指南。
- 从常见 BLE 服务检索已连接但停止广播的 HID 遥控器。
- 兼容小米固件 2671 偶发的 ATVV v1.0 codecs 与 interaction model 字节对调 `CAPS_RESP`。
- 中文 Whisper 技术词上下文提示与 `--prompt` 自定义覆盖。
- Codex Electron 窗口中唯一可用文本编辑器的安全发现与主动聚焦。
- 中英文 README、快速开始、故障排查、安全策略、社区准则与贡献指南。
- 真实证据分级的硬件兼容矩阵、设备支持 Issue 表单和统一文档入口。
- GitHub 首发方案：仓库描述、Topics、真实演示、Social Preview、Release 和社区设置门禁。
- `FanXeon@Poemcoder with Codex` 全仓版权头、NOTICE、CODEOWNERS 和 `CITATION.cff`。
- Vibe Coding 魔法仙女棒中英文传播文案与可复用首发帖。
- 实体按键学习、可替换动作预设、命令面板和方向键指针模式路线图。
- 中英文完整使用说明：日常启动、成功日志、安全模式、术语提示、更新与数据清理。
- README 首屏、GitHub About 和品牌文案明确标注仅支持 macOS 14+。
- 中英文遥控器配对与首次连接指南：小米 2 Pro 菜单键 + HOME 长按、macOS 连接、权限、安全转写测试、Codex 真实提交和失败恢复。
- `learn-buttons` 真机 HID 按键学习：Vendor/Product 精确过滤、单键复测、数组式 Usage 规范化和脱敏 JSON 报告；返回键 `0x07/0xF1` 已完成独立真机验证。
- `debug-buttons` 校准调试模式：逐项展示 HID Usage 与当前预设动作，支持确认、重测、跳过和提前结束；不合成米遥动作，确认后只写入硬件身份档案。
- 硬件校准与动作预设分层：同一份人工确认档案可复用于不同按键方案，不把鼠标或 Codex 语义写死在设备证据中。
- 默认双控制模式：`TV` 只在“方向环移动指针”与“方向环发送上下左右”之间切换；确认始终是 Return，返回始终是 Escape，其他按键不随模式变化。
- 电源键启动 Codex，已运行时聚焦现有窗口；只有真机产生 HID 事件并完成人工校准时才启用。
- 小米 2 Pro 固件 2671 真机确认：`TV` 为 Keyboard Usage `0x07/0x35`，电源键为 Keyboard Power `0x07/0x66`，两者均观察到完整按下与松手。
- 设备专属 `hidutil` 中性映射：只匹配小米遥控器 2 Pro，将方向键、确认、返回、HOME、TV、电源、语音和音量加减映射为 HID `No Event`；菜单不进入米遥映射并沿用 macOS 原生鼠标右键。v1/v2/v3 旧映射可安全迁移和恢复。
- 音量加减完成 `0x07/0x80`、`0x07/0x81` 人工确认和双向动作真机验收，默认映射为 Codex 上一个/下一个会话。动作通过 Accessibility 直接执行 Codex 菜单项，不合成 `⌘⇧[` / `⌘⇧]`；系统音量保持不变，未观察到修饰键状态残留。
- HOME 完成 `0x07/0x4A` 人工确认并加入单/双击仲裁：单击在 350 ms 窗口结束后发送 Page Down，窗口内双击取消待执行的单击并只发送一次 Page Up。
- 内置小米 2 Pro 固件 2671 十二键硬件档案：干净安装无需先生成本地校准文件；本地人工确认仍可覆盖或显式失效内置基线。
- `check-buttons` 启动门禁：只有辅助功能权限和按键运行时都就绪后才应用系统中性映射，失败时保持系统原状。
- Swift 运行时和 `remote-mapping.sh` 共用同一硬件档案；App Bundle 与 CI 均校验档案被完整打包，消除两套键码漂移。
- `run-with-mapping.sh` 一键会话：写入后回读验证，启动米遥，正常退出或信号中断时自动恢复；另提供 `status`、`restore` 和所有权状态文件恢复路径。
- 方向四键、确认、返回完成新格式真机校准；修复无关 HID 零值提前结束动作的问题，并为短按增加立即位移。四个方向已验证 `CGWarpMouseCursorPosition` 返回成功且真实坐标按方向变化。
- 运行期 `--debug` 输出 HID Usage 到实体按钮的映射；一键脚本拦截 `Control+Z`，终止子进程并恢复映射，避免挂起后遥控器完全失效。
- 人工确认档案合并、必需六键完整性检查、重复 Usage 冲突拒绝和 `--button-profile` / `--no-buttons` 启动控制。
- 鼠标执行器、长按加速曲线和按键松开停止；移除会误吞 Mac 实体键盘事件的全局 Quartz 过滤器，原生副作用只通过精确设备 `No Event` 映射隔离。已在米遥运行期间完成 Mac 实体键盘 `e E` 真机回归，并加入禁止全局键盘 event tap 的 CI 门禁。

### Changed

- 项目正式定名为「米遥 / MI-AO」，仓库与 CLI 标识统一为 `mi-ao`。
- App 身份更新为 `米遥.app` / `com.fanx.miao`，并加入旧原型模型、录音和 App 的安全迁移。
- `setup.sh` 安装完成后优先展示已验证小米遥控器的日常启动命令，其他设备先进入脱敏采集流程。
