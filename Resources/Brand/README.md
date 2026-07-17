<!-- Copyright (c) 2026 FanXeon@Poemcoder with Codex -->

# 米遥 MI-AO 品牌资产

本目录保存随 App Bundle 发布的正式品牌资产。官方主标识为第 06 款「中心连接」：中心圆环对应遥控器确认键，八个连接线同时表达方向操作、信号与 Agent 连接。

## 资产清单

| 文件 | 用途 | 规则 |
| --- | --- | --- |
| `mi-ao-symbol-gradient.svg` | 官方可缩放母版 | 网页、README、印刷与后续导出优先使用 |
| `mi-ao-symbol-gradient-1024.png` | 1024 px 透明位图 | 不支持 SVG 的场景 |
| `mi-ao-symbol-template.svg` | macOS 单色模板母版 | Toolbar 和 24 px 以上单色系统控件 |
| `mi-ao-symbol-template-1024.png` | 1024 px 透明单色位图 | App 运行时的单色资源备份 |
| `mi-ao-menubar-sun-template.svg` | macOS 菜单栏专用模板 | 基于 Lucide Sun 的 24×24 光学母版；运行时以 17 pt 居中显示 |
| `LUCIDE_LICENSE.txt` | 菜单栏图标第三方许可 | 随 App Bundle 保留 Lucide ISC 许可 |
| `../AppIcon/AppIcon-1024.png` | macOS AppIcon 母版 | 白色圆角方形底板，由构建脚本生成 `.icns` |

历史设计证据和实际选中参考图保存在：

- `docs/assets/brand/mi-ao-logo-concepts-01-09.png`：九款原始概念板，不作为对外导出母版。
- `docs/assets/brand/mi-ao-logo-06-reference.png`：06 「中心连接」的原始选中区域，用于设计对照。
- `docs/assets/mi-ao-logo.png`：README 直接使用的透明 PNG。

## 视觉规则

- 品牌主色：`#1473FF` 至 `#7B61FF` 线性渐变。
- 保护空间：图形四周至少留出中心圆环直径的一半。
- 建议最小尺寸：渐变版 24 px；更小尺寸使用单色模板版。
- 不拉伸、不旋转、不改变线条比例，不在 AppIcon 内塞入「米遥 / MI-AO」文字。
- 菜单栏必须使用单色 Template Image，不强制指定白色、黑色或蓝紫渐变；深浅菜单栏的前景色交给 macOS 自动处理。
- 菜单栏专用图标保持 Lucide 原始 `2 / 24` 笔画比例，以 17 pt 光学尺寸居中；不要直接缩放 1024 px 品牌母版代替。
- 原「魔法棒」图形保留为传播插画与「Codex 魔法棒」隐喻，不再作为官方 Logo。
- 「米遥 MI-AO」字标暂不从概念图反向追踪为矢量；在字体授权与字形连笔定稿前，正式资产只以图形标识为准。

## 版权

Created and maintained by **FanXeon@Poemcoder with Codex**.

`Copyright (c) 2026 FanXeon@Poemcoder with Codex`

米遥是独立开源项目。这些资产不得与小米、Google 或 OpenAI 的官方 Logo 混用，也不表示任何官方合作或背书。
