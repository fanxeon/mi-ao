# 名称候选

项目名应表达“一个实体动作把人的意图交给 AI Agent”，同时避免绑定小米、Codex、BLE 或某一种遥控器。

## 推荐顺序

| 名称 | 仓库名 | 一句话 | 初步情况 |
| --- | --- | --- | --- |
| **PressToAct** | `press-to-act` | Hold. Speak. Ship. | GitHub 无同名仓库；公开搜索无同名软件；`.com` 当前未注册 |
| **PromptTether** | `prompt-tether` | Your physical line to AI agents. | GitHub 无同名仓库；公开搜索无同名软件；`.com` 当前未注册 |
| **PushToAgent** | `push-to-agent` | Push to talk. Release to run. | GitHub 无同名仓库；名称描述性较强；`.com` 当前未注册 |
| **HoldToAct** | `hold-to-act` | One hold between intent and execution. | GitHub 无同名仓库；公开搜索无同名软件；`.com` 当前未注册 |
| **PromptFob** | `prompt-fob` | AI work at your thumb. | GitHub 无同名仓库；公开搜索无同名软件；`.com` 当前未注册 |

初步检索日期：2026-07-13。GitHub 结果来自全局仓库名称检索；`.com` 状态通过 Verisign RDAP 查询。结果会变化，也不等同于商标法律审查或域名预留。

## 当前建议

首选 **PressToAct**：动作感强、容易读写、和“按住说话，松手执行”的交互一致，而且未来可以扩展到按钮、耳机、脚踏板等输入设备。

如果更看重品牌独特性，选 **PromptTether**；如果更看重开源用户一眼理解，选 **PushToAgent**。

## 定名后的迁移范围

只执行一次统一迁移：

- Swift package、target 和 executable；
- App 显示名与 Bundle ID；
- 模型缓存和录音目录；
- Accessibility 授权目标；
- README、仓库名、Release 包名和 GitHub topics；
- 菜单栏文案与未来图标。

在名称确认前保留原型 App 身份，避免反复触发 macOS 辅助功能授权。
