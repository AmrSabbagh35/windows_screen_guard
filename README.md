# windows_screen_guard

[![pub version](https://img.shields.io/pub/v/windows_screen_guard.svg)](https://pub.dev/packages/windows_screen_guard)
[![license](https://img.shields.io/badge/license-MIT-blue.svg)](https://github.com/AmrSabbagh35/windows_screen_guard/blob/main/LICENSE)
[![platform](https://img.shields.io/badge/platform-Windows-blue.svg)](https://pub.dev/packages/windows_screen_guard)

Prevent screen capture and recording on Flutter Windows apps using the Windows display affinity API — the same method used by Netflix, banking apps, and enterprise software.

<p align="center">
  <img src="https://raw.githubusercontent.com/AmrSabbagh35/windows_screen_guard/main/assets/capture_demo.gif" width="560" alt="Capture blocked demo" />
</p>

---

## 🛡️ How it works

Windows exposes a kernel-level API called `SetWindowDisplayAffinity`. When called with the `WDA_MONITOR` flag, it instructs the GPU compositor to exclude your window from any capture pipeline. The result: every capture tool sees your window as **solid black**, while the user's own display is completely unaffected.

Because this happens at the driver level, no user-space screen capture software can bypass it — the same guarantee that lets Netflix play DRM content on Windows desktops.

`windows_screen_guard` wraps this API via Dart FFI using the `win32` package. No platform channels, no C++ to write, no native plugin setup.

<p align="center">
  <img src="https://raw.githubusercontent.com/AmrSabbagh35/windows_screen_guard/main/assets/shield_demo.gif" width="220" alt="Shield activation" />
</p>

---

## ✨ Features

| | |
|---|---|
| 🖥️ **Capture blocking** | Makes your window appear black in all screenshots and screen recordings |
| ⌨️ **PrintScreen key hook** | Swallows `VK_SNAPSHOT` at the OS level via a low-level keyboard hook |
| ⚡ **Zero-config** | Two lines of code to protect your entire app |
| 🔓 **No admin rights** | `SetWindowDisplayAffinity` works without elevated privileges |
| 🌐 **Cross-platform safe** | All methods are silent no-ops on macOS, Linux, Android, and iOS |
| 📋 **Result reporting** | Returns `ScreenGuardResult` with the Win32 error code on failure |

---

## 📦 Installation

```yaml
dependencies:
  windows_screen_guard: ^0.1.0
```

```sh
flutter pub get
```

---

## 🚀 Quick start

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

## 📖 Usage

### Enable protection

```dart
final result = WindowsScreenGuard.protect();

if (result.success) {
  print('✅ Screen capture is now blocked.');
} else {
  print('❌ Failed — Win32 error code: ${result.errorCode}');
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

### Toggle protection per screen

Protect only sensitive screens, not the entire app:

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

## 📊 What gets blocked

| Capture method | `protect()` | `blockPrintScreen()` |
|---|:---:|:---:|
| PrintScreen key | ✅ | ✅ |
| `Win + PrintScreen` | ✅ | ❌ |
| `Win + Shift + S` (Snipping Tool) | ✅ | ❌ |
| `Win + G` (Xbox Game Bar) | ✅ | ❌ |
| OBS / third-party recorders | ✅ | ❌ |
| Remote desktop capture | ✅ | ❌ |

> **`protect()` is the primary defence.** `blockPrintScreen()` is an additional layer for the physical key only.

---

## 🔌 API reference

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

## ⚠️ Caveats

### PrintScreen key hook limitations

`blockPrintScreen()` blocks the physical PrintScreen key via `SetWindowsHookEx`. It does **not** block `Win + Shift + S`, `Win + G`, or capture tools that bypass keyboard hooks. Always combine it with `protect()`.

### Remote desktop

`WDA_MONITOR` applies to the local display pipeline. Behaviour in RDP sessions may vary depending on the Windows version and RDP client in use.

---

## 🏗️ Requirements

| | |
|---|---|
| Flutter | `>=3.24.0` |
| Dart | `>=3.5.0` |
| Platform | Windows (no-op on all other platforms) |
| Dependencies | `ffi ^2.1.0`, `win32 ^5.2.0` |

---

## 💼 Use cases

- 🏦 **Banking & fintech** — protect account balances and transaction history
- 🏥 **Healthcare** — safeguard patient records displayed on screen
- 🏢 **Enterprise ERP** — prevent employees from capturing sensitive business data
- 📄 **Document viewers** — protect confidential PDFs and contracts
- 🎬 **DRM / media** — prevent capture of licensed content
- 🔐 **Any app handling private data** — add a security layer with two lines of code

---

## 📄 License

MIT © [Amr Sabbagh](https://github.com/AmrSabbagh35)
