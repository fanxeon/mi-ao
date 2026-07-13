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

## 真机证据要求

小米蓝牙遥控器 2 Pro 的协议尚未确认。不得仅根据产品支持 AI 语音就断言其使用 ATVV；必须取得真实 service、characteristic、capabilities 和音频帧。
