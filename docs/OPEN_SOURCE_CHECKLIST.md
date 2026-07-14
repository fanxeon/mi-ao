<!-- Copyright (c) 2026 FanXeon@Poemcoder with Codex -->

# 开源发布检查表

## 已完成

- [x] MIT 许可证
- [x] 中英文 README
- [x] 贡献、安全和行为规范
- [x] 第三方来源说明
- [x] GitHub Actions CI
- [x] Issue 和 PR 模板
- [x] `.gitignore` 排除模型、录音、构建物和本地配置
- [x] 最终名称确认为「米遥 / MI-AO」，技术标识统一为 `mi-ao`
- [x] App 名、Bundle ID、可执行文件和数据目录完成一次性迁移
- [x] 小米蓝牙遥控器 2 Pro 真机端到端提交
- [x] 中英文首页、快速开始、兼容矩阵和故障排查
- [x] 新设备兼容性 Issue 模板和脱敏门禁
- [x] 项目版权、App 元数据、CODEOWNERS 和机器可读引用统一为 `FanXeon@Poemcoder with Codex`
- [x] 中英文 Hero、About、发布帖和 Social Preview 文案已固定
- [x] 方向键指针模式已进入 0.2 路线图

## GitHub 仓库公开前

- [x] 已建立 GitHub origin 和 `main` 跟踪分支
- [ ] 在 GitHub 将当前私有仓库 `fanxeon/Vibe---------Mi-AO` 重命名为 `fanxeon/mi-ao`
- [ ] 重命名后把本地 origin 更新为 `https://github.com/fanxeon/mi-ao.git`
- [ ] 复核仓库名、App 名、Bundle ID、可执行文件和数据目录与 [NAMING.md](NAMING.md) 一致
- [ ] 添加简短描述、topics 和 MIT license 标记
- [ ] 启用 Issues、Discussions 和 Private vulnerability reporting
- [ ] 保护 `main`：要求 CI 通过、禁止强推、至少一次 review
- [ ] 启用 Dependabot for GitHub Actions
- [ ] 确认仓库中不存在语音、设备标识、绝对用户名路径或密钥
- [x] README CI badge 已指向 `fanxeon/mi-ao`
- [ ] 仓库创建后确认 CI badge 可正常加载
- [ ] 录制并脱敏 8–12 秒真实遥控器→Codex 演示
- [ ] 上传 1280 × 640 Social Preview
- [ ] 仓库 About、Release 和 Social Preview 显示 `FanXeon@Poemcoder with Codex`

## 首个正式版本前

- [x] 完成小米 2 Pro 真机证据
- [x] 更新兼容矩阵
- [ ] 决定是否需要可选的 Apple Developer ID 二进制发行通道
- [ ] 建立 `0.1.0` tag 和 GitHub Release
