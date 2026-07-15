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
./scripts/run.sh --name "小米蓝牙语音遥控器" --no-buttons
```

When the bridge reports that it is ready, hold the remote's voice button, speak, and release. MI-AO activates Codex and submits only when exactly one editor is available.

## 3B. Bring up another remote

```bash
./scripts/capture.sh --scan-seconds 30
./scripts/capture.sh --identifier <UUID> --capture-seconds 60 --debug
```

During capture, test a short press, hold-to-talk and release, a second press, and silence. Reports are stored under `~/Library/Application Support/mi-ao/captures`.

Device identity is redacted by default, but raw `events.jsonl` payloads still require manual review before sharing. Follow the complete [hardware bring-up guide](HARDWARE_BRINGUP.md).

## 4. Enable the default pointer preset

Xiaomi Remote 2 Pro firmware 2671 ships with a built-in twelve-key hardware profile, so a clean install needs no recalibration. Run:

```bash
./scripts/run-with-mapping.sh --name "小米蓝牙语音遥控器"
```

The wrapper runs `check-buttons` first. It changes the system only after Accessibility permission and the button runtime are both ready, then generates neutralization from the same hardware profile.

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

- Stop the foreground bridge with `Control + C`.
- Remove the app while retaining models and recordings with `./scripts/uninstall.sh`.
- Remove all local MI-AO data with `./scripts/uninstall.sh --all-data`.

Continue with the [complete usage guide](USAGE_EN.md) after installation. See [Troubleshooting](TROUBLESHOOTING_EN.md) if the first run does not complete.
