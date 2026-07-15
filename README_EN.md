<!-- Copyright (c) 2026 FanXeon@Poemcoder with Codex -->

# MI-AO 米遥

> Rapid iteration is in progress — stay tuned.

<p align="center">
  <img src="docs/assets/mi-ao-logo.png" width="180" alt="MI-AO Center Connection logo">
</p>

**In the Vibe Coding era, turn a Xiaomi Bluetooth Remote Control 2 Pro into a real, hold-in-your-hand magic wand for Codex on Mac.**

**macOS 14 or later only; Windows and Linux are not currently supported.** Hold to talk. Release to send. Transcribed locally with Whisper. Delivered safely to Codex.

Created, hardware-validated and maintained by **FanXeon@Poemcoder with Codex**.

[English](README_EN.md) · [中文](README.md) · [Development status](docs/DEVELOPMENT_STATUS.md) · [Permissions](docs/PERMISSIONS_EN.md) · [Pair and connect](docs/PAIRING_EN.md) · [3-minute quick start](docs/QUICKSTART_EN.md) · [Button presets](docs/BUTTON_PRESETS_EN.md) · [Usage](docs/USAGE_EN.md) · [Compatibility](docs/COMPATIBILITY.md) · [Contributing](CONTRIBUTING_EN.md)

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

## Runtime environment and included capabilities

| Area | Current requirement / included capability |
| --- | --- |
| Operating system | **macOS 14+**; Windows and Linux are not currently supported |
| Verified hardware | Xiaomi Bluetooth Remote Control 2 Pro, firmware 2671, connected over Bluetooth Low Energy |
| Target app | Codex for macOS, bundle ID `com.openai.codex` |
| Local toolchain | Swift 6.0+, Xcode Command Line Tools, Homebrew, and `whisper.cpp` |
| Permissions | Bluetooth is core-required; Accessibility is required only for submission or button control; Launch at Login is always optional |
| Voice path | ATVV v0.4 / v1.0 → ADPCM decoding → local Whisper transcription → Codex |
| Button control | The D-pad toggles between pointer movement and arrow keys; Center is always Return and Back is always Escape |
| Diagnostics and safety | Built-in firmware 2671 hardware profile with safe local overrides; permission/runtime preflight before interception; automatic restore on exit |
| Delivery | **Source-first alpha**; one local build installs a self-contained daily runtime and a real-state menu-bar GUI |

The first setup needs network access to install `whisper-cpp` and download the multilingual base model. Daily transcription then runs locally. See the [3-minute quick start](docs/QUICKSTART_EN.md) for setup, the [roadmap](docs/ROADMAP.md) for the implemented/planned boundary, and the [product delivery plan](docs/PRODUCT_DELIVERY_PLAN_EN.md) for the path to a no-terminal user experience with custom shortcuts.

## Why it feels like a real magic wand

- **One physical action.** Hold to speak, release to submit.
- **A real hardware microphone.** Audio comes from the remote, not a disguised MacBook microphone path.
- **Local speech processing.** ADPCM decoding and `whisper.cpp` transcription run on your Mac.
- **Ready for the next instruction.** Transcription and submission run on a serial background queue instead of blocking BLE, buttons, or the next recording.
- **Fail-safe submission.** MI-AO submits only when the current Codex accessibility tree contains exactly one usable composer; otherwise it only copies the transcript.
- **Visible state and safe exit.** Click the menu-bar icon for search, connection, recording, processing and submission state, plus Codex focus, records, diagnostics and safe exit.
- **Evidence-driven compatibility.** A privacy-aware GATT capture mode makes new remote support reproducible.
- **Works from a verified baseline and remains recalibratable.** The Xiaomi Remote 2 Pro uses a built-in hardware profile; debug mode can create local overrides without observing the Mac keyboard or synthesizing actions.

## Real end-to-end evidence

```text
AUDIO_START ADPCM 16 kHz
AUDIO_STOP reason=remote-release
Transcript: Please confirm MI-AO's real submission succeeded.
Submitted to Codex
```

See the [compatibility matrix](docs/COMPATIBILITY.md) and [hardware bring-up record](docs/HARDWARE_BRINGUP.md) for the underlying evidence.

## One remote, multiple presets

A hardware profile identifies physical buttons; a preset decides what they do. Firmware 2671 starts from the built-in twelve-key profile, while local confirmed calibration can override it. In the default preset, `TV` changes only the D-pad between pointer movement and arrow keys. Center always sends Return and Back always sends Escape. Volume Up/Down selects the previous/next Codex task, Power launches or focuses Codex, HOME sends Page Down on one click or Page Up on a double-click, Menu keeps its native macOS right-click, and Voice remains hold-to-talk.

> **Mode invariant:** `TV` changes only the D-pad between pointer movement and arrow keys. Center, Back, HOME, Volume, Voice, Power, and Menu behave identically in both modes.

> **Status boundary:** new-format calibration confirms D-pad, Center, Back, HOME, TV, Power, Voice, and Volume Up/Down on Xiaomi Remote 2 Pro firmware 2671. MI-AO takes over these twelve keys and blocks their native side effects. Menu is excluded from MI-AO mapping and keeps the native macOS right-click. Volume task navigation passed bidirectional hardware acceptance; HOME click arbitration, mode switching, and Power still require per-action acceptance.

![Default MI-AO button mapping on macOS](docs/assets/mi-ao-button-map.png)

<p align="center"><sub>MI-AO default button map · FanXeon@Poemcoder with Codex</sub></p>

> The image is in Chinese. Its “Menu = mouse right-click” label describes native macOS behavior; MI-AO neither remaps nor intercepts Menu.

See [Button presets and the default pointer mode](docs/BUTTON_PRESETS_EN.md) for the diagram, calibration flow, safety fallback, and extension contract.

## 3-minute quick start

### 1. Install

```bash
git clone https://github.com/fanxeon/mi-ao.git
cd mi-ao
./scripts/setup.sh
```

The setup script installs `whisper-cpp`, downloads the multilingual base model, builds and installs `~/Applications/米遥.app`, then opens the setup guide. This is the only project command required for a first install. The installed app contains its signed start, stop, button-gate, mapping-recovery, and speech-engine repair runtime, so daily use no longer depends on the repository remaining at its original path.

The source-first alpha keeps secure ad-hoc signing. After a source update changes the binary, macOS may leave an older “米遥” row switched on even though the current build is not authorized. The guide explains how to remove the stale row, re-add the current app, and refreshes automatically. MI-AO does not weaken TCC with a bundle-ID-only designated requirement.

### 2. Follow the setup guide

The guide has four pages: Start, Permissions & Connection, Control Preferences, and Button Guide. Choose automatic Codex submission, remote button control, and optional Launch at Login first; then resolve the required macOS, Whisper, MI-AO Accessibility, Bluetooth, Codex, and safe-launcher checks. The Button Guide includes the default mapping image. Only “Required” and “Required by enabled features” block startup; Accessibility and Codex become optional when submission and button control are both off. See [Permissions and optional features](docs/PERMISSIONS_EN.md).

If a busy Codex process lacks the per-process compatibility argument, the guide explains the requirement and does not restart it. A restart occurs only after explicit confirmation. The argument changes no Codex preference, opens no debugging port and expires when Codex quits. See the [complete pairing and first connection guide](docs/PAIRING_EN.md).

### 3. Run

When all checks pass, choose “连接遥控器并开始”. The guide uses the app's bundled safe runtime. Developers can still use the equivalent repository command:

```bash
./scripts/start.sh
```

The guide and terminal fallback use the same `check-buttons` launch gate. If Accessibility or the button runtime is unavailable, startup exits without changing the system. On success it generates the twelve-key HID `No Event` mapping from the built-in hardware profile. Menu keeps the native right-click. Click the menu-bar icon for the GUI; safe exit finishes accepted speech work and restores the mapping.

Daily startup never interrupts a busy Codex process. If Codex is closed, MI-AO launches it with the per-process compatibility argument. If Codex is already running without that argument, startup stops before changing the remote mapping and explains what to do; it never restarts Codex automatically. Safe `--no-submit` transcription does not require Codex compatibility.

For any other remote, follow the [detailed quick start](docs/QUICKSTART_EN.md) and capture redacted protocol evidence before assuming a UUID.

Before setup is completed, double-clicking `~/Applications/米遥.app` opens the guide. After the first successful start, both a manual app launch and optional login launch read the same preferences and execute the same guarded startup path; failure reopens the guide.

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
  → the active Codex process accessibility tree
  → exactly one usable Codex composer
```

The current implementation supports ATVV v0.4 and v1.0, 8 kHz and 16 kHz ADPCM, remote `AUDIO_STOP`, second-press termination, and silence timeout fallback. See [Architecture](docs/ARCHITECTURE.md) and [Protocol notes](docs/PROTOCOL.md).

Physical buttons use a separate path: `HID Usage → confirmed physical button → selected preset → action executor`. Hardware evidence never stores pointer or Codex behavior, so presets remain replaceable.

## Privacy and safety

- Speech transcription runs locally and does not require a speech cloud API.
- WAV files and transcripts stay under `~/Library/Application Support/mi-ao/recordings` for user review.
- The recordings directory is user-only and speech artifacts use mode `0600`; they are never uploaded automatically.
- If the user copies something new during submission, MI-AO detects the clipboard change and never overwrites it with an older snapshot.
- Empty transcripts, a missing Codex process, missing permission, or an ambiguous editor never trigger automatic submission.
- The Codex launch argument exposes only the current process accessibility tree. It opens no debugging port and changes no Codex preferences; text still enters through the guarded clipboard paste path.
- Capture reports hash peripheral UUIDs and hide device names by default. Raw GATT payload still requires manual review before sharing.

Read the complete policy in [SECURITY_EN.md](SECURITY_EN.md).

## Project status

The verified core path is working. MI-AO is currently a **source-first alpha**: it builds and ad-hoc signs the app on the user's own Mac. Until a Developer ID distribution channel exists, the project will not present an unnotarized DMG as a frictionless trusted install.

The current milestone is **P1 partially complete**: Preferences v1, feature-dependent permission gates, transcription/button switches, and the `SMAppService` login-item flow are implemented. The installed-app login-start path still needs one real system acceptance run.

MI-AO now includes menu-bar state, safe background start/stop, duplicate-instance prevention, a non-blocking speech queue, and clipboard concurrency protection. The next milestones are:

- device selection, persisted device identity, and complete reconnect feedback;
- versioned user presets with recorded, tested, importable and exportable custom keyboard shortcuts;
- mode switching, Power, event-suppression timing, and multi-display acceptance runs;
- a second Codex-session navigation preset;
- a broader real-hardware compatibility matrix;
- configurable output targets without weakening the default safety contract.

See the [Product delivery plan](docs/PRODUCT_DELIVERY_PLAN_EN.md), [Roadmap](docs/ROADMAP.md), and [Source-first distribution](docs/DISTRIBUTION.md).

## Contributing

The highest-value contribution is reproducible evidence from new hardware. You can help by:

- contributing a redacted GATT capture for another voice remote;
- improving ATVV / ADPCM adapters and fixtures;
- improving device selection, reconnect feedback, and installed-app login-start acceptance;
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
- [Development status snapshot](docs/DEVELOPMENT_STATUS.md)
- [Product delivery plan](docs/PRODUCT_DELIVERY_PLAN_EN.md)
- [Permissions and optional features](docs/PERMISSIONS_EN.md)

## Author, acknowledgments and license

MI-AO was created by **FanXeon@Poemcoder with Codex**. Product direction, engineering decisions, real-hardware validation and maintenance are led by FanXeon@Poemcoder, with Codex used as an AI engineering collaborator for code, tests, documentation and debugging. See [NOTICE](NOTICE) for the complete copyright and legal boundary.

MI-AO builds on research around Google ATV Voice over BLE and uses [`whisper.cpp`](https://github.com/ggml-org/whisper.cpp) for local transcription. See [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) for protocol references and third-party notices.

The code is available under the [MIT License](LICENSE), with the project-level notice `Copyright (c) 2026 FanXeon@Poemcoder with Codex`. MI-AO is an independent open-source project. It is not an official Xiaomi, Google, or OpenAI product and is not endorsed by them.

---

If you believe Vibe Coding deserves a real magic wand you can hold, star MI-AO and tell us which remote should light up next.
