# Contributing to MI-AO

[中文](CONTRIBUTING.md) · [Back to README](README_EN.md)

MI-AO prioritizes reproducible changes backed by real hardware evidence.

MI-AO is created and maintained by **FanXeon@Poemcoder with Codex**. By contributing, you agree that your contribution may be distributed under the project [MIT License](LICENSE); you retain the authorship and rights that legally arise from your contribution.

## Development setup

- macOS 14+
- Swift 6+
- Xcode Command Line Tools
- Homebrew (`whisper-cpp` is only required for runtime transcription)

```bash
git clone https://github.com/fanxeon/mi-ao.git
cd mi-ao
make check
```

Unit tests and the release build do not require a Whisper model or a connected remote.

## Workflow

1. Open an issue describing the device, firmware, macOS version, and reproducible behavior.
2. Create a short-lived branch from `main`.
3. Keep each pull request focused on one problem.
4. Add a test fixture, redacted hardware evidence, or both.
5. Run `make check` before opening the pull request.

Never commit personal speech, device addresses, peripheral UUIDs, serial numbers, usernames, API keys, or unreviewed capture payloads.

## Hardware compatibility evidence

A new device contribution should include as much of the following as possible:

- device model, firmware, and macOS version;
- advertised and connected services;
- characteristic UUIDs, properties, and notification direction;
- capability negotiation;
- press, hold, release, timeout, and disconnect behavior;
- audio frame size and codec evidence;
- a non-private test phrase and redacted logs.

Compatibility claims without real hardware evidence are not merged. Follow [Hardware bring-up](docs/HARDWARE_BRINGUP.md) and [Compatibility](docs/COMPATIBILITY.md).

## Commit messages

Use concise imperative messages, for example:

```text
Add ATVV v1.0 audio stop handling
Fix connected remote discovery
Document Remote 2 Pro firmware evidence
```

## Pull requests

Describe the change, verification, risk, and any privacy or Accessibility impact. UI automation changes must preserve the default fail-safe behavior: if MI-AO cannot prove where text will go, it must not submit.
