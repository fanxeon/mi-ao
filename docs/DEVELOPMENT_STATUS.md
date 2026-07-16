<!-- Copyright (c) 2026 FanXeon@Poemcoder with Codex -->

# 开发进度 / Development Status

> 最近核对：2026-07-16 · 当前版本：`0.2.0` · 交付阶段：**source-first beta · V2**

本页只记录已由真实代码、自动测试、安装产物或既有真机证据支持的状态。实现完成不等于物理场景已穷尽验收。

## 当前结论

米遥 V2 已把设备、按键配置、设置体验和安装更新从“有界面”收口为真实运行合同：

- 真实 CoreBluetooth 扫描、用户选择与 UUID 持久化；多设备按固定设备、ATVV 能力、信号和 UUID 稳定仲裁。
- 普通断连不再终止运行时，而是显示尝试次数与下次延迟并分级重连。
- GATT 已连接但 `GET_CAPS` 通知丢失时不再永久卡住：能力协商最多重试 3 次，超时后显示原因并进入同一分级重连链路；重连先复用已保存 UUID 或系统已连接 ATVV 设备，再回退到广播扫描。
- 按键方案保存后通过运行时通知立即热重载；真实 HID 按下/松开驱动界面高亮；测试按钮只显式执行一次当前动作。
- 菜单栏同时保留基础运行态和短暂指令态：实体按键执行器按真实动作/结果回传对应图标与蓝、绿、红圆角底色；录音、转写、断连和错误不会被普通指令覆盖。
- 过短录音取消后会立即从“正在听你说话”恢复就绪；转写队列已满或缺失时显示真实错误，不再留下过期录音状态。
- JSON 导入/导出已交付；导入限制 1 MB 且在写入前验证 schema、按键集、保留键、TV 目标、快捷键安全规则与完整 catalog。
- 首次设置与日常管理使用不同文案和主操作；窗口可缩放到 380 px，内容在 390 px 已完成真实页面检查。
- 安装器拒绝覆盖运行中 App，先分期和校验签名，再原子替换；失败恢复旧 App 和旧安装上下文。
- Whisper base 模型使用 Shell / App 共用的单一 SHA-256 契约；下载、设置就绪状态、转写器启动边界与安装验证全部重新校验。
- 日常运行进程由 LaunchServices 启动并进入真实 AppKit 事件循环；重复双击会把现有设置窗口带到前台，实际 App PID 由带令牌运行锁登记，退出仍由原会话恢复映射。
- Swift tools 和语言模式均统一为 Swift 6；CI 执行和本地相同的 `make check`。

| 阶段 | 状态 | 真实边界 |
| --- | --- | --- |
| P0 · 核心语音与品牌 | ✅ 完成 | 小米 2 Pro 固件 2671 真机语音 → Whisper → Codex 链路和公开资产已有证据 |
| P1 · Preferences 与日常启动 | 🟡 实现完成 | v2 持久化、权限分级、安装运行根和 `SMAppService` 真实状态已实现；重新登录需用户系统会话验收 |
| P2 · 自定义动作内核 | ✅ 完成 | 持久化、TV 跳转、危险组合拒绝、修饰键清理、导入导出和运行时热重载已有测试 |
| P3 · 按键 GUI | ✅ 完成 | 编辑、快捷键录制、真实 HID 高亮、单次测试、导入导出和 390 px 布局已交付 |
| P4 · 设备与稳定连接 | 🟡 实现完成 | 扫描、选择、持久化、确定性仲裁和重连已实现；8 小时压测与第二设备真机证据未完成 |
| P5 · 安装与运维 | 🟡 部分完成 | 自包含运行根、原子更新回滚和模型校验已完成；无 Developer ID 签名、公证和自动更新服务 |
| P6 · 1.0 发布门禁 | ⬜ 未完成 | 第二类真机、空白 macOS 账户、长时间压测和正式签名分发仍是 1.0 门禁 |

## 当前仍不能对外声称

- 不能声称已经完成 Developer ID 签名、Apple 公证、免源码自动更新或无摩擦 DMG 分发。
- 不能声称支持第二类遥控器，直到有可复核真机证据。
- 不能把登录项单元测试等同于已完成 macOS 注销/重新登录验收。
- 不能把重连策略测试等同于 8 小时干扰环境压测。

## 本批验证门禁

- `VERSION`、Info.plist、Swift 6 语言模式、CI 入口和共用模型 SHA 文件由 `ReleaseContractTests.sh` 防漂移。
- 66 个 Swift 用例覆盖状态机、菜单栏指令优先级/结果色、设备仲裁、能力协商重试、重连退避、HID 事件配对、运行启动参数、运行进程登记/reopen、导入导出、热重载和转写前模型篡改拒绝。
- 9 组 shell 门禁覆盖任意 `MI_AO_*` 环境隔离、LaunchServices 启动参数与真实 PID 交接、Codex 启动、映射异常恢复、损坏模型不替换、安装拒绝/首装/回滚、App Bundle 和签名。
- 最新 `dist/米遥.app` 已在当前已连接小米遥控器上经 LaunchServices 进入 `ATVV v1.0 / ADPCM 16 kHz / 120 B` 就绪；运行中再次打开真实显示设置窗口，TERM 后 App 与 `open -W` 均立即结束，系统映射保持原始空状态。
- `/Users/fanx/Applications/米遥.app` 0.2.0 已完成真实签名/运行根/148 MB 模型 hash 验证、已连接小米遥控器识别、GATT 枚举和 ATVV v1.0 / ADPCM 16 kHz 就绪，以及指定不存在 UUID 时 `1 → 2 → 4 → 8 → 16` 秒的真实重连反馈。
- 安装更新后新 ad-hoc 身份未继承旧授权时，App 自身真实阻止全功能启动；终端子进程的权限结果不当作 App 验收证据。最终安装包已重新获得辅助功能与蓝牙授权；安装版热重载、协商超时退避、已连接设备恢复、安全退出和全功能启动已有现场证据。实体方向/OK/TV/语音均收到完整 `down/up`；真实方向上执行时菜单栏瞬时显示“移动鼠标 · 上”，短录音取消后恢复就绪。逐项证据见 [V2 交付收口审计](V2_COMPLETION_AUDIT.md)。

## English snapshot

MI-AO `0.2.0` is the source-first V2 beta. Real device selection, persisted identity, deterministic arbitration, visible reconnect backoff, runtime preset hot reload, real HID highlighting, one-shot tests, validated JSON transfer, atomic app rollback, pinned model verification, and Swift 6 mode are implemented. Developer ID distribution, a second verified remote class, relogin acceptance, and long-duration hardware stress remain outside the verified boundary.

作者与维护 / Created and maintained by **FanXeon@Poemcoder with Codex**.
