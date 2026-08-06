# Blitztext Platform Strategy

This document describes how Blitztext should grow from the current macOS app into a four-platform product for macOS, Windows, Linux, and iOS.

The important principle: do not fork the macOS app into separate long-lived copies. Keep Blitztext as one product with platform-specific apps and shared product contracts.

## Current State

The repository currently contains a native macOS menu bar app in `BlitztextMac/`.

The macOS app includes:

- Workflow definitions for Blitztext, Blitztext+, Blitztext $%&!, and Blitztext :).
- OpenAI transcription and rewriting clients.
- Optional local transcription through WhisperKit/CoreML.
- macOS-specific integrations:
  - menu bar app shell
  - global hotkeys
  - microphone recording
  - Accessibility permission and paste behavior
  - macOS Keychain storage
  - Launch at Login
  - App Support paths
  - XcodeGen and Xcode project setup

This is a good stable reference implementation, but it should not become the base for copy-pasted Windows, Linux, and iOS forks.

## Target Shape

Recommended long-term repository shape:

```text
blitztext-app/
  apps/
    mac/
    windows/
    linux/
    ios/
  shared/
    product/
    workflows/
    prompts/
    api-contracts/
    settings/
    test-fixtures/
  docs/
    platform-strategy.md
    platform-notes/
```

The existing `BlitztextMac/` folder can stay where it is at first. A later cleanup can move it to `apps/mac/` once the platform direction is stable.

## Shared Product Layer

The shared layer should describe behavior that must stay consistent across platforms. It does not need to be shared executable code on day one.

Good candidates for shared ownership:

- Workflow names, descriptions, and expected behavior.
- Prompt templates and rewriting rules.
- OpenAI request and response contracts.
- Settings schema:
  - selected language
  - secure local mode
  - selected local model
  - custom workflow names
  - custom terms
  - tone settings
  - emoji density
- Error categories and user-facing recovery states.
- Test fixtures for workflow input and expected output shape.
- Privacy and data-flow rules.

For the first phase, `shared/` can contain Markdown, JSON schemas, and fixture files. Shared runtime code can be added later only if it genuinely reduces duplication.

## Platform Adapter Layer

Each platform app should own its operating-system integrations.

| Capability | macOS | Windows | Linux | iOS |
| --- | --- | --- | --- | --- |
| App shell | Menu bar app | Tray app or compact desktop app | Tray app or compact desktop app | Mobile app |
| Global hotkeys | Current Swift service | Windows hotkey API | Desktop environment dependent | Limited or unavailable system-wide |
| Text insertion | Accessibility/pasteboard | Clipboard, UI Automation, SendInput | Clipboard, X11/Wayland-specific APIs | Share sheet, clipboard, app-internal output |
| Credentials | Keychain | Windows Credential Manager | Secret Service/libsecret or encrypted local store | Keychain |
| Autostart | Launch at Login | Startup task/registry/startup folder | XDG autostart/system-specific | Not applicable in same way |
| Audio recording | AVFoundation | WASAPI/.NET audio stack | PulseAudio/PipeWire/ALSA abstraction | AVAudioSession/AVFoundation |
| Local transcription | WhisperKit/CoreML | whisper.cpp, ONNX Runtime, or native library | whisper.cpp, ONNX Runtime, or native library | CoreML or Apple-native path |
| Packaging | `.app`, signing, notarization | MSIX/installer, signing | AppImage/deb/rpm/Flatpak | App Store/TestFlight/signing |

## Technology Direction

### macOS

Keep the current Swift/SwiftUI macOS app stable. It already uses native APIs effectively and should remain the reference behavior.

### iOS

Use Swift/SwiftUI. iOS can share concepts with the macOS implementation, but it is not the same product surface:

- No general-purpose global hotkey workflow.
- No background menu bar/tray model.
- Text output likely works through copy, share sheet, app extensions, or in-app composition.
- Local transcription may use Apple-native/CoreML paths where practical.

### Windows

Recommended default: C#/.NET with WinUI/WPF, or a careful evaluation of Tauri.

C#/.NET is attractive for system integration:

- tray app support
- global hotkeys
- Windows Credential Manager
- audio APIs
- installer tooling
- UI Automation or clipboard-based text insertion

Tauri is attractive if Windows and Linux should share more UI and application structure.

### Linux

Recommended default: pair with the Windows decision.

If Windows uses Tauri, Linux can likely share the same app shell and much of the UI. If Windows uses C#/.NET, Linux could use Avalonia or a separate Tauri/GTK approach.

Linux needs extra caution around:

- X11 vs. Wayland behavior
- global hotkeys
- text insertion into other apps
- tray support differences across desktop environments
- audio stack differences
- packaging fragmentation

## Recommended Implementation Order

1. Keep `BlitztextMac/` unchanged as the working reference.
2. Create shared product contracts:
   - workflow definitions
   - prompt definitions
   - settings schema
   - API contracts
   - privacy/data-flow expectations
3. Decide the Windows/Linux desktop stack:
   - C#/.NET plus separate Linux decision
   - or Tauri for shared Windows/Linux desktop code
4. Build a minimal Windows spike:
   - tray or small window
   - microphone record
   - OpenAI API key storage
   - remote transcription
   - copy/paste output
5. Build the same minimal Linux spike.
6. Design the iOS-specific product flow separately.
7. Only after the second platform works, consider moving the repository into `apps/` and `shared/`.

## First Milestone

The first milestone should prove that the core Blitztext loop works outside macOS:

```text
press control -> record speech -> transcribe -> place text where the user needs it
```

For Windows and Linux, start with remote transcription before local transcription. Local models can be added after the app shell, audio, credentials, and output flow are reliable.

## Repository Guidance

Do not create four independent forks.

Prefer one repository while the product is still evolving:

- shared behavior stays visible
- documentation stays together
- workflow changes are easier to propagate
- bugs in common API usage can be fixed once conceptually
- platform differences are explicit instead of accidental

A separate repository per platform can be considered later if release engineering, ownership, or build tooling becomes too heavy for one repo.

## Immediate Next Steps

- Add `shared/` with product contracts, not code-heavy abstractions.
- Add `docs/platform-notes/windows.md`.
- Add `docs/platform-notes/linux.md`.
- Add `docs/platform-notes/ios.md`.
- Evaluate Tauri vs. C#/.NET for Windows/Linux before scaffolding.
- Keep the current macOS build path untouched until a second platform has a working spike.
