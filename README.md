<h1 align="center">windows_screen_guard</h1>

<p align="center">
  Screen capture prevention for Flutter Windows applications via the Win32 display affinity API.
</p>

<p align="center">
  <a href="https://pub.dev/packages/windows_screen_guard">
    <img src="https://img.shields.io/pub/v/windows_screen_guard.svg?style=flat-square&label=pub&logo=dart&logoColor=white&color=0175C2" alt="pub version" />
  </a>
  <a href="https://pub.dev/packages/windows_screen_guard/score">
    <img src="https://img.shields.io/pub/points/windows_screen_guard?style=flat-square&logo=dart&logoColor=white&color=0175C2" alt="pub points" />
  </a>
  <a href="https://github.com/AmrSabbagh35/windows_screen_guard/blob/main/LICENSE">
    <img src="https://img.shields.io/badge/license-MIT-blue?style=flat-square" alt="MIT license" />
  </a>
  <a href="https://flutter.dev/desktop">
    <img src="https://img.shields.io/badge/platform-Windows-0078D4?style=flat-square&logo=windows&logoColor=white" alt="Windows" />
  </a>
  <a href="https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-setwindowdisplayaffinity">
    <img src="https://img.shields.io/badge/Win32-SetWindowDisplayAffinity-0078D4?style=flat-square&logo=microsoft&logoColor=white" alt="Win32 API" />
  </a>
</p>

---

---

## Overview

`windows_screen_guard` prevents screen capture and recording on Flutter Windows applications by wrapping the [`SetWindowDisplayAffinity`](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-setwindowdisplayaffinity) Win32 API via Dart FFI.

When the `WDA_MONITOR` flag is applied, the Windows GPU compositor excludes your application window from every capture pipeline — PrintScreen, OBS, Xbox Game Bar, Snipping Tool, and any third-party recorder. The user's own display is completely unaffected. Because this operates at the driver level, no user-space software can bypass it. This is the same mechanism used by Netflix, banking applications, and enterprise software on Windows.

No platform channels. No C++ to write. No native plugin setup required.

---

## Features

| | |
|---|---|
| **Capture blocking** | Applies `WDA_MONITOR` via `SetWindowDisplayAffinity` — window appears black in all capture tools |
| **PrintScreen key hook** | Installs a `WH_KEYBOARD_LL` hook to intercept `VK_SNAPSHOT` at the OS level |
| **No admin rights required** | `SetWindowDisplayAffinity` works for any process on its own windows |
| **Non-Windows safe** | All methods are silent no-ops on macOS, Linux, Android, and iOS |
| **Error reporting** | Returns `ScreenGuardResult` with the Win32 error code on failure |
| **Minimal footprint** | Two dependencies — `ffi` and `win32` |

---

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  windows_screen_guard: ^0.1.0
```

```sh
flutter pub get
```

---

## Usage

### Protect on startup

The recommended approach is to enable protection before the widget tree renders:

```dart
import 'package:windows_screen_guard/windows_screen_guard.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  WindowsScreenGuard.protect();
  runApp(const MyApp());
}
```

### Check the result

```dart
final result = WindowsScreenGuard.protect();

if (!result.success) {
  debugPrint('Protection failed. Win32 error: ${result.errorCode}');
}
```

### Remove protection

```dart
WindowsScreenGuard.unprotect();
```

### Block the PrintScreen key

```dart
WindowsScreenGuard.blockPrintScreen();

// Query state
WindowsScreenGuard.isPrintScreenBlocked; // true

// Remove when no longer needed
WindowsScreenGuard.unblockPrintScreen();
```

### Protect specific screens only

Apply and remove protection scoped to individual routes:

```dart
class SecureScreen extends StatefulWidget {
  const SecureScreen({super.key});
  @override
  State<SecureScreen> createState() => _SecureScreenState();
}

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
  Widget build(BuildContext context) {
    return const SensitiveContentWidget();
  }
}
```

---

## Coverage

The table below shows what each method blocks:

| Capture method | `protect()` | `blockPrintScreen()` |
|---|:---:|:---:|
| PrintScreen key | ![yes](https://img.shields.io/badge/-%E2%9C%93-1a7f37?style=flat-square) | ![yes](https://img.shields.io/badge/-%E2%9C%93-1a7f37?style=flat-square) |
| Win + PrintScreen | ![yes](https://img.shields.io/badge/-%E2%9C%93-1a7f37?style=flat-square) | ![no](https://img.shields.io/badge/-%E2%9C%95-b91c1c?style=flat-square) |
| Win + Shift + S (Snipping Tool) | ![yes](https://img.shields.io/badge/-%E2%9C%93-1a7f37?style=flat-square) | ![no](https://img.shields.io/badge/-%E2%9C%95-b91c1c?style=flat-square) |
| Win + G (Xbox Game Bar) | ![yes](https://img.shields.io/badge/-%E2%9C%93-1a7f37?style=flat-square) | ![no](https://img.shields.io/badge/-%E2%9C%95-b91c1c?style=flat-square) |
| OBS and third-party recorders | ![yes](https://img.shields.io/badge/-%E2%9C%93-1a7f37?style=flat-square) | ![no](https://img.shields.io/badge/-%E2%9C%95-b91c1c?style=flat-square) |
| Remote desktop capture | ![yes](https://img.shields.io/badge/-%E2%9C%93-1a7f37?style=flat-square) | ![no](https://img.shields.io/badge/-%E2%9C%95-b91c1c?style=flat-square) |

`protect()` is the primary and comprehensive defence. `blockPrintScreen()` is a supplementary layer that targets the physical key only and should always be used alongside `protect()`.

---

## API Reference

### `WindowsScreenGuard`

```dart
abstract final class WindowsScreenGuard
```

| Member | Type | Description |
|---|---|---|
| `protect()` | `ScreenGuardResult` | Applies `WDA_MONITOR` to all windows owned by this process |
| `unprotect()` | `ScreenGuardResult` | Removes display affinity and restores normal capture behaviour |
| `blockPrintScreen()` | `bool` | Installs a low-level keyboard hook to intercept `VK_SNAPSHOT` |
| `unblockPrintScreen()` | `void` | Removes the keyboard hook |
| `isPrintScreenBlocked` | `bool` | Returns `true` if the keyboard hook is currently installed |

### `ScreenGuardResult`

```dart
class ScreenGuardResult
```

| Property | Type | Description |
|---|---|---|
| `success` | `bool` | `true` if the Win32 operation succeeded |
| `errorCode` | `int?` | The Win32 error code if `success` is `false`; `null` otherwise |

---

## Limitations

**PrintScreen key hook**
`blockPrintScreen()` intercepts the physical PrintScreen key (`VK_SNAPSHOT`) via `SetWindowsHookEx`. It does not intercept `Win + Shift + S`, `Win + G`, or capture tools that operate independently of the keyboard hook chain. Use `protect()` for comprehensive coverage.

**Remote Desktop Protocol (RDP)**
`WDA_MONITOR` operates on the local display compositor. Behaviour within RDP sessions may differ across Windows versions and RDP client implementations.

**Administrator privileges**
`protect()` does not require administrator rights. It operates exclusively on windows owned by the calling process.

---

## Requirements

| | |
|---|---|
| Dart SDK | `>=3.5.0` |
| Flutter | `>=3.24.0` |
| Platform | Windows 10 / 11 |
| Dependencies | [`ffi ^2.1.0`](https://pub.dev/packages/ffi), [`win32 ^5.2.0`](https://pub.dev/packages/win32) |

All methods are no-ops on non-Windows platforms. No conditional imports or platform guards are needed in application code.

---

## Use Cases

- **Banking and fintech** — prevent capture of account balances, statements, and transaction history
- **Healthcare** — protect patient records and clinical data rendered on screen
- **Enterprise ERP and document management** — prevent unauthorised capture of confidential business data
- **Legal and compliance** — safeguard contracts, case files, and privileged communications
- **DRM and licensed media** — prevent screen recording of protected content
- **Any application handling sensitive data** — add a meaningful security layer with minimal integration effort

---

## Contributing

Contributions, issues, and feature requests are welcome. Please open an issue on [GitHub](https://github.com/AmrSabbagh35/windows_screen_guard/issues) before submitting a pull request.

---

## License

Distributed under the MIT License. See [`LICENSE`](https://github.com/AmrSabbagh35/windows_screen_guard/blob/main/LICENSE) for details.

Copyright © 2026 [Amr Sabbagh](https://github.com/AmrSabbagh35)
