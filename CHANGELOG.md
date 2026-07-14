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
- 默认双控制模式：`TV` 在鼠标模式与方向键/Return/Escape 模式之间切换，米遥合成事件带来源标记以避免被自身过滤器拦截。
- 电源键启动 Codex，已运行时聚焦现有窗口；只有真机产生 HID 事件并完成人工校准时才启用。
- 小米 2 Pro 固件 2671 真机确认：`TV` 为 Keyboard Usage `0x07/0x35`，电源键为 Keyboard Power `0x07/0x66`，两者均观察到完整按下与松手。
- 设备专属 `hidutil` 中性映射：只匹配小米遥控器 2 Pro，将 `TV→F20`、`Power→F21`，保留 IOHID 原始 Usage，并拒绝覆盖既有用户映射。
- `run-with-mapping.sh` 一键会话：写入后回读验证，启动米遥，正常退出或信号中断时自动恢复；另提供 `status`、`restore` 和所有权状态文件恢复路径。
- 人工确认档案合并、必需六键完整性检查、重复 Usage 冲突拒绝和 `--button-profile` / `--no-buttons` 启动控制。
- 鼠标执行器、长按加速曲线和遥控器原始键盘事件的短时关联抑制；任何权限、档案或过滤器失败均只停用实体按键动作，语音链路继续运行。

### Changed

- 项目正式定名为「米遥 / MI-AO」，仓库与 CLI 标识统一为 `mi-ao`。
- App 身份更新为 `米遥.app` / `com.fanx.miao`，并加入旧原型模型、录音和 App 的安全迁移。
- `setup.sh` 安装完成后优先展示已验证小米遥控器的日常启动命令，其他设备先进入脱敏采集流程。
