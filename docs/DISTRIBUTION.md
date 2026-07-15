<!-- Copyright (c) 2026 FanXeon@Poemcoder with Codex -->

# 源码优先分发

项目在没有 Apple Developer ID 的阶段采用本机构建，不把未经公证的 DMG 作为默认下载。

## 用户路径

```bash
git clone https://github.com/fanxeon/mi-ao.git
cd mi-ao
make preflight
make setup
make verify
```

安装过程在用户自己的 Mac 上完成 Swift release 构建、VI AppIcon 全尺寸 `.icns` 生成、ad-hoc 签名、模型下载和 App 安装，并自动打开设置向导。Codex 本次进程的辅助功能兼容参数、米遥辅助功能和蓝牙权限仍必须由用户本人在向导或系统设置中显式确认；向导不会绕过 TCC，也不会自动重启忙碌的 Codex。参数可用 `./scripts/codex-accessibility.sh disable --restart` 立即撤销，也会在 Codex 退出后自然失效。

构建产物在 `Contents/Resources/Runtime` 内携带经签名的最小日常运行组件。源码目录仅用于首次构建、更新、重装和开发者诊断；安装后从 Finder 打开 App、运行按键门禁、恢复映射或修复缺失语音模型不再依赖仓库原路径。

ad-hoc 签名的 designated requirement 会绑定当前二进制 CDHash。源码更新改变 CDHash 后，旧辅助功能条目可能继续显示开启，但不能授权新构建。安装脚本会比较更新前后的 CDHash 并提示重新添加；向导自动轮询真实 `AXIsProcessTrusted()` 状态。项目不会改成仅凭 `com.fanx.miao` 匹配的宽松 requirement，因为那会让同 Bundle ID 的其他本地代码共享权限。

## 发布物

公开 Alpha 默认提供：

- Git tag 和 GitHub 自动生成的 source archive；
- `make source-release` 生成的可复核源码包；
- SHA-256 校验文件；
- 构建、卸载和隐私说明；
- 真实设备兼容矩阵。

不把 `xattr -dr com.apple.quarantine` 作为常规安装步骤，也不宣称 ad-hoc 签名等同于 Apple Developer ID。

## 本地生命周期

```bash
make preflight       # 构建环境检查
make install         # 本机构建并安装 App
make verify          # 签名、Bundle ID 和 doctor 验证
open ~/Applications/米遥.app # 打开设置向导
make codex-accessibility # 检查 Codex 本次进程的辅助功能兼容状态
make authorize       # 请求已安装 App 的辅助功能权限
make uninstall       # 仅删除 App，保留模型和录音
scripts/uninstall.sh --all-data
```

## 以后增加正式二进制通道

如果项目形成稳定用户群，再增加 Developer ID 签名、公证、staple 和 DMG。核心源码构建通道继续保留，正式签名只是额外的发行便利层。
