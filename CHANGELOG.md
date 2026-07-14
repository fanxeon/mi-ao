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
- 实体按键学习、动作映射、命令面板和方向键指针模式路线图。
- 中英文完整使用说明：日常启动、成功日志、安全模式、术语提示、更新与数据清理。

### Changed

- 项目正式定名为「米遥 / MI-AO」，仓库与 CLI 标识统一为 `mi-ao`。
- App 身份更新为 `米遥.app` / `com.fanx.miao`，并加入旧原型模型、录音和 App 的安全迁移。
- `setup.sh` 安装完成后优先展示已验证小米遥控器的日常启动命令，其他设备先进入脱敏采集流程。
