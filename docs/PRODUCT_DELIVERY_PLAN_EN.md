<!-- Copyright (c) 2026 FanXeon@Poemcoder with Codex -->

# Product Delivery Plan: Alpha to User-Ready

This plan defines the path from MI-AO's current source-first alpha to a product that a non-developer can use every day. A milestone is complete only when the real device, system permissions, persisted state, failure recovery, and public documentation form an end-to-end user path.

See the bilingual [development status snapshot](DEVELOPMENT_STATUS.md) for the currently verified baseline, active phase, and explicit not-yet-delivered boundary.

## Final delivery definition

A user without Swift experience must be able to:

1. Install MI-AO and grant Bluetooth and Accessibility permissions through the setup guide.
2. Connect a Xiaomi Bluetooth Remote Control 2 Pro and see its real connection and hardware-profile state.
3. choose the official preset or duplicate it into a personal preset.
4. Press a real remote button and verify the matching highlighted control before execution.
5. Record, test, save, reset, export, and import standard keyboard shortcuts without restarting the app.
6. Enable launch at login and use voice, Codex controls, or custom shortcuts without a terminal.
7. Recover safely from disconnects, revoked permissions, invalid presets, or an unwanted mapping.

## Current verified baseline

Already implemented:

- Xiaomi Remote 2 Pro firmware 2671 BLE audio, ADPCM decoding, local Whisper, and guarded Codex submission.
- A strict hardware-profile/action-preset split; changing an action never rewrites calibration evidence.
- The default `pointer` preset, pointer/directional D-pad modes, HOME click arbitration, Codex task navigation, and safe mapping restoration.
- A first-run setup guide, real menu-bar state, self-contained app runtime, and a launch gate that leaves mappings untouched on failure.
- The official 06 “Center Connection” logo, AppIcon, macOS monochrome template, and archived source concepts.

Not yet implemented and not to be marketed as complete: visual device selection, persisted preferences, launch at login, the custom-shortcut editor, automatic updates, and Developer ID distribution.

## Stable architecture boundary

```text
Device layer: HID Usage → physical RemoteButton (reviewable hardware evidence)
Action layer: RemoteButton → built-in action or keyboard shortcut (user preference)
```

- User presets never modify the hardware profile.
- MI-AO acts only on the exact matched remote; it does not install a global keyboard event tap.
- Custom actions v1 supports built-in actions and standard keyboard shortcuts only. Arbitrary shell commands, AppleScript, and downloaded executable content are out of scope.
- Menu remains the native macOS right-click in v1.
- Voice remains hold-to-talk and TV remains the D-pad mode switch by default. Any future advanced override must explain the recovery path the user is removing.

## Custom-shortcut contract

### Versioned data

```text
ShortcutPreset
  id, name, schemaVersion, source, updatedAt
  actions[RemoteButton] = BuiltInAction | KeyboardShortcutSpec

KeyboardShortcutSpec
  keyCode
  modifiers: command, option, control, shift, function
  displayLabel
```

- Persist key code plus modifiers rather than an input-method-dependent character.
- Store user presets under `~/Library/Application Support/mi-ao/presets/` with a `0700` directory and `0600` JSON files.
- Official presets are read-only. Editing one first creates a user-owned copy.
- Validate schema, allowed buttons, modifiers, and safety policy before importing or executing a preset.
- Use atomic writes and retain the last valid preset if a reload fails.

### GUI flow

1. Open Settings → Buttons & Shortcuts.
2. Choose a preset or select “Duplicate as My Preset”.
3. Press a real remote button to highlight its diagram and list row without executing it.
4. Choose a built-in action or start shortcut recording.
5. Show a normalized label such as `⌘⇧K`, `F8`, or `Page Down`.
6. Warn about duplicate mappings, modifier-only input, system-reserved shortcuts, and lost recovery controls.
7. Execute exactly one guarded test and show the real result.
8. Atomically save and hot-reload; keep the previous valid preset on failure.

### Execution safety

- Reject modifier-only shortcuts.
- Reject high-risk combinations such as Command-Q and Command-Tab by default.
- Produce symmetrical key-down and key-up events, and release every held modifier on disconnect, preset switch, error, or exit.
- Do not repeat a shortcut while held unless that action explicitly permits repeat.
- Missing Accessibility permission is a real failure with a repair action, never a fake success.
- Diagnostics may record action identifiers and timestamps, but never typed user text.

### Acceptance gate

- Saved mappings apply immediately and survive both app and Mac restarts.
- Only the target remote triggers them; the Mac keyboard and other input devices remain unaffected.
- Reset, duplicate, rename, delete, import, export, migration, and corrupted-file fallback have automated tests.
- Forced termination, disconnect, and mid-action preset switching leave no stuck modifier keys.
- A damaged preset is quarantined and the app returns to the official preset with a truthful explanation.
- Menu right-click, hold-to-talk, the default TV mode switch, and safe exit pass real-device acceptance.

## Delivery phases

### P0 · Release baseline and brand assets

- [x] Stable product identity, bundle ID, attribution, and non-endorsement boundary.
- [x] Nine source concepts, selected 06 reference, SVG master, PNG exports, monochrome template, and AppIcon.
- [x] Brand assets copied into the app bundle and verified by build tests.
- [ ] Install the rebuilt icon in a planned batch update so the current Accessibility authorization is not disrupted mid-work.

### P1 · Preferences v2 and daily startup

- [x] Add schema-versioned `AppPreferences` with atomic save, private permissions, corrupted-state quarantine, and future-schema preservation.
- [x] Add a real `SMAppService.mainApp` Launch at Login toggle with enabled, requires-approval, disabled, and unavailable states.
- [x] Persist automatic Codex submission versus transcription-only mode and the remote-button-control switch.
- [ ] Complete installed-app enable, relogin launch, disable, and ad-hoc update re-registration acceptance.

### P2 · Custom-action core (in progress)

- [x] Extend the fixed `ButtonAction` contract with versioned `KeyboardShortcutSpec` and an explicit TV preset target.
- [x] Add a private user-preset store with atomic save, corruption quarantine, schema protection, and official-default fallback.
- [x] Extend the executor with guaranteed modifier cleanup and interruption handling.
- [x] Add TV-target, reserved-shortcut, and safe-preset tests.
- [ ] Add import/export and cross-version migration.

### P3 · Buttons & Shortcuts GUI (in progress)

- [x] Add a Button Configurations tab with an accessible text list and separate button-map guide.
- [x] Support create, duplicate, rename, delete, action selection, shortcut recording, save/select, and TV target selection.
- [ ] Add real-button highlight, one-shot testing, import/export, reset, and cross-app hot reload.
- [ ] Complete Chinese/English copy, VoiceOver, keyboard navigation, high contrast, and 390 px narrow-window acceptance.

### P4 · Device management and resilient connection

- [ ] Show real scan results, explicit target-device selection, and persisted identity.
- [ ] Add backoff reconnect with visible next attempt and an actionable terminal failure.
- [ ] Require explicit choice when multiple compatible remotes are present.
- [ ] Complete multi-display, simultaneous Mac-keyboard, long-press, and eight-hour soak tests.

### P5 · Non-developer installation and maintenance

- [ ] Join install, permissions, device, voice, button test, preset, and login start into one first-run journey.
- [ ] Expose device, current preset, pause controls, diagnostics, and safe exit in the menu-bar app.
- [ ] Add repository-independent update checks, migration, uninstall cleanup, and a redacted diagnostic bundle.
- [ ] Pass a no-terminal daily-use run from a clean macOS user account.

### P6 · 1.0 release gate

- [ ] A reproducible compatibility matrix for at least two real remote models.
- [ ] Privacy, shortcut safety, abnormal-exit, import, and update reviews.
- [ ] Complete Chinese and English install, usage, mapping, troubleshooting, privacy, uninstall, and recovery docs.
- [ ] Independent clean-Mac acceptance from the public README through custom-shortcut use.
- [ ] Keep the auditable source-first release; Developer ID signing, notarization, and binary updates remain an optional distribution channel until genuinely available.

## Immediate next work

1. Complete the installed-app `SMAppService` acceptance cycle, including an ad-hoc update.
2. Complete real-device acceptance for a two-preset TV transition and shortcut release/interruption cleanup.
3. Add import/export, one-shot testing, and cross-app hot reload.

MI-AO is “fully user-ready” only when daily use requires no terminal, every success comes from real system/device evidence, failure paths remain actionable, and custom shortcuts never affect the Mac keyboard or leave modifier keys held.

Created and maintained by **FanXeon@Poemcoder with Codex**.
