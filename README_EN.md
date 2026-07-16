<!-- Copyright (c) 2026 FanXeon@Poemcoder with Codex -->

# MI-AO 米遥

> Rapid iteration is in progress — stay tuned.

<p align="center">
  <img src="docs/assets/mi-ao-logo.png" width="180" alt="MI-AO Center Connection logo">
</p>

**In the Vibe Coding era, turn a Xiaomi Bluetooth Remote Control 2 Pro into a real, hold-in-your-hand magic wand for Codex on Mac.**

**macOS 14 or later only; Windows and Linux are not currently supported.** Hold to talk. Release to send. Transcribed locally with Whisper. Delivered safely to Codex.

Created, hardware-validated and maintained by **FanXeon@Poemcoder with Codex**.

[English](README_EN.md) · [中文](README.md) · [V2 delivery audit](docs/V2_COMPLETION_AUDIT.md) · [Development status](docs/DEVELOPMENT_STATUS.md) · [Permissions](docs/PERMISSIONS_EN.md) · [Pair and connect](docs/PAIRING_EN.md) · [3-minute quick start](docs/QUICKSTART_EN.md) · [Button presets](docs/BUTTON_PRESETS_EN.md) · [Usage](docs/USAGE_EN.md) · [Compatibility](docs/COMPATIBILITY.md) · [Contributing](CONTRIBUTING_EN.md)

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

## V2 / 0.2.1 highlights

- `0.2.1` documents the notched-display visibility boundary: a valid status item can sit behind the camera housing or outside the remaining right-side width. It also hardens status-item creation order and process-level lifetime ownership.
- The final installed app passed Accessibility authorization, real ATVV v1.0 negotiation, paired D-pad/Center/TV/Voice HID events, and menu-bar command-feedback acceptance.
- A physical D-pad Up press produced the real “Move pointer · Up” menu state. Commands use a brief blue rounded highlight, confirmed success is green, failure is red, and recording/transcription/disconnect states retain priority.
- Persisted device selection, deterministic arbitration, capability watchdogs, visible reconnect backoff, preset hot reload, real highlighting, one-shot tests, and validated JSON transfer are now runtime contracts.
- Updates use signature verification, atomic replacement, and rollback. Shell and app model checks share one pinned Whisper SHA-256 contract.
- Opening MI-AO while it is running brings back the existing settings window instead of creating a conflicting process.

See the [V2 delivery audit](docs/V2_COMPLETION_AUDIT.md) for requirement-level evidence, automated gates, and the remaining 1.0 boundaries.

## Runtime environment and included capabilities

| Area | Current requirement / included capability |
| --- | --- |
| Operating system | **macOS 14+**; Windows and Linux are not currently supported |
| Verified hardware | Xiaomi Bluetooth Remote Control 2 Pro, firmware 2671, connected over Bluetooth Low Energy |
| Target app | Codex for macOS, bundle ID `com.openai.codex` |
| Local toolchain | Swift 6.0+, Xcode Command Line Tools, Homebrew, and `whisper.cpp` |
| Permissions | Bluetooth is core-required; Accessibility is required only for submission or button control; Launch at Login is always optional |
| Voice path | ATVV v0.4 / v1.0 → ADPCM decoding → local Whisper transcription → Codex |
| Button control | The default D-pad toggles between pointer movement and arrow keys; saved custom configurations can be selected and reached from TV |
| Diagnostics and safety | Built-in firmware 2671 hardware profile with safe local overrides; permission/runtime preflight before interception; automatic restore on exit |
| Delivery | **Source-first beta · V2 / 0.2.1**; one local build installs a self-contained daily runtime and a real-state menu-bar GUI |

The first setup needs network access to install `whisper-cpp` and download the multilingual base model. Daily transcription then runs locally. See the [3-minute quick start](docs/QUICKSTART_EN.md) for setup, the [roadmap](docs/ROADMAP.md) for the implemented/planned boundary, and the [product delivery plan](docs/PRODUCT_DELIVERY_PLAN_EN.md) for the path to a no-terminal user experience with custom shortcuts.

## Why it feels like a real magic wand

- **One physical action.** Hold to speak, release to submit.
- **A real hardware microphone.** Audio comes from the remote, not a disguised MacBook microphone path.
- **Local speech processing.** ADPCM decoding and `whisper.cpp` transcription run on your Mac.
- **Ready for the next instruction.** Transcription and submission run on a serial background queue instead of blocking BLE, buttons, or the next recording.
- **Fail-safe submission.** MI-AO submits only when the current Codex accessibility tree contains exactly one usable composer; otherwise it only copies the transcript.
- **Persistent runtime state and safe exit.** The menu-bar icon follows search, connection, recording, processing, submission, and physical-button commands. Commands receive a brief blue rounded highlight, success is green, and failure is red. Click it for Codex focus, records, diagnostics, and safe exit. On a notched display, too many right-side status items can push MI-AO outside the visible area; that is a menu-bar space limit, not evidence that the runtime stopped. See [Troubleshooting](docs/TROUBLESHOOTING_EN.md).
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

The **Button Configurations** page can create or copy a preset and map each supported button to a built-in action or recorded standard keyboard shortcut. Saving hot-reloads the running button controller without an app restart. Real HID down/up events highlight the matching row, and an explicit Test button executes the current action exactly once. User presets can be exported and imported as JSON; imports are size-, schema-, reserved-button-, TV-target-, and shortcut-safety-validated before confirmation and persistence.

Presets live in `~/Library/Application Support/mi-ao/button-presets.json` (directory `0700`, file `0600`). MI-AO rejects a TV transition without a valid target and dangerous shortcuts such as `Cmd-Q`, `Cmd-Option-Escape`, and `Cmd-Control-Q`; it actively releases injected modifiers on release and abnormal shutdown. See [Button presets and the default pointer mode](docs/BUTTON_PRESETS_EN.md) for the full contract.

> **Status boundary:** the firmware 2671 twelve-key hardware profile has new-format manual confirmation. The final installed app received complete down/up pairs for D-pad Up, Center, TV, and Voice, and the physical D-pad press entered the real “Move pointer · Up” menu command state. Volume task navigation passed bidirectional hardware acceptance. HOME click arbitration, Power, and multi-display positioning remain 1.0 per-action and stress gates, not substituted by the V2 evidence.

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

The source-first beta keeps secure ad-hoc signing. Updates are staged and signature-verified before an atomic swap; any failed post-swap verification restores the prior app and install context. The pinned Whisper model is SHA-256-verified before atomic replacement, on the setup readiness page, at the transcription boundary, and during installed-app verification from one shared contract. A changed binary may still require Accessibility reauthorization, and MI-AO never weakens TCC with a bundle-ID-only designated requirement.

### 2. Follow the setup guide

First run uses five pages: Start, Permissions & Connection, Control Preferences, Button Configurations, and Button Guide. After setup, reopening the window uses a daily-management context instead of pretending to repeat onboarding. Permissions & Connection scans real remotes and persists an explicit target; Button Configurations provides hot reload, real button highlighting, one-shot testing, and JSON transfer. Only Required and Required by enabled features checks block startup. See [Permissions and optional features](docs/PERMISSIONS_EN.md).

If a busy Codex process lacks the per-process compatibility argument, the guide explains the requirement and does not restart it. A restart occurs only after explicit confirmation. The argument changes no Codex preference, opens no debugging port and expires when Codex quits. See the [complete pairing and first connection guide](docs/PAIRING_EN.md).

### 3. Run

When all checks pass, choose “连接遥控器并开始”. The guide uses the app's bundled safe runtime. Developers can still use the equivalent repository command:

```bash
./scripts/start.sh
```

The guide and terminal fallback use the same `check-buttons` launch gate. If Accessibility or the button runtime is unavailable, startup exits without changing the system. On success it generates the twelve-key HID `No Event` mapping from the built-in hardware profile. LaunchServices owns the real runtime app process, so opening MI-AO again while it is running brings up its existing settings window instead of creating a conflicting instance. Menu keeps the native right-click. Click the menu-bar icon for the GUI; safe exit finishes accepted speech work and restores the mapping.

Daily startup never interrupts a busy Codex process. If Codex is closed, MI-AO launches it with the per-process compatibility argument. If Codex is already running without that argument, startup stops before changing the remote mapping and explains what to do; it never restarts Codex automatically. Safe `--no-submit` transcription does not require Codex compatibility.

If the remote is connected but an ATVV capabilities notification is lost, MI-AO retries negotiation. Three unanswered requests produce an explicit reason, disconnect the stale session, and enter the visible reconnect backoff. Every attempt checks the saved identifier and macOS-connected ATVV devices before falling back to advertisements, so a connected remote that stopped advertising is not lost.

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

The verified core path is working. MI-AO is currently a **source-first beta · V2 / 0.2.1**: it builds and ad-hoc signs the app on the user's own Mac. Until a Developer ID distribution channel exists, the project will not present an unnotarized DMG as a frictionless trusted install.

V2 includes Preferences v2, feature-dependent permission gates, real device discovery and persisted selection, deterministic multi-device arbitration, visible reconnect backoff, runtime preset hot reload, real HID highlighting, one-shot action tests, validated JSON transfer, atomic app replacement with rollback, and pinned model integrity verification. The final installed firmware 2671 path has completed full BLE, physical D-pad/Center/TV/Voice, transient menu feedback, and recovery acceptance. See the [V2 delivery audit](docs/V2_COMPLETION_AUDIT.md). The next 1.0 acceptance milestones are:

- installed-app relogin acceptance for the optional `SMAppService` launch item;
- long-duration, multi-display, and abnormal-interruption hardware acceptance;
- mode switching, Power, event-suppression timing, and multi-display acceptance runs;
- a second Codex-session navigation preset;
- a broader real-hardware compatibility matrix;
- configurable output targets without weakening the default safety contract.

See the [Product delivery plan](docs/PRODUCT_DELIVERY_PLAN_EN.md), [Roadmap](docs/ROADMAP.md), and [Source-first distribution](docs/DISTRIBUTION.md).

## Contributing

The highest-value contribution is reproducible evidence from new hardware. You can help by:

- contributing a redacted GATT capture for another voice remote;
- improving ATVV / ADPCM adapters and fixtures;
- contributing a second real-device profile and installed-app login-start acceptance evidence;
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
- [V2 delivery audit](docs/V2_COMPLETION_AUDIT.md)
- [Product delivery plan](docs/PRODUCT_DELIVERY_PLAN_EN.md)
- [Permissions and optional features](docs/PERMISSIONS_EN.md)

## Author, acknowledgments and license

MI-AO was created by **FanXeon@Poemcoder with Codex**. Product direction, engineering decisions, real-hardware validation and maintenance are led by FanXeon@Poemcoder, with Codex used as an AI engineering collaborator for code, tests, documentation and debugging. See [NOTICE](NOTICE) for the complete copyright and legal boundary.

MI-AO builds on research around Google ATV Voice over BLE and uses [`whisper.cpp`](https://github.com/ggml-org/whisper.cpp) for local transcription. See [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) for protocol references and third-party notices.

The code is available under the [MIT License](LICENSE), with the project-level notice `Copyright (c) 2026 FanXeon@Poemcoder with Codex`. MI-AO is an independent open-source project. It is not an official Xiaomi, Google, or OpenAI product and is not endorsed by them.

---

If you believe Vibe Coding deserves a real magic wand you can hold, star MI-AO and tell us which remote should light up next.
