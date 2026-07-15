<!-- Copyright (c) 2026 FanXeon@Poemcoder with Codex -->

# Security Policy

[中文](SECURITY.md) · [English](SECURITY_EN.md)

## Supported versions

Security fixes are guaranteed only for `main` and the latest stable release. Early previews may require an upgrade before a fix can be applied.

## Reporting a vulnerability

Do not disclose exploitable vulnerabilities, recordings, device identifiers or permission-bypass techniques in a public Issue. Before making the repository public, maintainers must enable **Private vulnerability reporting**. After launch, use the repository Security page to report vulnerabilities privately.

Include:

- the affected version or commit;
- macOS, Codex and remote versions;
- minimal reproduction steps;
- the expected impact;
- the redaction already applied.

## Security boundaries

- MI-AO sends text only to `com.openai.codex` by default.
- It does not submit when the transcript is empty, Codex is not running, Accessibility is not authorized, or the active composer cannot be proven unique.
- When submission and button control are both disabled, Accessibility and Codex become optional; Bluetooth and the local engine remain core requirements.
- Current Codex builds require `--force-renderer-accessibility` to expose the current process web accessibility tree. MI-AO still submits only when exactly one usable text input exists in that tree.
- `codex-accessibility.sh enable` uses only Codex's built-in per-process launch argument. It changes no preferences, opens no remote debugging port, and expires when Codex quits; `disable --restart` returns to a native launch.
- Text still enters Codex through the guarded clipboard paste path. MI-AO does not read conversation content.
- `--force-submit` relaxes focus validation and should only be used in a controlled environment.
- Raw WAV files and transcripts can contain private information. They stay local by default and must not be committed to Git.
- The recordings directory uses mode `0700`; WAV, final transcript and raw Whisper text files use `0600`. They remain sensitive local data and need an explicit retention decision.
- `preferences.json` uses schema v1, atomic writes, and `0600`; corrupted input is quarantined and a future schema is preserved rather than executed or overwritten.
- Automatic submission restores the clipboard only when its `changeCount` still matches MI-AO's injected content. New clipboard data from the user or another app is never overwritten.
- `capture` hashes peripheral UUIDs and hides device names by default. Original values are retained only with `--include-identifiers` or `--include-device-names`.
- `events.jsonl` can contain unknown GATT payloads. Those bytes may include button, audio or device data, so every capture requires manual review before public sharing even when identities are redacted.
- The verified Xiaomi Remote 2 Pro starts from the built-in firmware 2671 hardware profile. Local confirmed calibration overrides that baseline; explicit invalidation, duplicate Usage assignments, or missing Accessibility prevents button runtime startup.
- `run-with-mapping.sh` executes `check-buttons` before any system change. Once ready, it modifies only the exactly matched Xiaomi remote HID service, requires an empty mapping, verifies every write, and uses local ownership state for restore. Unknown or user-defined mappings are never overwritten or deleted.
- Normal submission startup also runs a Codex compatibility gate: a closed Codex app may be launched compatibly, while a running process without the argument causes a safe refusal instead of an automatic restart. `--no-submit` does not require this gate.
- `run-with-mapping.sh` uses a tokenized single-instance lock that records the real app PID. `start.sh`, `stop.sh`, menu-bar safe exit, normal app exit, and the outer wrapper all perform ownership-checked restore.
- `--no-buttons`, `--help`, and the original `run.sh` do not apply neutralization. Uninstall attempts to restore MI-AO-owned mappings first.
- Physical-button mode takes over twelve keys: D-pad, Center, Back, HOME, TV, Power, Voice, and Volume Up/Down. Exact-device HID `No Event` prevents native side effects; Menu is excluded and keeps the native macOS right-click. MI-AO creates no global keyboard event tap and does not intercept the Mac's physical keyboard. Use `--no-buttons` during sensitive editing.
- Launch at Login is always optional and uses `SMAppService.mainApp`; MI-AO installs no custom LaunchAgent and requests no administrator privilege. ServiceManagement is the single source of truth.
- Login and manual launch invoke the same bundled gate. An ad-hoc identity change is reported for re-registration instead of being bypassed with a weakened code requirement.
