<!-- Copyright (c) 2026 FanXeon@Poemcoder with Codex -->

# GitHub 首发方案

这份文档固定仓库公开时的产品身份、发现性和首发资产。目标不是在 README 里堆营销词，而是让真正有同类硬件的人在 10 秒内看懂并愿意试用。

## 仓库身份

- Owner：`fanxeon`
- Repository：`mi-ao`
- URL：`https://github.com/fanxeon/mi-ao`
- Default branch：`main`
- License：MIT
- Author credit：`FanXeon@Poemcoder with Codex`

仓库已于 2026-07-14 以 `fanxeon/mi-ao` 正式公开，本地 `origin` 已同步到正式地址，`main` CI 已通过。

### GitHub About

**Description**

```text
小米蓝牙遥控器 2 Pro × Codex for macOS：在 Vibe Coding 时代，把 Remote 变成真正握在手里的语音魔法仙女棒。
```

**Topics**

```text
accessibility
atvv
codex
macos
push-to-talk
remote-control
speech-to-text
swift
vibe-coding
voice-control
whisper-cpp
xiaomi-bluetooth-remote-2-pro
xiaomi-remote
```

Topics 只使用项目已真实涉及的技术和场景，不蹭无关热词。

## 首发视觉资产

### 1. README 真实演示

公开前录制一段 8–12 秒的无剪辑或少剪辑演示：

1. 画面同时看到小米 2 Pro 和 Codex 输入区；
2. 按住语音键，说“请检查当前项目并告诉我下一步”；
3. 松手；
4. 展示文字自动进入 Codex 并发送；
5. 不展示其他私人任务、设备地址或终端绝对路径。

优先使用 GitHub 支持的 MP4 附件，同时输出一张首帧 PNG 用于静态环境。没有真实演示前，不用假 UI 动画占位。

### 2. Social Preview

- 尺寸：1280 × 640 px；
- 背景：稳定的实色或深浅都可读的弱渐变；
- 主视觉：遥控器轮廓 + 语音波形 + Codex 光标；
- 主文案：`MI-AO`；
- 副文案：`A real magic wand for Vibe Coding`；
- 署名：`FanXeon@Poemcoder with Codex`；
- 不使用小米、Google 或 OpenAI 官方 Logo，避免造成背书错觉；
- PNG 小于 1 MB。

GitHub 建议社交预览图至少 640 × 320，1280 × 640 效果最佳。设置方式见 [GitHub Social Preview 官方文档](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/customizing-your-repositorys-social-media-preview)。

## 仓库设置

公开时启用：

- Issues；
- Discussions，分为 `Q&A`、`Hardware reports`、`Show and tell`；
- Private vulnerability reporting；
- Dependabot alerts 与 GitHub Actions updates；
- `main` branch protection：CI 必须通过、禁止 force push；
- 首个外部贡献者出现后，增加至少一次 review 要求。

不在未设置收款主体时提前放空的 Sponsors 按钮。

### 初始 Labels

```text
bug
enhancement
hardware
compatibility
privacy
documentation
good first issue
help wanted
```

其中 `hardware` 和 `compatibility` 必须在开放 Issue 前创建，否则设备支持表单无法自动附加标签。

## v0.1.0 Release 结构

**Title**

```text
MI-AO 0.1.0 — Remote-to-Codex hardware alpha
```

**Release 摘要**

1. 一句价值：把 BLE 语音遥控器变成 Codex 按住说话入口；
2. 已验证硬件：小米蓝牙遥控器 2 Pro，固件 2671；
3. 安装：源码优先、本地构建、ad-hoc 签名；
4. 安全：本地 Whisper、唯一编辑器门禁、失败时只复制；
5. 交付：已有首次设置向导、菜单栏 GUI 和不依赖源码原路径的 App 内置日常运行组件；尚无开机自启、Developer ID 与广泛硬件矩阵；
6. 贡献召集：寻找其他 ATVV 语音遥控器的脱敏证据。
7. 作者署名：`Created by FanXeon@Poemcoder with Codex`。

发布物只包含：

- GitHub source archive；
- `mi-ao-0.1.0.tar.gz`；
- `mi-ao-0.1.0.tar.gz.sha256`。

没有 Developer ID 前不发布未公证的 DMG。

## 首发节奏

1. 先公开仓库、通过 CI 并建立 v0.1.0 Release；
2. 用真实演示视频发布一篇中文和一篇英文说明；
3. 优先去对应的 macOS、Swift、蓝牙硬件和本地 AI 社区征集设备证据；
4. 不购买 Star、不互赞、不在无关 Issue 中广告；
5. 首周按真实 Issue 收紧快速开始和兼容矩阵，而不是急着堆功能。

中英文首发帖、Hero、About 和 Star 行动文案统一从 [BRAND_COPY.md](BRAND_COPY.md) 复制，避免每个平台出现不同定位。

## 首发门禁

- [ ] README 真实演示已录制并脱敏
- [ ] Social Preview 已上传
- [ ] 新 Mac 或新用户完整走通 `setup.sh`
- [x] README 所有命令可复制执行
- [x] 所有相对链接通过检查
- [x] 仓库不含 MAC、peripheral UUID、序列、用户名、私人语音或密钥
- [x] CI 和 source release 校验通过
- [x] Issues 和 Discussions 已启用
- [ ] Private vulnerability reporting 已启用
