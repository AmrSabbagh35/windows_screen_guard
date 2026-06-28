import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

import 'screen_guard_status.dart';

// WDA_MONITOR makes the window appear black in any capture tool.
const int _wdaMonitor = 0x00000001;
const int _wdaNone = 0x00000000;

typedef _SetAffinityNative = Uint32 Function(IntPtr hWnd, Uint32 dwAffinity);
typedef _SetAffinityDart = int Function(int hWnd, int dwAffinity);

typedef _EnumWindowsProc = Int32 Function(IntPtr hWnd, IntPtr lParam);
typedef _LowLevelKeyboardProc = IntPtr Function(
    Int32 nCode, IntPtr wParam, IntPtr lParam);

final _user32 = DynamicLibrary.open('user32.dll');

final _setWindowDisplayAffinity = _user32.lookupFunction<
    _SetAffinityNative, _SetAffinityDart>('SetWindowDisplayAffinity');

final _enumWindows = _user32.lookupFunction<
    Int32 Function(
        Pointer<NativeFunction<_EnumWindowsProc>> lpEnumFunc, IntPtr lParam),
    int Function(Pointer<NativeFunction<_EnumWindowsProc>> lpEnumFunc,
        int lParam)>('EnumWindows');

// Keyboard hook state — module-level so the Pointer stays alive.
final _keyboardProcPointer =
    Pointer.fromFunction<_LowLevelKeyboardProc>(_lowLevelKeyboardProc, 0);
int _keyboardHookId = 0;

/// Prevents screen capture and recording on Flutter Windows apps.
///
/// All methods are no-ops on non-Windows platforms so you can call them
/// unconditionally without platform guards.
abstract final class WindowsScreenGuard {
  /// Applies [SetWindowDisplayAffinity] (WDA_MONITOR) to every window owned
  /// by this process.
  ///
  /// After this call, any screen capture tool (PrintScreen, OBS, Xbox Game
  /// Bar, etc.) will see the window as solid black. The user's own display
  /// is unaffected.
  ///
  /// Returns a [ScreenGuardResult] indicating success or the Win32 error code.
  static ScreenGuardResult protect() {
    if (!Platform.isWindows) return const ScreenGuardResult(success: true);
    return _applyAffinity(_wdaMonitor);
  }

  /// Removes display affinity protection, restoring normal capture behaviour.
  static ScreenGuardResult unprotect() {
    if (!Platform.isWindows) return const ScreenGuardResult(success: true);
    return _applyAffinity(_wdaNone);
  }

  /// Installs a low-level keyboard hook that swallows the PrintScreen key
  /// (`VK_SNAPSHOT`).
  ///
  /// **Limitations:** this blocks the physical key only. It does NOT block
  /// `Win + Shift + S`, `Win + G` (Xbox Game Bar), or third-party capture
  /// tools that bypass keyboard hooks. Use [protect] for comprehensive
  /// capture prevention; treat this as an additional layer.
  ///
  /// Returns `true` if the hook was installed successfully.
  static bool blockPrintScreen() {
    if (!Platform.isWindows) return true;
    if (_keyboardHookId != 0) return true;
    _keyboardHookId = SetWindowsHookEx(
        WH_KEYBOARD_LL, _keyboardProcPointer, GetModuleHandle(nullptr), 0);
    return _keyboardHookId != 0;
  }

  /// Removes the keyboard hook installed by [blockPrintScreen].
  static void unblockPrintScreen() {
    if (!Platform.isWindows) return;
    if (_keyboardHookId != 0) {
      UnhookWindowsHookEx(_keyboardHookId);
      _keyboardHookId = 0;
    }
  }

  /// Whether the PrintScreen keyboard hook is currently active.
  static bool get isPrintScreenBlocked => _keyboardHookId != 0;

  // ── internals ──────────────────────────────────────────────────────────────

  static ScreenGuardResult _applyAffinity(int affinity) {
    var lastError = 0;

    int enumProc(int hWnd, int lParam) {
      final pidPtr = calloc<Uint32>();
      try {
        GetWindowThreadProcessId(hWnd, pidPtr);
        if (pidPtr.value == GetCurrentProcessId()) {
          final result = _setWindowDisplayAffinity(hWnd, affinity);
          if (result == 0) lastError = GetLastError();
        }
      } finally {
        free(pidPtr);
      }
      return TRUE;
    }

    final procPtr =
        Pointer.fromFunction<_EnumWindowsProc>(enumProc, 0);
    _enumWindows(procPtr, 0);

    return lastError == 0
        ? const ScreenGuardResult(success: true)
        : ScreenGuardResult(success: false, errorCode: lastError);
  }
}

// Top-level so Dart FFI can take a stable pointer to it.
int _lowLevelKeyboardProc(int nCode, int wParam, int lParam) {
  if (nCode >= 0 && (wParam == WM_KEYDOWN || wParam == WM_SYSKEYDOWN)) {
    final kb = Pointer<KBDLLHOOKSTRUCT>.fromAddress(lParam);
    if (kb.ref.vkCode == VK_SNAPSHOT) {
      return 1; // Swallow the key — do not pass to next hook.
    }
  }
  return CallNextHookEx(_keyboardHookId, nCode, wParam, lParam);
}
