# 开源发布检查表

## 已完成

- [x] MIT 许可证
- [x] 中英文 README
- [x] 贡献、安全和行为规范
- [x] 第三方来源说明
- [x] GitHub Actions CI
- [x] Issue 和 PR 模板
- [x] `.gitignore` 排除模型、录音、构建物和本地配置

## 创建 GitHub 仓库时

- [ ] 从 [NAMING.md](NAMING.md) 确认最终项目名并完成一次性迁移
- [ ] 仓库名、App 名、Bundle ID、可执行文件和数据目录保持一致
- [ ] 添加简短描述、topics 和 MIT license 标记
- [ ] 启用 Issues、Discussions 和 Private vulnerability reporting
- [ ] 保护 `main`：要求 CI 通过、禁止强推、至少一次 review
- [ ] 启用 Dependabot for GitHub Actions
- [ ] 确认仓库中不存在语音、设备标识、绝对用户名路径或密钥
- [ ] 将 README 中的通用 badge 更新为真实仓库 CI badge

## 首个正式版本前

- [ ] 完成小米 2 Pro 真机证据
- [ ] 更新兼容矩阵
- [ ] 决定是否需要可选的 Apple Developer ID 二进制发行通道
- [ ] 建立 `0.1.0` tag 和 GitHub Release
