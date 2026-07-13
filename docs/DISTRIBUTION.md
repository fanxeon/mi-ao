# 源码优先分发

项目在没有 Apple Developer ID 的阶段采用本机构建，不把未经公证的 DMG 作为默认下载。

## 用户路径

```bash
git clone https://github.com/<owner>/mi-ao.git
cd mi-ao
make preflight
make setup
make verify
make authorize
```

安装过程在用户自己的 Mac 上完成 Swift release 构建、ad-hoc 签名、模型下载和 App 安装。辅助功能和蓝牙权限仍必须由用户本人确认。

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
make authorize       # 请求已安装 App 的辅助功能权限
make uninstall       # 仅删除 App，保留模型和录音
scripts/uninstall.sh --all-data
```

## 以后增加正式二进制通道

如果项目形成稳定用户群，再增加 Developer ID 签名、公证、staple 和 DMG。核心源码构建通道继续保留，正式签名只是额外的发行便利层。
