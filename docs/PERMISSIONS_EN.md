<!-- Copyright (c) 2026 FanXeon@Poemcoder with Codex -->

# Permissions and Optional Features

MI-AO requests a capability only when the currently selected feature needs it. The setup guide uses three labels:

- **Required:** the core voice path cannot run without it.
- **Required by enabled features:** it blocks startup only while the dependent feature is enabled.
- **Optional:** declining it does not block local speech transcription.

## Permission matrix

| Item | Default full mode | Transcription only, buttons off | Can be declined? | Purpose |
| --- | --- | --- | --- | --- |
| macOS 14+ | Required | Required | No | Runtime contract for CoreBluetooth, ServiceManagement, and the app |
| Local speech engine and model | Required | Required | No | Transcribe remote audio locally |
| Bluetooth | Required | Required | No | Connect to the remote and read BLE voice data |
| Bundled runtime components | Required | Required | No | Safe start/stop, button gate, and restoration |
| Accessibility | Feature-required | Optional | Yes | Codex submission, pointer movement, keyboard and menu actions |
| Codex app | Feature-required | Optional | Yes | Submission and the default preset's task navigation/focus actions |
| Codex composer compatibility | Required for submission | Optional | Yes | Verify exactly one composer; button-only control does not need it |
| Launch at Login | Optional | Optional | Yes | Run the same guarded startup path after macOS login |

## Recommended configurations

### Full Codex mode (default)

Automatic Codex submission and remote button control are enabled. Bluetooth, the local engine, Accessibility, Codex, and composer compatibility are required by the enabled features. Launch at Login remains optional.

### Transcribe and copy only

Turn off both automatic submission and button control. Only Bluetooth, the local engine, and bundled runtime are required. Accessibility, Codex, and Launch at Login can all remain disabled.

### Voice submission without button interception

Keep automatic submission on and turn button control off. Bluetooth, the local engine, Accessibility, and Codex composer compatibility remain feature-required. MI-AO does not apply the twelve-button `No Event` mapping.

## Why Launch at Login is optional

MI-AO uses macOS 13+ `SMAppService.mainApp`, not a custom LaunchAgent and not an administrator service. The switch reflects the real ServiceManagement state:

- **Disabled:** manual launch remains available.
- **Enabled:** macOS launches MI-AO after login.
- **Requires approval:** the request is registered, but the user must allow it in System Settings → General → Login Items & Extensions.
- **Unavailable:** the current app location, installation, or signature cannot be registered; MI-AO never reports a fake success.

Login launch never bypasses setup or the button gate. After the first successful start, a no-argument app launch reads the same preferences and invokes the same bundled `start.sh` path. Failure reopens the setup guide. Disabling the login item does not affect manual use.

The source-first beta uses ad-hoc signing. A rebuilt binary may need its login item or Accessibility authorization registered again; MI-AO does not weaken the system identity boundary to hide this.

## Permissions MI-AO does not request

- No Mac microphone permission: audio comes from the remote's BLE microphone path.
- No Screen Recording permission.
- No Full Disk Access.
- No Input Monitoring permission or global keyboard event tap.
- No speech-cloud API permission after the local model is installed.

## Preference storage

Feature choices are stored at:

```text
~/Library/Application Support/mi-ao/preferences.json
```

The current schema is v1. The directory is `0700`, the file is `0600`, writes are atomic, corrupted JSON is quarantined, and a future schema is preserved instead of overwritten. Launch at Login is not duplicated in JSON; `SMAppService` remains the single source of truth.

Created and maintained by **FanXeon@Poemcoder with Codex**.
