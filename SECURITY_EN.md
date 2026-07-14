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
