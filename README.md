# windows_screen_guard

[![pub version](https://img.shields.io/pub/v/windows_screen_guard.svg)](https://pub.dev/packages/windows_screen_guard)
[![license](https://img.shields.io/badge/license-MIT-blue.svg)](https://github.com/AmrSabbagh35/windows-screen-guard/blob/main/LICENSE)
[![platform](https://img.shields.io/badge/platform-Windows-blue.svg)](https://pub.dev/packages/windows_screen_guard)

Prevent screen capture and recording on Flutter Windows apps using the Windows display affinity API — the same method used by Netflix, banking apps, and enterprise software.

---

## How it works

`SetWindowDisplayAffinity` with the `WDA_MONITOR` flag tells Windows to exclude your app's window from any capture pipeline. The result: every capture tool (PrintScreen, OBS, Xbox Game Bar, third-party recorders) sees your window as **solid black**, while the user's own display is completely unaffected.

This is a kernel-level Windows API call — it cannot be bypassed by capture software running in user space.

---

## Features

- **Capture blocking** — makes your window appear black in screenshots and recordings
- **PrintScreen key hook** — swallows `VK_SNAPSHOT` at the OS level (best-effort, see caveats)
- **Zero-config** — two lines of code, no platform channels, no native plugins to set up
- **Non-Windows safe** — all methods are no-ops on macOS/Linux/Android/iOS so you can call them unconditionally
- **Result reporting** — returns Win32 error codes on failure so you know exactly what went wrong

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

## Usage

### Protect on startup

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
  debugPrint('Protection failed — Win32 error: ${result.errorCode}');
}
```

### Block the PrintScreen key

```dart
// Install keyboard hook
WindowsScreenGuard.blockPrintScreen();

// Remove it when no longer needed
WindowsScreenGuard.unblockPrintScreen();

// Query state
print(WindowsScreenGuard.isPrintScreenBlocked); // true / false
```

### Remove protection

```dart
WindowsScreenGuard.unprotect();
```

---

## API reference

### WindowsScreenGuard

| Method | Returns | Description |
|---|---|---|
| `protect()` | `ScreenGuardResult` | Enables WDA_MONITOR on all process windows |
| `unprotect()` | `ScreenGuardResult` | Removes display affinity protection |
| `blockPrintScreen()` | `bool` | Installs low-level keyboard hook for `VK_SNAPSHOT` |
| `unblockPrintScreen()` | `void` | Removes the keyboard hook |
| `isPrintScreenBlocked` | `bool` | Whether the keyboard hook is active |

### ScreenGuardResult

| Property | Type | Description |
|---|---|---|
| `success` | `bool` | Whether the operation succeeded |
| `errorCode` | `int?` | Win32 error code if `success` is false |

---

## Caveats

### PrintScreen key hook limitations

`blockPrintScreen()` blocks the physical PrintScreen key via `SetWindowsHookEx`. It does **not** block:

- `Win + Shift + S` (Snipping Tool shortcut)
- `Win + G` (Xbox Game Bar)
- Third-party capture tools that don't use keyboard hooks

**Use `protect()` for comprehensive capture prevention.** The PrintScreen hook is an additional layer, not a replacement.

### Administrator rights

`protect()` does not require administrator rights. The `SetWindowDisplayAffinity` API works for any process on its own windows.

---

## Requirements

- Flutter `>=3.24.0`
- Dart `>=3.5.0`
- Windows only (no-op on all other platforms)
- Dependencies: `ffi`, `win32`

---

## License

MIT © [Amr Sabbagh](https://github.com/AmrSabbagh35)
