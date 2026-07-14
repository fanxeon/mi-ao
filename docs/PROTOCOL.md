# ATVV 协议说明

当前实现参考 Google ATV Voice over BLE v0.4/v1.0 和公开遥控器实现。

## UUID

| 角色 | UUID |
| --- | --- |
| Service | `AB5E0001-5A21-4F05-BC7D-AF01F617B664` |
| TX | `AB5E0002-5A21-4F05-BC7D-AF01F617B664` |
| RX audio | `AB5E0003-5A21-4F05-BC7D-AF01F617B664` |
| Control | `AB5E0004-5A21-4F05-BC7D-AF01F617B664` |

## 协商

- GET_CAPS：`0A 01 00 00 03 03`
- v0.4 MIC_OPEN：`0C 00 <codec>`
- v0.4 MIC_CLOSE：`0D`
- v1.0 MIC_OPEN：`0C 00`
- v1.0 MIC_CLOSE：`0D <stream-id>`

## 音频

v0.4 常见帧长 134 字节，包含大端 sequence、padding、predictor、step index 和 128 字节 ADPCM。nibble 顺序为高位优先。

v1.0 音频帧可不带头部，解码器状态通过 `AUDIO_SYNC` 初始化。实现同时处理 `AUDIO_STOP`、第二次 `START_SEARCH` 和静音超时，覆盖不同遥控器的松手行为。

## 小米固件 2671 兼容差异

固件 2671 实测通常返回标准布局 `0B 01 00 02 03 00 78 00 00`，但首次协商曾观察到 `0B 01 00 00 03 00 78 00 00`。后者符合 v1.0 总长度，但标准 codec 字段无有效位、相邻字段却含 ADPCM 8/16 kHz 位。解析器仅在这一无歧义条件成立时作字节对调兼容，不影响标准响应。

## 真机证据要求

小米蓝牙遥控器 2 Pro（固件 2671）已确认使用标准 ATVV Service：v1.0、ADPCM 16 kHz、Hold-to-Talk、120 字节音频帧。真机已观察到 `AUDIO_START`、持续音频 notify 和松手 `AUDIO_STOP`，解码 WAV 可被本地 Whisper 识别。

使用 `mi-ao capture` 时，未知协议设备只会被枚举、读取可读特征并订阅 notify/indicate。程序不会猜测或写入未知 characteristic。若发现标准 ATVV Service，才会发送本页定义的 `GET_CAPS`，并把 TX/RX 一并写入 `events.jsonl`。
