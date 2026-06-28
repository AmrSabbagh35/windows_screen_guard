# windows_screen_guard

[![pub version](https://img.shields.io/pub/v/windows_screen_guard.svg)](https://pub.dev/packages/windows_screen_guard)
[![license](https://img.shields.io/badge/license-MIT-blue.svg)](https://github.com/AmrSabbagh35/windows_screen_guard/blob/main/LICENSE)
[![platform](https://img.shields.io/badge/platform-Windows-blue.svg)](https://pub.dev/packages/windows_screen_guard)

Prevent screen capture and recording on Flutter Windows apps using the Windows display affinity API — the same method used by Netflix, banking apps, and enterprise software.

When protection is active, every capture tool — PrintScreen, OBS, Xbox Game Bar, Snipping Tool, third-party recorders — sees your app's window as **solid black**. The user's own display is completely unaffected.

---

## How it works

Windows exposes a kernel-level API called `SetWindowDisplayAffinity`. When called with the `WDA_MONITOR` flag, it instructs the GPU compositor to exclude the window from any capture pipeline. Because this happens at the driver level, no user-space screen capture software can bypass it — the same guarantee that lets Netflix play DRM content on Windows desktops.

`windows_screen_guard` wraps this API via Dart FFI using the `win32` package — no platform channels, no native plugins, no C++ to write.

---

## Features

- **Capture blocking** — makes your window appear black in all screenshots and screen recordings
- **PrintScreen key hook** — swallows `VK_SNAPSHOT` at the OS level via a low-level keyboard hook
- **Zero-config** — two lines of code to protect your entire app
- **No admin rights needed** — `SetWindowDisplayAffinity` works for any process on its own windows
- **Cross-platform safe** — all methods are silent no-ops on macOS, Linux, Android, and iOS
- **Result reporting** — returns `ScreenGuardResult` with the Win32 error code on failure

---

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  windows_screen_guard: ^0.1.0
```

Then run:

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
  print('Screen capture is now blocked.');
} else {
  print('Failed — Win32 error code: ${result.errorCode}');
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
print(hooked); // true if the hook was installed successfully

// Check state at any time.
print(WindowsScreenGuard.isPrintScreenBlocked); // true

// Remove the hook when no longer needed.
WindowsScreenGuard.unblockPrintScreen();
```

### Toggle protection at runtime

```dart
// Useful for "secure view" flows — protect only certain screens.
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

## What gets blocked

| Capture method | Blocked by `protect()` | Blocked by `blockPrintScreen()` |
|---|---|---|
| PrintScreen key | ✅ | ✅ |
| `Win + PrintScreen` | ✅ | ❌ |
| `Win + Shift + S` (Snipping Tool) | ✅ | ❌ |
| `Win + G` (Xbox Game Bar) | ✅ | ❌ |
| OBS / third-party recorders | ✅ | ❌ |
| Remote desktop capture | ✅ | ❌ |

**`protect()` is the primary defence.** `blockPrintScreen()` is an additional layer for the physical key only.

---

## Caveats

- **`blockPrintScreen()` is best-effort.** It blocks the physical key via a keyboard hook. It does not block `Win + Shift + S`, `Win + G`, or any capture tool that doesn't route through the keyboard hook chain. Always combine it with `protect()`.
- **`protect()` requires no administrator rights** — it only operates on windows owned by the current process.
- **Remote desktop sessions** — `WDA_MONITOR` applies to the local display pipeline. Behaviour in RDP sessions may vary depending on the Windows version and RDP client.

---

## Requirements

| | |
|---|---|
| Flutter | `>=3.24.0` |
| Dart | `>=3.5.0` |
| Platform | Windows only (no-op on all others) |
| Dependencies | `ffi ^2.1.0`, `win32 ^5.2.0` |

---

## Use cases

- **Enterprise ERP / document management** — prevent employees from leaking sensitive data via screenshots
- **Banking & fintech apps** — protect account details and transaction history
- **Healthcare apps** — safeguard patient records displayed on screen
- **DRM / content protection** — prevent capture of licensed media
- **Secure PDF / document viewers** — protect confidential documents from screen grabs

---

## License

MIT © [Amr Sabbagh](https://github.com/AmrSabbagh35)
