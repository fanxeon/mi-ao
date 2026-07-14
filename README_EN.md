<!-- Copyright (c) 2026 FanXeon@Poemcoder with Codex -->

# MI-AO 米遥

**In the Vibe Coding era, turn a Xiaomi Bluetooth Remote Control 2 Pro into a real, hold-in-your-hand magic wand for Codex on Mac.**

**macOS 14 or later only; Windows and Linux are not currently supported.** Hold to talk. Release to send. Transcribed locally with Whisper. Delivered safely to Codex.

Created, hardware-validated and maintained by **FanXeon@Poemcoder with Codex**.

[English](README_EN.md) · [中文](README.md) · [Pair and connect](docs/PAIRING_EN.md) · [3-minute quick start](docs/QUICKSTART_EN.md) · [Button presets](docs/BUTTON_PRESETS_EN.md) · [Usage](docs/USAGE_EN.md) · [Compatibility](docs/COMPATIBILITY.md) · [Contributing](CONTRIBUTING_EN.md)

[![CI](https://github.com/fanxeon/mi-ao/actions/workflows/ci.yml/badge.svg)](https://github.com/fanxeon/mi-ao/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![macOS 14+](https://img.shields.io/badge/macOS-14%2B-black.svg)](Package.swift)
[![Swift 6](https://img.shields.io/badge/Swift-6-orange.svg)](Package.swift)
[![Hardware verified](https://img.shields.io/badge/hardware-verified-2ea44f.svg)](docs/COMPATIBILITY.md)

```text
Hold the remote → say "inspect this project and continue" → release → Codex gets to work
```

MI-AO is a macOS voice-input system that connects the Xiaomi Bluetooth Remote Control 2 Pro to Codex. It reads BLE voice data from the microphone inside the remote, decodes and transcribes it locally on your Mac, then safely submits the result to the active Codex task. It is not another Mac-microphone dictation app. It turns a voice remote sitting in a drawer into a tactile entry point for Vibe Coding.

> **Verified hardware:** Xiaomi Bluetooth Remote Control 2 Pro firmware 2671 has completed a real hold-to-talk → local Whisper → Codex submission test.

## Why it feels like a real magic wand

- **One physical action.** Hold to speak, release to submit.
- **A real hardware microphone.** Audio comes from the remote, not a disguised MacBook microphone path.
- **Local speech processing.** ADPCM decoding and `whisper.cpp` transcription run on your Mac.
- **Fail-safe submission.** MI-AO submits only when exactly one enabled Codex editor is found; otherwise it only copies the transcript.
- **Evidence-driven compatibility.** A privacy-aware GATT capture mode makes new remote support reproducible.
- **Confirmable button calibration.** HID events are filtered by exact Vendor/Product IDs. Debug mode shows the Usage and current preset action before saving only the physical mapping; it excludes the Mac keyboard and synthesizes no mouse or keyboard action.

## Real end-to-end evidence

```text
AUDIO_START ADPCM 16 kHz
AUDIO_STOP reason=remote-release
Transcript: Please confirm MI-AO's real submission succeeded.
Submitted to Codex
```

See the [compatibility matrix](docs/COMPATIBILITY.md) and [hardware bring-up record](docs/HARDWARE_BRINGUP.md) for the underlying evidence.

## One remote, multiple presets

Calibration identifies physical buttons; a preset decides what they do. In the default preset, `TV` switches between pointer mode (D-pad movement, Center left-click, Back right-click) and directional mode (arrow keys, Return, Escape). Power launches Codex or focuses it when already running; Volume scrolls, `HOME` focuses Codex, Menu cycles presets, and Voice remains hold-to-talk.

> **Status boundary:** the preset architecture, dual control modes, and executor are implemented. Voice, Back, `TV`, and Power now have physical hardware evidence; new-format calibration confirmed `TV=0x07/0x35` and `Power=0x07/0x66`. The complete required six-button calibration and action acceptance run are still pending, so physical-button actions remain an implementation preview.

See [Button presets and the default pointer mode](docs/BUTTON_PRESETS_EN.md) for the diagram, calibration flow, safety fallback, and extension contract.

## 3-minute quick start

### 1. Install

```bash
git clone https://github.com/fanxeon/mi-ao.git
cd mi-ao
./scripts/setup.sh
```

The setup script installs `whisper-cpp`, downloads the multilingual base model, builds the release app, and installs it as `~/Applications/米遥.app`.

### 2. Pair and authorize

Open System Settings → Bluetooth. On the Xiaomi Remote 2 Pro, **press and hold Menu + `HOME` simultaneously** until it appears under Nearby Devices. Click Connect, wait for the Connected status, then run:

```bash
./scripts/authorize.sh
```

`authorize.sh` requests Accessibility access. macOS separately requests Bluetooth access when the bridge runs for the first time. Grant both permissions to the installed MI-AO app. See the [complete pairing and first connection guide](docs/PAIRING_EN.md) for exact steps, a safe first test, reconnection and recovery.

### 3. Run

For the verified Xiaomi Remote 2 Pro:

```bash
./scripts/run-with-mapping.sh --name "小米蓝牙语音遥控器"
```

The wrapper temporarily applies device-specific `TV→F20` and `Power→F21`, while MI-AO continues reading the original IOHID Usage. When the bridge is ready, hold the voice button, speak, and release. `Control + C` stops MI-AO and restores the original mapping. For voice with no system mapping change, use `./scripts/run.sh --name "小米蓝牙语音遥控器" --no-buttons`.

For any other remote, follow the [detailed quick start](docs/QUICKSTART_EN.md) and capture redacted protocol evidence before assuming a UUID.

See the [complete usage guide](docs/USAGE_EN.md) for daily startup, success logs, transcription-only mode, project vocabulary, updates and local data cleanup. Keep the terminal open in the current release; double-clicking the app is not the recommended entry point.

## Compatibility

| Device | Firmware | Protocol | End to end |
| --- | --- | --- | --- |
| Xiaomi Bluetooth Remote Control 2 Pro | 2671 | ATVV v1.0 · ADPCM 16 kHz · 120 B | ✅ macOS → Whisper → Codex |
| Other Google / Android TV voice remotes | Community evidence needed | ATVV v0.4 / v1.0 reference implementation | 🧪 Hardware verification needed |

See [docs/COMPATIBILITY.md](docs/COMPATIBILITY.md) for evidence levels and instructions for contributing a device.

## How it works

```text
BLE voice remote
  → Google ATV Voice over BLE
  → IMA/DVI ADPCM
  → 16 kHz PCM / WAV
  → local whisper.cpp
  → macOS Accessibility
  → the unique Codex editor
```

The current implementation supports ATVV v0.4 and v1.0, 8 kHz and 16 kHz ADPCM, remote `AUDIO_STOP`, second-press termination, and silence timeout fallback. See [Architecture](docs/ARCHITECTURE.md) and [Protocol notes](docs/PROTOCOL.md).

Physical buttons use a separate path: `HID Usage → confirmed physical button → selected preset → action executor`. Hardware evidence never stores pointer or Codex behavior, so presets remain replaceable.

## Privacy and safety

- Speech transcription runs locally and does not require a speech cloud API.
- WAV files and transcripts stay under `~/Library/Application Support/mi-ao/recordings` for user review.
- Empty transcripts, a missing Codex process, missing permission, or an ambiguous editor never trigger automatic submission.
- Capture reports hash peripheral UUIDs and hide device names by default. Raw GATT payload still requires manual review before sharing.

Read the complete policy in [SECURITY_EN.md](SECURITY_EN.md).

## Project status

The verified core path is working. MI-AO is currently a **source-first alpha**: it builds and ad-hoc signs the app on the user's own Mac. Until a Developer ID distribution channel exists, the project will not present an unnotarized DMG as a frictionless trusted install.

The next milestones are:

- menu bar status and recording feedback;
- device selection, persisted configuration, and reconnect;
- the six-button pointer hardware calibration, event-suppression timing, and multi-display acceptance run;
- a second Codex-session navigation preset;
- a broader real-hardware compatibility matrix;
- configurable output targets without weakening the default safety contract.

See the [Roadmap](docs/ROADMAP.md) and [Source-first distribution](docs/DISTRIBUTION.md).

## Contributing

The highest-value contribution is reproducible evidence from new hardware. You can help by:

- contributing a redacted GATT capture for another voice remote;
- improving ATVV / ADPCM adapters and fixtures;
- building the menu bar and reconnect experience;
- improving documentation, diagnostics, and privacy review.

Start with [CONTRIBUTING_EN.md](CONTRIBUTING_EN.md). Compatibility claims without real hardware evidence are not merged.

## Documentation

- [Documentation index](docs/README.md)
- [Remote pairing and first connection](docs/PAIRING_EN.md)
- [Quick start](docs/QUICKSTART_EN.md)
- [Complete usage guide](docs/USAGE_EN.md)
- [Button presets and default pointer mode](docs/BUTTON_PRESETS_EN.md)
- [Compatibility matrix](docs/COMPATIBILITY.md)
- [Troubleshooting](docs/TROUBLESHOOTING_EN.md)
- [Architecture](docs/ARCHITECTURE.md)
- [ATVV protocol notes](docs/PROTOCOL.md)
- [Hardware bring-up](docs/HARDWARE_BRINGUP.md)
- [Roadmap](docs/ROADMAP.md)

## Author, acknowledgments and license

MI-AO was created by **FanXeon@Poemcoder with Codex**. Product direction, engineering decisions, real-hardware validation and maintenance are led by FanXeon@Poemcoder, with Codex used as an AI engineering collaborator for code, tests, documentation and debugging. See [NOTICE](NOTICE) for the complete copyright and legal boundary.

MI-AO builds on research around Google ATV Voice over BLE and uses [`whisper.cpp`](https://github.com/ggml-org/whisper.cpp) for local transcription. See [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) for protocol references and third-party notices.

The code is available under the [MIT License](LICENSE), with the project-level notice `Copyright (c) 2026 FanXeon@Poemcoder with Codex`. MI-AO is an independent open-source project. It is not an official Xiaomi, Google, or OpenAI product and is not endorsed by them.

---

If you believe Vibe Coding deserves a real magic wand you can hold, star MI-AO and tell us which remote should light up next.
