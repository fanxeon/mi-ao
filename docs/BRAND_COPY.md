# 品牌与发布文案 / Brand Copy

这份文档是米遥公开传播的单一文案来源。README、GitHub About、Social Preview、Release 和社区发布帖优先复用这里的表达，不临时发明互相冲突的口号。

## 固定身份

- 产品名：**米遥 MI-AO**
- 项目署名：**FanXeon@Poemcoder with Codex**
- 版权：`Copyright (c) 2026 FanXeon@Poemcoder with Codex`
- 仓库：`fanxeon/mi-ao`
- 核心硬件：小米蓝牙遥控器 2 Pro，固件 2671
- 核心动作：按住说话，松手发送

## 首页主文案

**中文 Hero**

> 在 Vibe Coding 时代，把小米蓝牙遥控器 2 Pro 变成一根真正握在手里的 Codex 魔法仙女棒。

**中文副文案**

> 按住说话，松手发送。本地 Whisper 完成转写，Codex 立即开工。

**English Hero**

> In the Vibe Coding era, turn a Xiaomi Bluetooth Remote Control 2 Pro into a real, hold-in-your-hand magic wand for Codex.

**English subline**

> Hold to talk. Release to send. Transcribed locally with Whisper. Delivered safely to Codex.

## 短文案

### GitHub About

```text
Turn a Xiaomi Bluetooth Remote Control 2 Pro into a local push-to-talk magic wand for Codex on macOS.
```

### 中文一句话

```text
使用小米蓝牙遥控器 2 Pro 构建的 Codex 本地语音输入方案。
```

### Social Preview

```text
MI-AO
A real magic wand for Vibe Coding
```

### 作者署名

```text
Created by FanXeon@Poemcoder with Codex
```

## 项目介绍

### 中文

米遥 MI-AO 是由 **FanXeon@Poemcoder with Codex** 创建的开源 macOS 项目。它读取小米蓝牙遥控器 2 Pro 自带麦克风的 BLE 语音数据，在 Mac 上完成 ADPCM 解码与本地 Whisper 转写，再把结果安全发送到 Codex。无需拿起手机，也无需先寻找屏幕上的麦克风按钮——按住、说话、松手，Agent 就开始工作。

### English

MI-AO is an open-source macOS project created by **FanXeon@Poemcoder with Codex**. It reads BLE audio from the microphone inside a Xiaomi Bluetooth Remote Control 2 Pro, decodes and transcribes it locally with Whisper, then safely submits the result to Codex. No phone and no on-screen microphone hunt: hold, speak, release, and let the agent work.

## 首发帖

### 中文版

```text
我把小米蓝牙遥控器 2 Pro 变成了一根 Codex 魔法仙女棒。

按住语音键说需求，松手后在 Mac 本地完成转写，文字自动进入 Codex。不是调用 Mac 麦克风，也不是云端语音 API，而是直接使用遥控器自己的 BLE 麦克风链路。

第一台真机已经完整跑通：ATVV → ADPCM → Whisper → Codex。

项目：米遥 MI-AO
作者：FanXeon@Poemcoder with Codex

如果你手里也有一支闲置的电视语音遥控器，欢迎来点亮它。
```

### English version

```text
I turned a Xiaomi Bluetooth Remote Control 2 Pro into a real magic wand for Codex.

Hold the voice button, speak, and release. MI-AO decodes the remote's own BLE microphone audio, transcribes it locally on the Mac, and safely submits the result to Codex. No Mac microphone disguise and no speech cloud API.

The first real device now works end to end: ATVV → ADPCM → Whisper → Codex.

MI-AO — created by FanXeon@Poemcoder with Codex.

If a voice remote is collecting dust in your drawer, help us light it up next.
```

## Star 行动文案

优先使用：

> 如果你也相信 Vibe Coding 应该有一根真正握在手里的魔法仙女棒，欢迎 Star，并告诉我们下一款应该点亮哪支遥控器。

不使用“求 Star”“冲榜”“互赞”等表达。Star 的理由必须来自真实演示、可复制安装和清楚的后续价值。

## 表达边界

必须明确：

- 真正使用遥控器自带麦克风，不把 Mac 麦克风包装成硬件能力；
- 当前端到端验证的是小米蓝牙遥控器 2 Pro 固件 2671；
- 语音转写默认在本机完成；
- 当前是 source-first alpha，不宣传成免配置正式产品；
- 项目由 FanXeon@Poemcoder 创建和维护，Codex 是 AI 工程协作者；
- 项目不是小米、Google、OpenAI 或 Codex 官方项目，也不受其背书。

避免使用：

- “支持所有蓝牙遥控器”；
- “零配置”“绝不误发”“百分之百识别”；
- “OpenAI 联合开发”或任何可能暗示官方合作的说法；
- 没有真实录像支撑的性能、延迟和准确率数字。
