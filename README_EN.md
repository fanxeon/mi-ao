# 米遥 MI-AO

English · [中文](README.md)

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-macOS%2014%2B-black.svg)](Package.swift)
[![Swift](https://img.shields.io/badge/Swift-6.0%2B-orange.svg)](Package.swift)

MI-AO turns a compatible Bluetooth voice remote into a push-to-talk input for Codex on macOS: hold to speak, release to put an agent to work.

```text
Remote microphone -> BLE ATVV -> ADPCM -> local Whisper -> active Codex composer -> Return
```

This project reads voice data from the remote itself. It does not substitute the Mac microphone.

## Status

Xiaomi Bluetooth Remote Control 2 Pro firmware 2671 is verified on real hardware with ATVV v1.0, 16 kHz ADPCM, 120-byte frames, hold/release control, WAV decoding, and Chinese Whisper transcription. Codex submission and reconnect edge cases remain under validation.

## Features

- CoreBluetooth discovery and GATT enumeration
- Structured hardware capture reports with redacted device identity and raw local GATT events
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

Create a redacted scan report, then capture the selected device:

```bash
./scripts/capture.sh --scan-seconds 30
./scripts/capture.sh --identifier <PERIPHERAL-UUID> --capture-seconds 60 --debug
./scripts/run.sh --identifier <PERIPHERAL-UUID> --debug
```

See the [hardware bring-up guide](docs/HARDWARE_BRINGUP.md) before sharing capture artifacts. Raw GATT payloads remain local but may still contain private data.

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

MI-AO is an independent open-source project. It is not an official Xiaomi product and is not endorsed by Xiaomi, Google, or OpenAI. All trademarks belong to their respective owners.
