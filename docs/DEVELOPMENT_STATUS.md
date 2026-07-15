<!-- Copyright (c) 2026 FanXeon@Poemcoder with Codex -->

# 开发进度 / Development Status

> 最近核对：2026-07-15 · 当前版本：`0.1.0` · 交付阶段：**source-first alpha**

本页是米遥 MI-AO 的当前进度快照。它只记录已经由代码、测试或真机证据支持的状态；完整工作拆分见 [产品交付计划](PRODUCT_DELIVERY_PLAN.md)，逐项功能见 [路线图](ROADMAP.md)。

## 当前结论

米遥已经完成“小米蓝牙遥控器 2 Pro → 本地语音转写 → Codex”的真实核心闭环，并具备首次设置向导、菜单栏状态、自包含 App 运行组件、设备专属按键接管和安全恢复。当前仍不是面向普通用户的免配置正式版：配置持久化、登录启动、设备选择和自定义快捷键尚未交付。

| 阶段 | 状态 | 真实边界 |
| --- | --- | --- |
| P0 · 发布基线与品牌资产 | ✅ 完成 | 真机语音链路、自包含 App、设置向导、菜单栏、06 品牌资产和公开文档已落库 |
| P1 · Preferences 与日常启动 | ⏭️ 下一阶段 | 数据合同已设计；持久化、迁移、损坏回退和 `SMAppService` 尚未实现 |
| P2 · 自定义动作内核 | 📝 已设计 | `KeyboardShortcutSpec`、安全边界和验收合同已写入文档，代码尚未实现 |
| P3 · 按键与快捷键 GUI | 📝 已设计 | 用户动线已确定，编辑器、录制器和热重载尚未实现 |
| P4 · 设备管理与稳定连接 | 🟡 部分具备 | 运行中断连会重新扫描；可视化设备选择、持久化和多设备分支尚未实现 |
| P5 · 普通用户安装与运维 | 🟡 部分具备 | 首次向导和自包含运行根已完成；更新检查、无终端全流程和诊断包尚未完成 |
| P6 · 1.0 发布门禁 | ⬜ 未进入 | 第二类真机、干净 Mac 验收、完整安全审查和可选签名分发仍待完成 |

## 已交付能力

### 语音与 Codex

- 小米蓝牙遥控器 2 Pro 固件 2671 已完成真实按住、说话、松手和 Codex 收到消息的端到端验证。
- ATVV v0.4/v1.0、ADPCM 解码、16 kHz WAV、本地 `whisper.cpp` 和后台串行转写队列已经实现。
- Codex 只有在辅助功能树存在唯一可用输入区时才自动发送；否则安全回退为复制文字。
- 录音目录权限为 `0700`，WAV 和 transcript 为 `0600`，不会自动上传。

### 遥控器按键

- 固件档案与动作预设已经分层；重新定义动作不会污染硬件校准证据。
- 方向环支持鼠标移动和方向键两种模式，`TV` 只切换方向环。
- 确认固定 Return，返回固定 Escape，HOME 单击 Page Down / 双击 Page Up。
- 音量加减切换 Codex 上一个/下一个任务，电源启动或聚焦 Codex。
- 菜单继续使用 macOS 原生鼠标右键，不进入米遥映射。
- 退出、检查失败和信号中断会恢复设备专属映射；没有全局键盘事件拦截。

### App 与开源交付

- `~/Applications/米遥.app` 可由一条源码安装命令构建，App 内包含日常启停、映射门禁、恢复和语音修复组件。
- 设置向导检查 macOS、Whisper、辅助功能、蓝牙、Codex 输入区和安全启动组件。
- 菜单栏显示搜索、连接、就绪、录音、处理、发送和错误等真实状态。
- 06「中心连接」Logo 已保存为 SVG、PNG、单色模板和 AppIcon；九款原始概念图完整归档。
- 中英文 README、快速开始、配对、使用、排错、安全、贡献和产品交付文档已经建立。

## 当前未交付

以下内容不能在 README、Release 或演示中描述为已经可用：

- 用户自定义快捷键与按键预设编辑器。
- 配置持久化、预设迁移、损坏隔离和运行中热重载。
- 「登录时启动」系统开关。
- GUI 设备选择、多设备仲裁和完整重连反馈。
- 自动更新、Developer ID 签名、公证和免源码二进制分发。
- 第二类真实遥控器兼容证明与完整多显示器/长时间压力测试。

## 当前开发批次

下一批代码严格按以下顺序推进：

1. **AppPreferences v1**
   - schema version、原子写入、权限、默认值和 Codable 合同；
   - 旧配置迁移、损坏文件隔离和上一份有效配置回退；
   - 保存提交模式、当前预设和后续目标设备标识。
2. **登录时启动**
   - 使用 macOS `SMAppService`；
   - 区分已启用、已关闭、等待系统确认和失败，不显示假成功；
   - 与设置向导和菜单栏使用同一个后端状态。
3. **自定义快捷键内核**
   - 内置动作与 `KeyboardShortcutSpec` 的版本化联合类型；
   - 用户预设 store、导入/导出、恢复默认和运行中重载；
   - 修饰键按下/释放对称、异常中断清理和高风险组合拒绝。
4. **按键与快捷键 GUI**
   - 实体按键高亮、动作选择、快捷键录制和一次性测试；
   - 冲突警告、保存失败回退、复制/重命名/删除/导入/导出；
   - 中英文、VoiceOver、键盘导航和窄窗口验收。

## 下一批完成门禁

P1 与 P2 只有同时满足以下条件才可标记完成：

- 不修改用户配置时，当前默认按键行为完全不变。
- 配置保存后立即生效，App 重启后保持；损坏时回退而不是崩溃。
- 用户配置目录为 `0700`、文件为 `0600`，导入数据先校验再落盘。
- 登录启动状态来自 `SMAppService` 的真实返回。
- 快捷键只由目标遥控器触发，不影响 Mac 实体键盘，不残留修饰键。
- 自动测试、本地 `make check` 和 GitHub Actions CI 同步通过。
- README、使用说明、排错、安全策略、路线图和 Changelog 同步更新。

## English snapshot

MI-AO `0.1.0` has a verified Xiaomi Remote 2 Pro firmware 2671 voice-to-Codex path, a self-contained source-built app, setup guidance, menu-bar runtime state, device-specific button interception, and safe restoration. It is still a source-first alpha. Persisted preferences, Launch at Login, visual device selection, and user-defined keyboard shortcuts are designed but not implemented.

The active sequence is: **AppPreferences v1 → SMAppService login start → versioned custom-shortcut core → Buttons & Shortcuts GUI**. A feature moves to “complete” only after real persistence, failure recovery, keyboard-isolation tests, documentation, and CI all pass.

作者与维护 / Created and maintained by **FanXeon@Poemcoder with Codex**.
