<!-- Copyright (c) 2026 FanXeon@Poemcoder with Codex -->

# Usage Guide

[中文](USAGE.md) · [Quick start](QUICKSTART_EN.md) · [Troubleshooting](TROUBLESHOOTING_EN.md)

This guide starts after installation and covers daily startup, hold-to-talk behavior, success signals, safe modes, updates and local data cleanup. Complete the [3-minute quick start](QUICKSTART_EN.md) first.

## Current launch model

MI-AO is currently a **source-first alpha**. Start it from the cloned repository:

```bash
cd /path/to/mi-ao
./scripts/run.sh --name "小米蓝牙语音遥控器"
```

Keep the terminal open while MI-AO is running. The current version has no menu bar, login item or visible recording overlay. Do not rely on double-clicking `米遥.app` for daily use because connection, transcript and failure messages would be hidden.

## Daily use in four actions

### 1. Prepare

- Confirm that `小米蓝牙语音遥控器` is connected in System Settings → Bluetooth.
- Open the Codex macOS app.
- Open the Codex task that should receive the instruction and close dialogs covering its editor.

### 2. Start MI-AO

```bash
cd /path/to/mi-ao
./scripts/run.sh --name "小米蓝牙语音遥控器"
```

Wait for:

```text
桥接已就绪：按遥控器语音键开始说话
```

Do not start speaking before the ready message appears.

### 3. Hold, speak, release

1. Hold the voice button in the top-right corner of the remote.
2. Keep holding while speaking the complete instruction.
3. Release only after the sentence is finished.
4. Wait for local Whisper transcription and safe Codex submission.

A normal session produces logs similar to:

```text
AUDIO_START ADPCM 16 kHz
AUDIO_STOP reason=0x00
录音完成 reason=remote-release
转写：检查当前项目并告诉我下一步
已发送到 Codex
桥接已就绪：按遥控器语音键继续
```

Start the next instruction only after the bridge is ready again. A very short tap is discarded and never submits an empty message.

### 4. Stop

Press `Control + C` in the terminal running MI-AO. This stops the current bridge without deleting the app, model, recordings or permissions.

## How submission works

In default mode MI-AO:

1. transcribes the remote audio locally;
2. verifies that Codex is running;
3. finds exactly one usable editor in the active Codex window;
4. temporarily uses the clipboard to paste and press Return;
5. restores the previous clipboard contents after a successful submission.

If Codex is missing, Accessibility is not authorized, or a unique editor cannot be proven, MI-AO does not press Return blindly. It leaves the transcript on the clipboard and explains the reason in the terminal so it can be reviewed and pasted manually.

## Effective spoken instructions

Short instructions with a clear target and action work best, for example:

```text
Inspect the current project and tell me the next step.
Run the tests, locate the first failure, and explain the cause.
Read the README and find claims that disagree with the code.
Audit the implementation first. Do not modify code yet.
Fix this problem and run the relevant tests when finished.
```

Keep one primary task per utterance. Speak filenames, function names and acronyms more slowly. Add frequently used project vocabulary with `--prompt`.

## Three common modes

### Default: submit on release

```bash
./scripts/run.sh --name "小米蓝牙语音遥控器"
```

### Safe test: transcribe without submitting

```bash
./scripts/run.sh \
  --name "小米蓝牙语音遥控器" \
  --no-submit
```

The transcript is printed and saved as a `.txt` file but is not sent to Codex. Use this mode first when testing a new environment, model or vocabulary list.

### Project vocabulary

```bash
./scripts/run.sh \
  --name "小米蓝牙语音遥控器" \
  --language en \
  --prompt "MI-AO. Codex. Swift. CoreBluetooth. ProjectName."
```

Keep the prompt as a short vocabulary list. A command or paragraph can be continued into the output by a small Whisper model.

## Select a specific remote

Prefer a stable, readable name:

```bash
./scripts/run.sh --name "小米蓝牙语音遥控器"
```

If multiple devices share the same name, scan and then target the local peripheral UUID:

```bash
./scripts/bridge.sh scan --scan-seconds 20
./scripts/run.sh --identifier <UUID>
```

A peripheral UUID is a local device identifier. Never paste it into a public issue, screenshot or log.

## Diagnostics

Run the complete installation check first:

```bash
./scripts/verify-install.sh
```

For local BLE / GATT inspection:

```bash
./scripts/run.sh \
  --name "小米蓝牙语音遥控器" \
  --debug
```

Debug output can include raw device data and must be redacted before sharing. See [Troubleshooting](TROUBLESHOOTING_EN.md) for failure-specific steps.

## Local data

The default directory is:

```text
~/Library/Application Support/mi-ao/recordings
```

Each valid utterance keeps:

- `voice-*.wav`: decoded local audio;
- `voice-*.txt`: final transcript;
- `voice-*.whisper.txt`: raw Whisper text output.

These files can contain private speech, project names and code vocabulary. They are not uploaded automatically and must not be committed to Git or attached to public issues without review.

Use another output directory with:

```bash
./scripts/run.sh \
  --name "小米蓝牙语音遥控器" \
  --output-dir "$HOME/Desktop/mi-ao-test"
```

## Update MI-AO

Stop the running bridge, then:

```bash
cd /path/to/mi-ao
git pull --ff-only
./scripts/setup.sh
./scripts/verify-install.sh
```

Setup rebuilds and replaces `~/Applications/米遥.app` while retaining the model and recordings. If macOS asks again, grant Accessibility only to this installed app.

## Uninstall and cleanup

Remove the app while retaining models and recordings:

```bash
./scripts/uninstall.sh
```

Remove the app, Whisper model, recordings and captures:

```bash
./scripts/uninstall.sh --all-data
```

`--all-data` is irreversible. Back up any transcript that must be retained.

## Current boundaries

- End-to-end verified hardware: Xiaomi Bluetooth Remote Control 2 Pro firmware 2671.
- The voice button is the only production input today; D-pad, action mapping and pointer mode remain on the [Roadmap](ROADMAP.md).
- The terminal must remain open; menu bar, background service and login start are not implemented yet.
- Default submission targets only the Codex macOS app with bundle ID `com.openai.codex`.
- Do not use `--force-submit` as a daily option because it relaxes editor validation.

Bring up any other remote with the redacted [hardware evidence workflow](HARDWARE_BRINGUP.md) before claiming compatibility.
