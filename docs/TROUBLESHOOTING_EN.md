<!-- Copyright (c) 2026 FanXeon@Poemcoder with Codex -->

# Troubleshooting

[中文](TROUBLESHOOTING.md) · [Pair and connect](PAIRING_EN.md) · [Quick start](QUICKSTART_EN.md)

## Start with diagnostics

```bash
./scripts/verify-install.sh
```

This checks the app, Bundle ID, signature, Codex process, Bluetooth and Accessibility permissions, `whisper-cli`, and the model.

## The remote does not appear in Bluetooth settings

Open System Settings → Bluetooth, then press and hold Menu + `HOME` simultaneously on the Xiaomi Bluetooth Remote Control 2 Pro. Click Connect when the remote appears and wait for the Connected status.

If it still does not appear, check the batteries, move it closer to the Mac, and temporarily turn off Bluetooth on its previously paired TV or set-top box. See the [pairing and first connection guide](PAIRING_EN.md) for forgetting a stale pairing, retrying and running the first safe test.

## The remote is not found

- Separate system pairing from the bridge connection: if macOS is not Connected, repeat pairing first; if macOS is Connected but MI-AO cannot find it, inspect the name filter, permissions and other MI-AO processes.
- Confirm macOS shows the device as connected.
- Connected BLE devices may stop advertising; prefer a stable `--name` filter.
- Make sure the filter matches part of the name shown by macOS.
- Do not run two MI-AO bridge processes at the same time.

## The voice button does nothing

Wait for the ready message first. If it never appears, stop with `Control + C`, confirm Bluetooth, run the verification script, and restart with `--debug`. A working session should log `AUDIO_START` after the button is held.

## A transcript exists but Codex receives nothing

MI-AO copies the transcript instead of submitting when its safety check fails.

- `Codex is not running`: open the Codex app.
- Accessibility is missing: authorize `~/Applications/米遥.app`.
- A unique editor cannot be focused: close overlapping Codex dialogs or multi-editor states and retry.

Do not use `--force-submit` as a routine workaround; it bypasses the unique-editor check.

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

## The foreground app reacts during calibration

`debug-buttons` does not synthesize MI-AO actions, but macOS can still handle the original remote HID key. Stop calibration, focus an empty window where arrows or Back cannot lose work, and retry. Do not calibrate in an unsaved editor, file list, or destructive confirmation dialog.

## Pointer movement and the foreground app both react

Correlated event filtering is still an implementation preview. Consumer Control or system-defined events may not pass through the Quartz `keyDown` / `keyUp` filter. Stop immediately with `Control + C`, restart with `--no-buttons`, and report the specific button, macOS version, remote firmware, and redacted log. Do not treat a global keyboard remap as a routine workaround.

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
