# windows_screen_guard

[![pub version](https://img.shields.io/pub/v/windows_screen_guard.svg?style=flat-square&logo=dart&logoColor=white)](https://pub.dev/packages/windows_screen_guard)
[![license](https://img.shields.io/badge/license-MIT-blue.svg?style=flat-square&logo=open-source-initiative&logoColor=white)](https://github.com/AmrSabbagh35/windows_screen_guard/blob/main/LICENSE)
[![platform](https://img.shields.io/badge/platform-Windows-0078D4?style=flat-square&logo=windows&logoColor=white)](https://pub.dev/packages/windows_screen_guard)
[![Win32](https://img.shields.io/badge/Win32-SetWindowDisplayAffinity-0078D4?style=flat-square&logo=microsoft&logoColor=white)](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-setwindowdisplayaffinity)

Prevent screen capture and recording on Flutter Windows apps using the Windows display affinity API — the same method used by Netflix, banking apps, and enterprise software.

<p align="center">
  <img src="https://raw.githubusercontent.com/AmrSabbagh35/windows_screen_guard/main/assets/capture_demo.gif" width="580" alt="User sees content, capture tool sees black" />
</p>

---

## How it works

Windows exposes a kernel-level API called `SetWindowDisplayAffinity`. When called with the `WDA_MONITOR` flag, it instructs the GPU compositor to exclude your window from any capture pipeline. The result: every capture tool sees your window as **solid black**, while the user's own display is completely unaffected.

Because this happens at the driver level, no user-space screen capture software can bypass it — the same guarantee that lets Netflix play DRM content on Windows desktops.

`windows_screen_guard` wraps this API via Dart FFI using the `win32` package. No platform channels, no C++ to write, no native plugin setup.

<p align="center">
  <img src="https://raw.githubusercontent.com/AmrSabbagh35/windows_screen_guard/main/assets/shield_demo.gif" width="240" alt="Shield activation animation" />
</p>

---

## Features

[![shield](https://img.shields.io/badge/Capture_Blocking-WDA__MONITOR-0078D4?style=flat-square&logo=shield&logoColor=white)](https://pub.dev/packages/windows_screen_guard)
[![keyboard](https://img.shields.io/badge/PrintScreen_Hook-VK__SNAPSHOT-6A0DAD?style=flat-square&logo=keyboard&logoColor=white)](https://pub.dev/packages/windows_screen_guard)
[![cross-platform](https://img.shields.io/badge/Non--Windows-No--op_Safe-22863a?style=flat-square&logo=flutter&logoColor=white)](https://pub.dev/packages/windows_screen_guard)

| Feature | Details |
|---|---|
| ![shield](https://img.shields.io/badge/-Capture_Blocking-0078D4?style=flat-square&logo=fontawesome&logoColor=white) | Makes your window appear black in all screenshots and recordings |
| ![keyboard](https://img.shields.io/badge/-PrintScreen_Key_Hook-6A0DAD?style=flat-square&logo=fontawesome&logoColor=white) | Swallows `VK_SNAPSHOT` at the OS level via `SetWindowsHookEx` |
| ![bolt](https://img.shields.io/badge/-Zero_Config-F0A500?style=flat-square&logo=fontawesome&logoColor=white) | Two lines of code to protect your entire app |
| ![unlock](https://img.shields.io/badge/-No_Admin_Rights-22863a?style=flat-square&logo=fontawesome&logoColor=white) | `SetWindowDisplayAffinity` works without elevated privileges |
| ![globe](https://img.shields.io/badge/-Cross_Platform_Safe-555?style=flat-square&logo=flutter&logoColor=white) | Silent no-op on macOS, Linux, Android, and iOS |
| ![info](https://img.shields.io/badge/-Result_Reporting-c0392b?style=flat-square&logo=fontawesome&logoColor=white) | Returns `ScreenGuardResult` with Win32 error code on failure |

---

## Installation

```yaml
dependencies:
  windows_screen_guard: ^0.1.0
```

```sh
flutter pub get
```

---

## Quick start

```dart
import 'package:windows_screen_guard/windows_screen_guard.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Block all screen capture before the app renders.
  WindowsScreenGuard.protect();

  // Optionally also block the PrintScreen key.
  WindowsScreenGuard.blockPrintScreen();

  runApp(const MyApp());
}
```

---

## Usage

### Enable protection

```dart
final result = WindowsScreenGuard.protect();

if (result.success) {
  debugPrint('Screen capture is now blocked.');
} else {
  debugPrint('Failed — Win32 error code: ${result.errorCode}');
}
```

### Disable protection

```dart
WindowsScreenGuard.unprotect();
```

### Block the PrintScreen key

```dart
// Install a low-level keyboard hook that swallows VK_SNAPSHOT.
final hooked = WindowsScreenGuard.blockPrintScreen();

// Check state at any time.
print(WindowsScreenGuard.isPrintScreenBlocked); // true

// Remove the hook when no longer needed.
WindowsScreenGuard.unblockPrintScreen();
```

### Toggle protection per screen

Protect only sensitive screens rather than the entire app:

```dart
class SecureScreen extends StatefulWidget { ... }

class _SecureScreenState extends State<SecureScreen> {
  @override
  void initState() {
    super.initState();
    WindowsScreenGuard.protect();
  }

  @override
  void dispose() {
    WindowsScreenGuard.unprotect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SensitiveContentWidget();
}
```

---

## What gets blocked

| Capture method | `protect()` | `blockPrintScreen()` |
|---|:---:|:---:|
| PrintScreen key | ![yes](https://img.shields.io/badge/-Yes-22863a?style=flat-square) | ![yes](https://img.shields.io/badge/-Yes-22863a?style=flat-square) |
| `Win + PrintScreen` | ![yes](https://img.shields.io/badge/-Yes-22863a?style=flat-square) | ![no](https://img.shields.io/badge/-No-c0392b?style=flat-square) |
| `Win + Shift + S` (Snipping Tool) | ![yes](https://img.shields.io/badge/-Yes-22863a?style=flat-square) | ![no](https://img.shields.io/badge/-No-c0392b?style=flat-square) |
| `Win + G` (Xbox Game Bar) | ![yes](https://img.shields.io/badge/-Yes-22863a?style=flat-square) | ![no](https://img.shields.io/badge/-No-c0392b?style=flat-square) |
| OBS / third-party recorders | ![yes](https://img.shields.io/badge/-Yes-22863a?style=flat-square) | ![no](https://img.shields.io/badge/-No-c0392b?style=flat-square) |
| Remote desktop capture | ![yes](https://img.shields.io/badge/-Yes-22863a?style=flat-square) | ![no](https://img.shields.io/badge/-No-c0392b?style=flat-square) |

> `protect()` is the primary defence. `blockPrintScreen()` is an additional layer for the physical key only.

---

## API reference

### `WindowsScreenGuard`

| Method / Property | Returns | Description |
|---|---|---|
| `protect()` | `ScreenGuardResult` | Applies `WDA_MONITOR` to all windows owned by this process |
| `unprotect()` | `ScreenGuardResult` | Removes display affinity, restoring normal capture behaviour |
| `blockPrintScreen()` | `bool` | Installs a `WH_KEYBOARD_LL` hook to swallow `VK_SNAPSHOT` |
| `unblockPrintScreen()` | `void` | Removes the keyboard hook |
| `isPrintScreenBlocked` | `bool` | Whether the keyboard hook is currently active |

### `ScreenGuardResult`

| Property | Type | Description |
|---|---|---|
| `success` | `bool` | `true` if the Win32 call succeeded |
| `errorCode` | `int?` | Win32 error code when `success` is `false`, otherwise `null` |

---

## Caveats

**PrintScreen key hook limitations**

`blockPrintScreen()` blocks the physical PrintScreen key via `SetWindowsHookEx`. It does not block `Win + Shift + S`, `Win + G`, or capture tools that bypass keyboard hooks. Always combine it with `protect()`.

**Remote desktop**

`WDA_MONITOR` applies to the local display pipeline. Behaviour in RDP sessions may vary depending on the Windows version and RDP client in use.

---

## Requirements

[![flutter](https://img.shields.io/badge/Flutter-%3E%3D3.24.0-02569B?style=flat-square&logo=flutter&logoColor=white)](https://flutter.dev)
[![dart](https://img.shields.io/badge/Dart-%3E%3D3.5.0-0175C2?style=flat-square&logo=dart&logoColor=white)](https://dart.dev)
[![windows](https://img.shields.io/badge/Windows-Only-0078D4?style=flat-square&logo=windows&logoColor=white)](https://flutter.dev/desktop)

| | |
|---|---|
| Flutter | `>=3.24.0` |
| Dart | `>=3.5.0` |
| Platform | Windows (no-op on all other platforms) |
| Dependencies | `ffi ^2.1.0`, `win32 ^5.2.0` |

---

## Use cases

[![banking](https://img.shields.io/badge/-Banking_&_Fintech-F0A500?style=flat-square&logo=stripe&logoColor=white)](https://pub.dev/packages/windows_screen_guard)
[![healthcare](https://img.shields.io/badge/-Healthcare-c0392b?style=flat-square&logo=red-cross&logoColor=white)](https://pub.dev/packages/windows_screen_guard)
[![enterprise](https://img.shields.io/badge/-Enterprise_ERP-0078D4?style=flat-square&logo=microsoft&logoColor=white)](https://pub.dev/packages/windows_screen_guard)
[![drm](https://img.shields.io/badge/-DRM_&_Media-6A0DAD?style=flat-square&logo=netflix&logoColor=white)](https://pub.dev/packages/windows_screen_guard)

- **Banking & fintech** — protect account balances and transaction history
- **Healthcare** — safeguard patient records displayed on screen
- **Enterprise ERP** — prevent employees from capturing sensitive business data
- **Document viewers** — protect confidential PDFs and contracts
- **DRM / media** — prevent capture of licensed content
- **Any app handling private data** — add a security layer with two lines of code

---

## License

[![MIT](https://img.shields.io/badge/license-MIT-blue.svg?style=flat-square&logo=open-source-initiative&logoColor=white)](https://github.com/AmrSabbagh35/windows_screen_guard/blob/main/LICENSE)

MIT © [Amr Sabbagh](https://github.com/AmrSabbagh35)
