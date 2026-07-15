<!-- Copyright (c) 2026 FanXeon@Poemcoder with Codex -->

# Usage Guide

[中文](USAGE.md) · [Pair and connect](PAIRING_EN.md) · [Quick start](QUICKSTART_EN.md) · [Troubleshooting](TROUBLESHOOTING_EN.md)

This guide starts after installation and covers daily startup, hold-to-talk behavior, success signals, safe modes, updates and local data cleanup. Complete the [3-minute quick start](QUICKSTART_EN.md) first.

## Current launch model

MI-AO is currently a **source-first alpha**. Start it from the cloned repository:

```bash
cd /path/to/mi-ao
./scripts/run-with-mapping.sh --name "小米蓝牙语音遥控器"
```

Keep the terminal open while MI-AO is running. The current version has no menu bar, login item or visible recording overlay. Do not rely on double-clicking `米遥.app` for daily use because connection, transcript and failure messages would be hidden.

## Daily use in four actions

### 1. Prepare

- Confirm that `小米蓝牙语音遥控器` is connected in System Settings → Bluetooth. If it has not been paired, hold Menu + `HOME` simultaneously and follow the [pairing and first connection guide](PAIRING_EN.md).
- Open the Codex macOS app.
- Open the Codex task that should receive the instruction and close dialogs covering its editor.

### 2. Start MI-AO

```bash
cd /path/to/mi-ao
./scripts/run-with-mapping.sh --name "小米蓝牙语音遥控器"
```

The wrapper matches only Vendor `0x2717` / Product `0x32B8`. It maps D-pad, Center, Back, HOME, TV, Power, Voice, and Volume Up/Down—twelve keys total—to HID `No Event`; Menu is excluded and keeps the native macOS right-click. Volume Up/Down selects the previous/next Codex task. It restores the original mapping on exit.

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
./scripts/run-with-mapping.sh --name "小米蓝牙语音遥控器"
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

In run mode, `--debug` also prints `HID down/up → physical button`, separating hardware recognition, preset mapping, and action execution failures.

Debug output can include raw device data and must be redacted before sharing. See [Troubleshooting](TROUBLESHOOTING_EN.md) for failure-specific steps.

## Learn physical buttons

The button learner listens only to the selected remote's HID Vendor/Product IDs and excludes the Mac's built-in keyboard. Run a full Xiaomi Remote 2 Pro scan with:

```bash
./scripts/learn-buttons.sh \
  --name "小米蓝牙语音遥控器"
```

Press and release each button once when prompted. Use single-button mode to eliminate prompt timing errors or verify one result:

```bash
./scripts/learn-buttons.sh \
  --name "小米蓝牙语音遥控器" \
  --button back \
  --button-seconds 20
```

Use confirmation-gated debug mode when producing a trusted production mapping:

```bash
./scripts/debug-buttons.sh \
  --name "小米蓝牙语音遥控器"
```

After every release, the terminal shows “physical button → HID Usage → current preset action.” The debugger does not execute MI-AO pointer, Codex, or system actions. Because an unprivileged process cannot exclusively seize this HID device, the original key may still be handled by macOS or the frontmost app during calibration. Focus a safe window first. Enter:

- `Return` or `y` to confirm and save;
- `r` to discard and retry the current button;
- `s` to mark the current button skipped;
- `q` to stop and save only previously confirmed entries.

For example, Back displays Usage Page `0x07` / Usage `0xF1`, previewed as `keyboard.escape` under the default `pointer` preset. Confirmation stores only that the Usage is the physical `back` button; it does not store Escape action semantics.

Valid IDs are `voice`, `dpad_up`, `dpad_down`, `dpad_left`, `dpad_right`, `center`, `back`, `home`, `menu`, `volume_up`, `volume_down`, `tv`, and `power`.

Reports are written to:

```text
~/Library/Application Support/mi-ao/button-profiles/
```

They contain normalized HID Usage values, raw values, press, release and repeat evidence, plus the confirmation result. They do not store an action preset, MAC address, CoreBluetooth UUID, serial number, or host-keyboard events. On Xiaomi Remote 2 Pro firmware 2671, an isolated retest verified Back as Keyboard Usage Page `0x07` / Usage `0xF1`, with both press and release observed. The older report lacks the new `captureMode` trust marker, so Back must be reconfirmed before pointer mode can use it. Every other button also requires confirmed calibration.

## Enable the default pointer mode

After confirming all four D-pad directions, Center, and Back, restart the normal command. `pointer` is the default preset:

```bash
./scripts/run.sh --name "小米蓝牙语音遥控器"
```

Use `--button-profile "/path/to/buttons-*.json"` to pin one complete profile, or `--no-buttons` for voice only. Missing buttons, duplicate Usage values, Accessibility failure, or event-filter failure disables physical-button actions with a diagnostic while voice remains available.

Inspect or recover the mapping with:

```bash
./scripts/remote-mapping.sh status
./scripts/remote-mapping.sh restore
```

One `HOME` click sends Page Down after a 350 ms double-click window. A second click inside that window cancels the pending Page Down and emits one Page Up, so a double-click never moves down before moving up.

Use `restore --force` only when the ownership state file was lost and `status` shows the exact MI-AO mapping. Any other existing user mapping is left untouched.

Startup defaults to pointer mode. A calibrated `TV` key changes only the D-pad to arrow keys; press it again to restore pointer movement. Center always sends Return, Back always sends Escape, and no other button changes with the mode. A calibrated Power key launches Codex or focuses an existing process. Xiaomi Remote 2 Pro firmware 2671 now has complete press/release evidence for `TV=0x07/0x35` and `Power=0x07/0x66`; other remotes still require independent calibration.

See [Button presets and the default pointer mode](BUTTON_PRESETS_EN.md) for the two-layer diagram, complete mapping, and safety boundary. All six required buttons are hardware-calibrated and all four directions passed direct positioning with real-coordinate monitoring; mode switching and Power remain an implementation preview.

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

Uninstall restores any neutral mapping owned by MI-AO before removing the app or local data.

## Current boundaries

- End-to-end verified hardware: Xiaomi Bluetooth Remote Control 2 Pro firmware 2671.
- Voice has completed hardware end-to-end acceptance. All six required pointer buttons are calibrated and all four directions have completed their mouse-action loop; remaining physical actions stay on the [Roadmap](ROADMAP.md).
- The terminal must remain open; menu bar, background service and login start are not implemented yet.
- Default submission targets only the Codex macOS app with bundle ID `com.openai.codex`.
- Do not use `--force-submit` as a daily option because it relaxes editor validation.

Bring up any other remote with the redacted [hardware evidence workflow](HARDWARE_BRINGUP.md) before claiming compatibility.
