<!-- Copyright (c) 2026 FanXeon@Poemcoder with Codex -->

# Troubleshooting

[中文](TROUBLESHOOTING.md) · [Quick start](QUICKSTART_EN.md)

## Start with diagnostics

```bash
./scripts/verify-install.sh
```

This checks the app, Bundle ID, signature, Codex process, Bluetooth and Accessibility permissions, `whisper-cli`, and the model.

## The remote is not found

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
