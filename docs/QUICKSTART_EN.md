<!-- Copyright (c) 2026 FanXeon@Poemcoder with Codex -->

# 3-minute quick start

[中文](QUICKSTART.md) · [Back to README](../README_EN.md)

## Requirements

- macOS 14 or later;
- Xcode Command Line Tools and Homebrew;
- the Codex macOS app;
- a BLE voice remote.

The fully verified device is Xiaomi Bluetooth Remote Control 2 Pro firmware 2671. Check the [compatibility matrix](COMPATIBILITY.md) before assuming another remote works.

## 1. Install

```bash
git clone https://github.com/fanxeon/mi-ao.git
cd mi-ao
./scripts/setup.sh
```

The app is installed to `~/Applications/米遥.app`, the model to `~/.cache/mi-ao`, and recordings to `~/Library/Application Support/mi-ao/recordings`. The setup guide opens automatically when installation finishes.

MI-AO currently uses a local source build and ad-hoc signing. Do not download unofficial "unsigned" or "quarantine-free" DMGs.

## 2. Pair from the guide

Complete the Bluetooth card in the setup guide and choose “配对遥控器”. On the Xiaomi Bluetooth Remote Control 2 Pro, **press and hold Menu + `HOME` simultaneously** until it appears under Nearby Devices. Click Connect and wait for the Connected status. Pairing shortcuts for other remotes may differ; see the device manual and the [complete pairing guide](PAIRING_EN.md).

## 3. Complete the six real checks

The guide checks macOS, the local speech engine, MI-AO Accessibility, Bluetooth, the Codex composer and the safe launcher. Use each card action until every check is green.

Grant Accessibility to the installed MI-AO app, not a temporary binary inside `.build`. A closed Codex app is launched with its built-in Chromium accessibility argument. If a busy process lacks the argument, the guide reports it and waits for explicit restart confirmation. The argument affects only that process, changes no preferences and opens no debugging port.

## 4A. Start the verified Xiaomi Remote 2 Pro

Choose “连接遥控器并开始”. The guide calls the same real launch gate as `./scripts/start.sh`, closes after success and leaves MI-AO in the menu bar.

Click the menu-bar icon and wait for the ready state. Then hold the remote's voice button, speak and release. The panel also provides Codex focus, recordings, setup diagnostics and safe exit.

## 4B. Bring up another remote

```bash
./scripts/capture.sh --scan-seconds 30
./scripts/capture.sh --identifier <UUID> --capture-seconds 60 --debug
```

During capture, test a short press, hold-to-talk and release, a second press, and silence. Reports are stored under `~/Library/Application Support/mi-ao/captures`.

Device identity is redacted by default, but raw `events.jsonl` payloads still require manual review before sharing. Follow the complete [hardware bring-up guide](HARDWARE_BRINGUP.md).

## 5. Terminal fallback and the default pointer preset

Xiaomi Remote 2 Pro firmware 2671 ships with a built-in twelve-key hardware profile, so a clean install needs no recalibration. The terminal fallback uses the same gate:

```bash
./scripts/start.sh
```

The wrapper runs `check-buttons` first. It changes the system only after Accessibility permission and the button runtime are both ready, then generates neutralization from the same hardware profile.

If Codex is closed, `start.sh` launches it with the per-process compatibility argument. If a busy Codex process is already running without that argument, MI-AO exits before changing the remote mapping and never restarts Codex automatically.

If the same model behaves differently, uses another firmware, or you are bringing up another remote, stop MI-AO and calibrate:

```bash
./scripts/debug-buttons.sh \
  --name "小米蓝牙语音遥控器" \
  --preset pointer
```

Local confirmed results override the built-in baseline in time order. Explicit invalidation, a missing required button, or duplicate Usage makes `check-buttons` fail before any system mapping is changed.

Use `--button tv` or `--button power` to retest one key. Verified Xiaomi Remote 2 Pro firmware 2671 values are `TV=0x07/0x35` and `Power=0x07/0x66`; an infrared-only button on another remote cannot be handled by the Mac.

All four directions passed direct cursor positioning with real-coordinate monitoring. The complete button mode remains an implementation preview until mode switching and Power complete acceptance. Add `--no-buttons` for an explicit voice-only run. The wrapper restores on exit and refuses to overwrite an existing user `UserKeyMapping`.

## Useful options

```bash
# Transcribe without submitting
./scripts/run.sh --name "<device name>" --no-submit

# Override Whisper vocabulary context
./scripts/run.sh --name "<device name>" --prompt "MI-AO. Codex. Your project terms."

# Print raw GATT data for local debugging
./scripts/run.sh --name "<device name>" --debug

# Explicit voice-only fallback
./scripts/run.sh --name "<device name>" --no-buttons
```

## Verify, stop, and uninstall

```bash
./scripts/verify-install.sh
```

- Stop from the menu bar with “安全退出并恢复遥控器”, or run `./scripts/stop.sh`.
- Remove the app while retaining models and recordings with `./scripts/uninstall.sh`.
- Remove all local MI-AO data with `./scripts/uninstall.sh --all-data`.

Continue with the [complete usage guide](USAGE_EN.md) after installation. See [Troubleshooting](TROUBLESHOOTING_EN.md) if the first run does not complete.
