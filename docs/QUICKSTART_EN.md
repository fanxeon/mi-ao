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

The app is installed to `~/Applications/米遥.app`, the model to `~/.cache/mi-ao`, and recordings to `~/Library/Application Support/mi-ao/recordings`.

MI-AO currently uses a local source build and ad-hoc signing. Do not download unofficial "unsigned" or "quarantine-free" DMGs.

## 2. Pair and authorize

Open System Settings → Bluetooth. On the Xiaomi Bluetooth Remote Control 2 Pro, **press and hold Menu + `HOME` simultaneously** until it appears under Nearby Devices. Click Connect and wait for the Connected status. Pairing shortcuts for other remotes may differ; see the device manual and the [complete pairing guide](PAIRING_EN.md).

Then run:

```bash
./scripts/authorize.sh
```

Grant Accessibility access to the installed MI-AO app, not a temporary binary inside `.build`. macOS asks for Bluetooth access separately when the bridge starts for the first time; allow it then.

## 3A. Run the verified Xiaomi Remote 2 Pro

```bash
./scripts/run.sh --name "小米蓝牙语音遥控器"
```

When the bridge reports that it is ready, hold the remote's voice button, speak, and release. MI-AO activates Codex and submits only when exactly one editor is available.

## 3B. Bring up another remote

```bash
./scripts/capture.sh --scan-seconds 30
./scripts/capture.sh --identifier <UUID> --capture-seconds 60 --debug
```

During capture, test a short press, hold-to-talk and release, a second press, and silence. Reports are stored under `~/Library/Application Support/mi-ao/captures`.

Device identity is redacted by default, but raw `events.jsonl` payloads still require manual review before sharing. Follow the complete [hardware bring-up guide](HARDWARE_BRINGUP.md).

## 4. Optional: calibrate the default pointer preset

Verify voice first, stop MI-AO, then run:

```bash
./scripts/debug-buttons.sh \
  --name "小米蓝牙语音遥控器" \
  --preset pointer
```

Confirm at least all four D-pad directions, Center, and Back. Restart the normal command afterward; MI-AO merges confirmed reports and attempts to enable the default `pointer` preset. A missing button or duplicate Usage disables pointer actions while voice remains available.

Pointer mode is still an implementation preview. Add `--no-buttons` for an explicit voice-only run. See [Button presets and the default pointer mode](BUTTON_PRESETS_EN.md) for the complete mapping, per-button calibration, and macOS event-filter boundary.

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

- Stop the foreground bridge with `Control + C`.
- Remove the app while retaining models and recordings with `./scripts/uninstall.sh`.
- Remove all local MI-AO data with `./scripts/uninstall.sh --all-data`.

Continue with the [complete usage guide](USAGE_EN.md) after installation. See [Troubleshooting](TROUBLESHOOTING_EN.md) if the first run does not complete.
