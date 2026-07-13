# 贡献指南

感谢参与米遥 MI-AO。项目优先接受可复现、保留真实硬件证据的改动。

## 开发环境

- macOS 14+
- Swift 6.0+
- Xcode Command Line Tools
- Homebrew（仅运行时转写需要 `whisper-cpp`）

```bash
git clone https://github.com/<owner>/mi-ao.git
cd mi-ao
make check
```

单元测试和 release 构建不需要下载 Whisper 模型，也不需要连接遥控器。

## 工作方式

1. 先建立 Issue，描述设备型号、固件、macOS 版本和复现步骤。
2. 从 `main` 创建短生命周期分支。
3. 每个 PR 只解决一个明确问题，并补测试或真机日志。
4. 不提交包含私人语音、设备地址、用户名或 API 密钥的录音和日志。
5. 提交前运行 `make check`。

## 硬件兼容性证据

新增遥控器适配时，请尽量提供脱敏后的：

- 广播名称与 service UUID；
- characteristic UUID、properties 和通知方向；
- capabilities 响应；
- 一组不含个人语音的最小音频帧；
- 按下、松开、超时和断连行为；
- 设备型号、固件和测试系统版本。

没有真实硬件证据的兼容性声明不会合并。

## 提交信息

使用清楚的祈使句，例如：

```text
Add ATVV v1.0 audio stop handling
Fix scan command run-loop exit
Document Xiaomi Remote 2 Pro pairing evidence
```

## Pull Request

PR 需要说明变化、验证方法、风险和是否涉及隐私权限。涉及 UI 自动操作时，必须保留失败时不发送的安全边界。
