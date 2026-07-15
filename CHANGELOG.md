<!-- Copyright (c) 2026 FanXeon@Poemcoder with Codex -->

# Changelog

本项目遵循 [Keep a Changelog](https://keepachangelog.com/en/1.1.0/)；稳定发布后采用语义化版本。

## [Unreleased]

### Added

- 米遥 VI 正式接入：从主视觉精确提取蓝紫魔杖 Logo，生成透明品牌资产和白色圆角 macOS AppIcon；构建时使用系统工具生成完整 `.icns` 并纳入 App Bundle 校验。
- CoreBluetooth 扫描、连接和完整 GATT 枚举。
- ATVV v0.4/v1.0 能力协商与语音会话。
- IMA/DVI ADPCM 解码、增益、重采样和 WAV 输出。
- 本地 whisper.cpp 中文转写。
- Codex Accessibility 安全提交与剪贴板回退：只有活动窗口存在唯一可用输入控件时才发送。
- 面向 Codex 26.707+ 的本次进程兼容脚本：使用 Codex 自带 `--force-renderer-accessibility` 参数，可一键启用、检查、关闭并重启，不修改偏好设置、不开放调试端口。
- Codex 输入控件诊断和修复提示：区分兼容参数未开启、权限缺失、没有输入控件和多个候选控件。
- 不打断工作的启动门禁：Codex 未运行时自动兼容启动；已运行但缺少参数时在修改遥控器映射前安全停止，绝不自动重启；`--no-submit` 可继续独立转写。
- macOS App 打包、诊断和授权命令。
- 首次设置向导：安装完成后自动打开，逐项验证 macOS、Whisper/模型、米遥辅助功能、蓝牙、Codex 输入区和安全启动组件；全部通过后才允许调用现有启动门禁。
- 菜单栏轻量 GUI：点击状态图标查看实时状态和方向环模式，并可聚焦 Codex、打开录音与文字记录、复查设置或安全退出恢复遥控器。
- App 自包含日常运行根：启停、Codex 兼容门禁、按键检查、设备映射恢复、语音引擎修复与硬件档案随 Bundle 签名封装，安装后不依赖源码目录原路径。
- 安装上下文 v2：`install-context.plist` 以 `0600` 记录内置 `runtimeRoot`、版本、签名指纹和可选源码根目录；向导优先验证并调用当前 App Bundle 中的固定脚本，同时仍可读取旧上下文。
- 辅助功能权限恢复：向导每 1.5 秒自动刷新真实 App 状态；源码更新导致 ad-hoc CDHash 变化时明确引导移除旧条目并重新添加当前 App，安装脚本同时记录并比较签名指纹。
- `authorize.sh` 改为通过 LaunchServices 打开真实米遥向导，`doctor` 明确标注 Terminal 子进程状态不能代替 App 自身权限，避免假阳性诊断。
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
- 菜单栏运行状态：搜索、连接、就绪、录音、后台转写、发送成功和错误均可见，并提供聚焦 Codex、打开记录、设置诊断和安全退出恢复。
- `start.sh` / `stop.sh` 后台日常启停，以及 `run-with-mapping.sh` 单实例锁，避免重复进程争用遥控器或映射所有权。
- 串行 `SpeechJobQueue`：Whisper 与 Codex 提交不再阻塞 BLE/HID 主线程；最多保留一条处理中和一条等待任务，第三条明确拒绝。
- 剪贴板并发保护：只有剪贴板仍是米遥注入版本时才恢复原快照，不覆盖用户刚复制的新内容。
- 录音目录 `0700`、WAV 和两类 transcript `0600`，并使用时间戳加 UUID 的唯一文件名。

### Changed

- 项目正式定名为「米遥 / MI-AO」，仓库与 CLI 标识统一为 `mi-ao`。
- App 身份更新为 `米遥.app` / `com.fanx.miao`，并加入旧原型模型、录音和 App 的安全迁移。
- `setup.sh` 安装完成后自动打开设置向导；双击已安装 App 进入向导而不是绕过按键门禁直接运行。
