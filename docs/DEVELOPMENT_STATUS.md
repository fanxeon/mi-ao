<!-- Copyright (c) 2026 FanXeon@Poemcoder with Codex -->

# 开发进度 / Development Status

> 最近核对：2026-07-16 · 当前版本：`0.1.0` · 交付阶段：**source-first alpha**

本页是米遥 MI-AO 的当前进度快照。它只记录已经由代码、测试或真机证据支持的状态；完整工作拆分见 [产品交付计划](PRODUCT_DELIVERY_PLAN.md)，逐项功能见 [路线图](ROADMAP.md)。

## 当前结论

米遥已经完成核心闭环，并交付 Preferences v2、按功能分级的权限门禁、仅转写/按键开关、`SMAppService` 登录启动实现，以及可保存的自定义按键配置。当前仍不是免配置正式版：登录启动和自定义方案仍缺真机验收，设备选择、导入导出和单次按键测试尚未交付。

| 阶段 | 状态 | 真实边界 |
| --- | --- | --- |
| P0 · 发布基线与品牌资产 | ✅ 完成 | 真机语音链路、自包含 App、设置向导、菜单栏、06 品牌资产和公开文档已落库 |
| P1 · Preferences 与日常启动 | 🟡 部分完成 | v2 持久化、v1 迁移、损坏回退、权限分级和 `SMAppService` 已实现；安装版登录启动验收待完成 |
| P2 · 自定义动作内核 | 🟡 部分完成 | `KeyboardShortcutSpec`、TV 目标方案、私有 store、危险组合拒绝和修饰键清理已实现；导入导出待完成 |
| P3 · 按键与快捷键 GUI | 🟡 部分完成 | 已交付配置 Tab、创建/复制/重命名/删除、动作选择、快捷键录制、保存/选择；真机高亮、单次测试与跨 App 热重载待完成 |
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
- 「按键配置」Tab 可保存和选择多套用户方案；TV 可跳转到另一套方案并记住目标选择。
- 可录制标准键盘快捷键；危险退出、强制退出与锁屏组合被拒绝，松手和中断会对称释放修饰键。

### App 与开源交付

- `~/Applications/米遥.app` 可由一条源码安装命令构建，App 内包含日常启停、映射门禁、恢复和语音修复组件。
- 设置向导检查 macOS、Whisper、辅助功能、蓝牙、Codex 输入区和安全启动组件。
- 设置向导已采用 macOS 原生 Tab 容器，将“开始 / 权限与连接 / 控制偏好 / 按键配置 / 按键指南”分开呈现；内容区会随窗口剩余高度伸缩，所有卡片会随 macOS 浅色/深色外观实时重绘，提示条图标与文本垂直居中，footer 按“开始 → 权限与连接 → 控制偏好 → 按键配置”引导，第四个核心 Tab 完成设置并开始运行。
- 菜单栏显示搜索、连接、就绪、录音、处理、发送和错误等真实状态。
- 06「中心连接」Logo 已保存为 SVG、PNG、单色模板和 AppIcon；九款原始概念图完整归档。
- 中英文 README、快速开始、配对、使用、排错、安全、贡献和产品交付文档已经建立。
- Preferences v1 使用原子写入、`0700/0600`、损坏隔离和未来 schema 保护；登录启动只读取系统真实状态。

## 当前未交付

以下内容不能在 README、Release 或演示中描述为已经可用：

- 用户自定义预设的迁移、导入导出和跨 App 热重载。
- 真实按键高亮、单次测试与完整冲突诊断。
- 「登录时启动」在安装版完成重新登录与 ad-hoc 更新验收。
- GUI 设备选择、多设备仲裁和完整重连反馈。
- 自动更新、Developer ID 签名、公证和免源码二进制分发。
- 第二类真实遥控器兼容证明与完整多显示器/长时间压力测试。

## 当前开发批次

下一批代码严格按以下顺序推进：

1. **P1 安装版验收**
   - 在 `~/Applications/米遥.app` 启用登录项；
   - 验证重新登录后使用已保存偏好启动、关闭后不再启动；
   - 验证 ad-hoc 更新后真实提示重新注册，不继承假状态。
2. **自定义配置真机验收与扩展**
   - 双方案 TV 跳转、快捷键按下/松手/中断和 Mac 实体键盘回归；
   - 导入/导出、恢复默认与跨 App 热重载；
   - 真实按键高亮、单次测试与完整冲突诊断。

## 下一批完成门禁

P1、P2 与 P3 只有同时满足以下条件才可标记完成：

- 不修改用户配置时，当前默认按键行为完全不变。
- 配置保存后立即生效，App 重启后保持；损坏时回退而不是崩溃。
- 用户配置目录为 `0700`、文件为 `0600`，导入数据先校验再落盘。
- 登录启动状态来自 `SMAppService` 的真实返回。
- 快捷键只由目标遥控器触发，不影响 Mac 实体键盘，不残留修饰键。
- 自动测试、本地 `make check` 和 GitHub Actions CI 同步通过。
- README、使用说明、排错、安全策略、路线图和 Changelog 同步更新。

## English snapshot

MI-AO `0.1.0` now includes Preferences v2, feature-dependent permission gates, transcription/button switches, a truthful `SMAppService` login-item flow, and saved custom button configurations with TV preset transitions. Installed-app login-start acceptance, visual device selection, import/export, one-shot button testing, and real-device custom-preset acceptance remain incomplete.

The active sequence is: **installed-app login-start acceptance → custom-preset real-device acceptance → import/export, test, and hot-reload extensions**.

作者与维护 / Created and maintained by **FanXeon@Poemcoder with Codex**.
