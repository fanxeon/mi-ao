# 截图清单与使用建议

所有截图均采集于 2026-07-18，来自本次真实网页访问和已安装的米遥 `0.2.2`。未使用生成式界面或旧截图。

## 官网截图

| 文件 | 状态 | 用途 |
| --- | --- | --- |
| `screenshots/website/01-home-desktop.png` | 可用于审计 | 1280×720 桌面首屏 |
| `screenshots/website/03-workflow-desktop.png` | 仅用于审计 | Hero 尾部与明显空白区域 |
| `screenshots/website/04-workflow-steps-desktop.png` | 可用于审计 | 桌面三步工作链路 |
| `screenshots/website/05-controls-desktop.png` | 可用于审计 | 控制预设与 source-first 文案 |
| `screenshots/website/06-compatibility-desktop.png` | 可用于审计 | 兼容性与页尾 |
| `screenshots/website/07-home-mobile-390.png` | 可用于审计 | 390×844 移动首屏 |
| `screenshots/website/08-product-mobile-390.png` | 仅用于审计 | 移动端固定滚动段，约 `scrollY=720` |
| `screenshots/website/09-workflow-mobile-390.png` | 仅用于审计 | 约 `scrollY=2220`，画面仍几乎相同，用于证明固定段过长 |
| `screenshots/website/10-workflow-mobile-late-390.png` | 可用于审计 | 移动端控制与 source-first 区块 |
| `screenshots/website/11-steps-mobile-390.png` | 可用于审计 | 移动端工作步骤 |
| `screenshots/website/12-mobile-navigation-390.png` | 可用于审计 | 移动菜单及错误的首页 active 状态 |

## 米遥 App 截图

| 文件 | 推荐程度 | 建议标题与 alt 文本 |
| --- | --- | --- |
| `screenshots/app/01-settings-overview.png` | 备选 | 米遥设置与诊断的日常管理总览 |
| `screenshots/app/02-permissions-connection.png` | 推荐 | 米遥设备选择、macOS 与本地语音引擎检查 |
| `screenshots/app/03-permissions-connection-bottom.png` | 主图 | 米遥蓝牙、Codex 输入区与启动组件全部通过检查 |
| `screenshots/app/04-usage-preferences.png` | 主推 | 米遥自动发送、按键控制及随时就绪和智能休眠设置 |
| `screenshots/app/05-button-configuration.png` | 主推 | 米遥默认按键配置与自定义配置入口 |
| `screenshots/app/06-button-mapping-list.png` | 备选 | 米遥逐项按键动作与单次测试列表 |
| `screenshots/app/07-button-guide.png` | 主推 | 小米蓝牙遥控器 2 Pro 的米遥完整按键指南 |

## 发布使用规则

- 官网只使用 `app/` 下的真实 App 截图；`website/` 仅用于改版前审计和对照。
- 不要抹掉真实状态、版本号或平台限制。
- 不要把权限全部通过的画面解释为所有用户首次打开都会自动通过。
- 可以轻微裁掉窗口边缘和底部固定 footer，但不得裁掉当前 Tab、功能标题或关键状态。
- 不要加入假的鼠标点击、假的成功 Toast 或静态可交互控件。
- 图片需提供表格中的准确 alt 文本，不使用“截图”“图片”等无信息描述。

