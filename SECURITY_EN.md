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
- It does not submit when the transcript is empty, Codex is not running or Accessibility is not authorized.
- Active focus and submission require exactly one usable text input in the Codex accessibility tree by default.
- `--force-submit` relaxes focus validation and should only be used in a controlled environment.
- Raw WAV files and transcripts can contain private information. They stay local by default and must not be committed to Git.
- `capture` hashes peripheral UUIDs and hides device names by default. Original values are retained only with `--include-identifiers` or `--include-device-names`.
- `events.jsonl` can contain unknown GATT payloads. Those bytes may include button, audio or device data, so every capture requires manual review before public sharing even when identities are redacted.
- The verified Xiaomi Remote 2 Pro starts from the built-in firmware 2671 hardware profile. Local confirmed calibration overrides that baseline; explicit invalidation, duplicate Usage assignments, or missing Accessibility prevents button runtime startup.
- `run-with-mapping.sh` executes `check-buttons` before any system change. Once ready, it modifies only the exactly matched Xiaomi remote HID service, requires an empty mapping, verifies every write, and uses local ownership state for restore. Unknown or user-defined mappings are never overwritten or deleted.
- `--no-buttons`, `--help`, and the original `run.sh` do not apply neutralization. Uninstall attempts to restore MI-AO-owned mappings first.
- Physical-button mode takes over twelve keys: D-pad, Center, Back, HOME, TV, Power, Voice, and Volume Up/Down. Exact-device HID `No Event` prevents native side effects; Menu is excluded and keeps the native macOS right-click. MI-AO creates no global keyboard event tap and does not intercept the Mac's physical keyboard. Use `--no-buttons` during sensitive editing.
