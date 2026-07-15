<!-- Copyright (c) 2026 FanXeon@Poemcoder with Codex -->

# Remote Pairing and First Connection Guide

[中文](PAIRING.md) · [3-minute quick start](QUICKSTART_EN.md) · [Troubleshooting](TROUBLESHOOTING_EN.md) · [Back to README](../README_EN.md)

This guide covers the fully verified **Xiaomi Bluetooth Remote Control 2 Pro, firmware 2671**, on macOS 14+. It starts before the remote appears on the Mac and ends after the first real transcript reaches Codex.

Pairing shortcuts differ on other remotes. Do not assume the shortcut below applies to an unverified device; check its manual and the [compatibility matrix](COMPATIBILITY.md).

## Understand the three connection states

First-time setup has three separate layers:

1. **Pair the remote with macOS:** System Settings → Bluetooth shows the remote as Connected.
2. **Authorize MI-AO:** macOS allows the installed MI-AO app to use Bluetooth and Accessibility.
3. **Connect the MI-AO bridge:** the terminal reports `桥接已就绪` after discovering the ATVV voice service.

A Connected status in System Settings does not yet mean that the voice bridge is ready.

## 0. Install MI-AO

Skip this section if setup is already complete.

```bash
git clone https://github.com/fanxeon/mi-ao.git
cd mi-ao
./scripts/setup.sh
```

The installed app is `~/Applications/米遥.app`. Run the remaining commands from the cloned repository.

## 1. Put the remote into pairing mode

1. Install working batteries and keep the remote near the Mac.
2. Open Apple menu → System Settings → Bluetooth and keep the page visible.
3. On the Xiaomi Bluetooth Remote Control 2 Pro, **press and hold Menu and `HOME` at the same time**.
4. Keep holding both buttons until the remote appears under Nearby Devices, then release them.

The buttons must be held simultaneously. If the remote was paired with a TV or set-top box, temporarily turn off Bluetooth on that device or move it away so it cannot take the connection back.

## 2. Connect in macOS

1. Find `小米蓝牙语音遥控器` under Nearby Devices.
2. Click Connect.
3. Wait until it moves to My Devices and reports Connected.

Remember the exact name shown by macOS. The verified unit uses `小米蓝牙语音遥控器`; if yours differs, use a stable, unique part of its displayed name with `--name` below.

## 3. Grant permissions

Request Accessibility access:

```bash
./scripts/authorize.sh
```

Enable the installed MI-AO app in System Settings → Privacy & Security → Accessibility. Do not authorize a temporary binary inside `.build`.

macOS requests Bluetooth access when the bridge is run for the first time. Allow it. If it was denied earlier, enable MI-AO manually under Privacy & Security → Bluetooth.

## 4. Connect MI-AO to the remote

Start with a safe test that does not submit to Codex:

```bash
./scripts/run.sh \
  --name "小米蓝牙语音遥控器" \
  --no-submit
```

Allow Bluetooth access if macOS asks. A successful connection produces logs similar to:

```text
蓝牙已就绪
连接 小米蓝牙语音遥控器（…）
已连接，枚举全部 GATT services
ATVV v1.0，codec=…
桥接已就绪：按遥控器语音键开始说话
```

The bridge is ready only after the final message appears. The current release has no second in-app pairing screen. The first `--no-submit` run is a foreground diagnostic; daily use starts in the background with `start.sh` and exposes connection state in the menu bar.

## 5. Run the first voice test

1. After the ready message, hold the voice button in the top-right corner.
2. Keep holding while saying a short test sentence.
3. Release after speaking.
4. Wait for a `转写：…` line. The bridge becomes ready again as soon as the recording enters the background queue.

`--no-submit` performs the real Bluetooth capture and local transcription but never sends text to Codex. After it succeeds, stop with `Control + C`.

Open the Codex macOS app, enter the task that should receive the instruction, and run normal mode:

```bash
./scripts/start.sh
```

Speak one short instruction. First-time setup is complete only when the terminal reports `已发送到 Codex` and the active Codex task receives the same text.

## Daily reconnection

You normally do not repeat Menu + `HOME` after pairing:

1. Confirm the remote is connected in System Settings → Bluetooth; press a button once if it is sleeping.
2. Open Codex and select the target task.
3. Run `./scripts/start.sh` from the repository.
4. Wait for the ready state in the menu bar before holding the voice button.

## Pairing and connection failures

### The remote never appears

- Replace the batteries and move the remote closer to the Mac.
- Release the buttons, then press and hold Menu + `HOME` simultaneously again.
- Temporarily turn off Bluetooth on the previously paired TV or set-top box.
- Toggle Bluetooth on the Mac and retry.

### The remote is saved but does not connect

Press a remote button once to wake it. If reconnecting still fails, use Forget This Device in Bluetooth settings and repeat the complete pairing flow. Forgetting removes the existing pairing record, so use it only after a normal retry fails.

### macOS says Connected but MI-AO cannot find it

- Make sure another MI-AO process is not already using the remote.
- Match `--name` to part of the actual name displayed by macOS.
- Run `./scripts/verify-install.sh` to check the installation and permissions.
- For local diagnostics, run `./scripts/capture.sh --scan-seconds 30` to confirm CoreBluetooth can retrieve it.

### The bridge is ready but the voice button does nothing

Stop with `Control + C` and restart with `--debug`:

```bash
./scripts/run.sh \
  --name "小米蓝牙语音遥控器" \
  --debug
```

A working voice-button press produces `AUDIO_START`. Continue with [Troubleshooting](TROUBLESHOOTING_EN.md) if it does not. Redact device UUIDs and raw GATT data before sharing logs.
