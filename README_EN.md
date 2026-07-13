# Xiaomi Voice Bridge

English · [中文](README.md)

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-macOS%2014%2B-black.svg)](Package.swift)
[![Swift](https://img.shields.io/badge/Swift-6.0%2B-orange.svg)](Package.swift)

Use a Xiaomi or Google TV Bluetooth voice remote as a push-to-talk input for Codex on macOS.

```text
Remote microphone -> BLE ATVV -> ADPCM -> local Whisper -> active Codex composer -> Return
```

This project reads voice data from the remote itself. It does not substitute the Mac microphone.

## Status

Early hardware enablement. The macOS bridge and the ATVV v0.4/v1.0 implementation are operational, but Xiaomi Bluetooth Remote Control 2 Pro still requires real-device GATT and audio-frame verification. Compatibility is never reported without hardware evidence.

## Features

- CoreBluetooth discovery and GATT enumeration
- Google ATV Voice over BLE v0.4 and v1.0
- IMA/DVI ADPCM at 8 kHz and 16 kHz
- Remote release, second-press, and silence fallbacks
- Fully local transcription with `whisper.cpp`
- Safe Codex submission through macOS Accessibility
- WAV and transcript retention for debugging

## Requirements

- macOS 14 or later
- Swift 6.0 or later
- Homebrew
- A compatible BLE voice remote
- Bluetooth and Accessibility permissions

## Install

```bash
chmod +x scripts/*.sh
./scripts/setup.sh
```

Scan for the remote and run the bridge:

```bash
.build/release/xiaomi-voice-bridge scan --scan-seconds 30 --debug
./scripts/run.sh --identifier <PERIPHERAL-UUID> --debug
```

## Development

```bash
make test
make release
make app
make check
```

See [Architecture](docs/ARCHITECTURE.md), [Protocol notes](docs/PROTOCOL.md), [Roadmap](docs/ROADMAP.md), and [Contributing](CONTRIBUTING.md).

## Security

The bridge only submits non-empty transcripts. If Codex, Accessibility permission, or a verified text-input focus is unavailable, it falls back to copying the transcript. See [SECURITY.md](SECURITY.md).

## License

MIT. See [LICENSE](LICENSE) and [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).
