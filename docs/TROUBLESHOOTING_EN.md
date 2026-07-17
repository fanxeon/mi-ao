<!-- Copyright (c) 2026 FanXeon@Poemcoder with Codex -->

# Troubleshooting

[中文](TROUBLESHOOTING.md) · [Pair and connect](PAIRING_EN.md) · [Quick start](QUICKSTART_EN.md)

## Start with diagnostics

```bash
./scripts/verify-install.sh
```

This checks the app, Bundle ID, signature, Codex process, Bluetooth, Accessibility, Codex composer automation, `whisper-cli`, and the model.

It also reports remote mapping state. After an abnormal exit, run `./scripts/remote-mapping.sh status`; if MI-AO neutralization remains active, keep the remote connected and run `./scripts/remote-mapping.sh restore`. Unknown user mappings are never deleted.

If a foreground debug terminal reports `suspended`, `Control + Z` paused the process. The wrapper catches the suspend signal, terminates its child, and restores the mapping. For daily use, stop from the menu bar or run `./scripts/stop.sh`.

## MI-AO is running but its menu-bar icon is not visible

First double-click `~/Applications/米遥.app`. If the settings window reports that MI-AO is already running, the background runtime exists; do not keep starting additional instances.

On a notched MacBook, too many right-side status items can exceed the visible menu-bar width and leave the MI-AO item behind the camera housing. This is a menu-bar layout boundary, not a crash.

1. Temporarily quit unneeded menu-bar apps to free right-side width.
2. If available, use a non-notched external display to confirm the MI-AO status item.
3. If the safe-exit item remains inaccessible, run `./scripts/stop.sh` from the project directory; it stops the runtime and restores the remote mapping.

Only continue as a real status-item failure when enough right-side space is available and a fresh start still produces no visible item.

## The remote does not appear in Bluetooth settings

Open System Settings → Bluetooth, then press and hold Menu + `HOME` simultaneously on the Xiaomi Bluetooth Remote Control 2 Pro. Click Connect when the remote appears and wait for the Connected status.

If it still does not appear, check the batteries, move it closer to the Mac, and temporarily turn off Bluetooth on its previously paired TV or set-top box. See the [pairing and first connection guide](PAIRING_EN.md) for forgetting a stale pairing, retrying and running the first safe test.

## The remote is not found

- Separate system pairing from the bridge connection: if macOS is not Connected, repeat pairing first; if macOS is Connected but MI-AO cannot find it, inspect the name filter, permissions and other MI-AO processes.
- Confirm macOS shows the device as connected.
- Connected BLE devices may stop advertising; prefer a stable `--name` filter.
- Make sure the filter matches part of the name shown by macOS.
- Do not run two MI-AO bridge processes at the same time.

`start.sh` rejects a second instance and reports the current process. If that state is stale, run `./scripts/stop.sh` to clean up and confirm mapping restoration before starting again.

## The menu keeps reconnecting or reports “Smart Sleep”

The remote is not answering ATVV capability negotiation. Check Settings & Diagnostics → Usage Preferences → Voice Connection first:

- Always Ready is the default. It backs off from one second to a maximum interval of 60 seconds and continues recovering instead of giving up after a few seconds.
- Smart Sleep makes two quick automatic recovery attempts, then stops background handshakes and reports that a button press can wake voice.
- The HID path remains independent in both modes. Recognized HID activity interrupts a countdown or wakes Smart Sleep immediately.
- The menu-bar “Retry/Wake Voice Connection” action and Bluetooth power recovery also reconnect immediately.
- Do not repeatedly relaunch the app. Confirm the target device, then inspect `~/Library/Application Support/mi-ao/logs/mi-ao.log` for subscription and `GET_CAPS` records.

## The voice button does nothing

Wait for the ready state first. If it never appears, use menu-bar safe exit or `./scripts/stop.sh`, confirm Bluetooth, run the verification script, and restart in foreground with `--debug`. A working session should log `AUDIO_START` after the button is held.

## A transcript exists but Codex receives nothing

MI-AO copies the transcript instead of submitting when its safety check fails.

- `Codex is not running`: open the Codex app.
- Accessibility is missing: authorize `~/Applications/米遥.app`.
- `Composer candidates: 0`: run `./scripts/codex-accessibility.sh enable --restart`, open an editable Codex task, and retry.
- The unique Accessibility editor cannot be focused: check compatibility, then close overlapping dialogs or multi-editor states and retry.

Check the compatibility state first:

```bash
./scripts/codex-accessibility.sh status
./scripts/authorize.sh
```

The compatibility argument affects only the current Codex process, changes no preferences, and opens no debugging port. It expires when Codex quits; reverse it immediately with `./scripts/codex-accessibility.sh disable --restart`.

Do not use `--force-submit` as a routine workaround; it bypasses the unique-editor check.

## System Settings says MI-AO is on, but the guide still says unauthorized

This is an identity change after rebuilding the source-first ad-hoc app, not a missed toggle. The stale row can remain enabled, but it is tied to the previous binary CDHash and does not authorize the current build.

1. In System Settings → Privacy & Security → Accessibility, select the old “米遥” row and remove it with `-`.
2. Choose `+` and add `~/Applications/米遥.app` again.
3. Enable the new row. Keep the guide open; it refreshes automatically within 1.5 seconds without restarting MI-AO.

The guide's “修复权限” action opens the correct pane and reveals the current app in Finder. `./scripts/authorize.sh` now opens that real app guide instead of reporting the potentially misleading state of a Terminal-launched child process.

## Launch at Login is unavailable or requires approval

- “Requires approval” means the optional request still needs approval in System Settings → General → Login Items & Extensions.
- “Unavailable” usually means the app is running from `dist` or `.build`, or ServiceManagement has not located the current signature yet. From the installed app, toggle it once to retry registration and surface the real `SMAppService` error; reinstall only if that retry still fails.
- An ad-hoc update may require the old login item to be disabled and the current app registered again.
- Manual launch remains available. MI-AO reports the real `SMAppService` state and never substitutes a local success flag. See [Permissions](PERMISSIONS_EN.md).

## Voice works but pointer mode does not start

This is a safe fallback, not a voice failure. Follow the specific terminal diagnostic:

- Missing confirmed calibration: run `./scripts/debug-buttons.sh --name "小米蓝牙语音遥控器"` and confirm all four D-pad directions, Center, and Back.
- Calibration conflict: two physical buttons share one Usage; retest each with `--button <id>`.
- Accessibility or event-filter failure: run `./scripts/authorize.sh`, authorize the installed MI-AO app in System Settings, and restart.
- A pinned `--button-profile` fails: it must be a complete new-format `captureMode=confirmed_calibration` profile, not an automatic `learn-buttons` report.

Use voice only while deferring pointer diagnostics:

```bash
./scripts/run.sh --name "小米蓝牙语音遥控器" --no-buttons
```

See [Button presets and the default pointer mode](BUTTON_PRESETS_EN.md) for the complete gate and mapping.

## `TV` does not switch modes, or Power does not launch Codex

These keys are not part of the base six-button gate and must be calibrated separately:

```bash
./scripts/debug-buttons.sh --name "小米蓝牙语音遥控器" --button tv
./scripts/debug-buttons.sh --name "小米蓝牙语音遥控器" --button power
```

The verified Xiaomi Remote 2 Pro firmware 2671 result is `TV=0x07/0x35` and `Power=0x07/0x66`. Do not confirm a different result on the same firmware without retesting. Power on another remote may still be infrared-only. If the terminal says Codex cannot be found, confirm the official Codex macOS app is installed with bundle ID `com.openai.codex`.

## The foreground app reacts during calibration

`debug-buttons` does not synthesize MI-AO actions, but macOS can still handle the original remote HID key. Stop calibration, focus an empty window where arrows or Back cannot lose work, and retry. Do not calibrate in an unsaved editor, file list, or destructive confirmation dialog.

## Volume does not navigate Codex tasks

Confirm Codex is running and its View menu contains `Previous Task` / `Next Task`. Then calibrate `--button volume_up` and `--button volume_down` separately; Xiaomi Remote 2 Pro firmware 2671 should report `0x07/0x80` and `0x07/0x81`. MI-AO invokes these Accessibility menu items directly and synthesizes no keyboard chord. A stuck modifier is a safety defect: stop immediately and report it.

## Pointer movement and the foreground app both react

Stop immediately from the menu bar or with `./scripts/stop.sh`, then run `./scripts/remote-mapping.sh status`. A healthy state shows all twelve intercepted keys mapped to `No Event` for the current device, while Menu is absent and keeps the native macOS right-click. If state is missing or readback differs, run `./scripts/remote-mapping.sh restore` first and restart through `./scripts/start.sh`. Do not use a global keyboard remap as a workaround.

MI-AO installs no global Quartz keyboard event tap. If the physical Mac keyboard loses keystrokes or leaves a modifier stuck, stop MI-AO immediately and submit a redacted log; that is a safety defect, not an accepted limitation.

## Project terms are transcribed incorrectly

Use a short vocabulary list, not a full sentence:

```bash
./scripts/run.sh \
  --name "<device name>" \
  --prompt "MI-AO. Codex. ProjectName. DomainTerm."
```

Long prompt sentences can be continued or repeated by a small Whisper model.

## Permissions changed after reinstalling

Replacing an ad-hoc signed app can make macOS request Accessibility approval again. Avoid rebuilding and reinstalling the app during normal use.

## Recordings and transcripts

```text
~/Library/Application Support/mi-ao/recordings
```

Each run keeps a WAV and transcript so you can separate audio, Whisper, and Codex submission failures. These files can contain private speech; never attach them to a public issue without review.

If the problem remains, use the Bug Report issue template with versions, the remote model and firmware, and redacted logs. Report security issues privately according to [SECURITY_EN.md](../SECURITY_EN.md).
