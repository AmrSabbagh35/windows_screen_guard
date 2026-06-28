import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

import 'screen_guard_status.dart';

const int _wdaMonitor = 0x00000001;
const int _wdaNone = 0x00000000;

// FFI typedefs — only referenced on Windows, never loaded on other platforms.
typedef _SetAffinityNative = Uint32 Function(IntPtr hWnd, Uint32 dwAffinity);
typedef _SetAffinityDart = int Function(int hWnd, int dwAffinity);
typedef _EnumWindowsProc = WNDENUMPROC;
typedef _LowLevelKeyboardProc = IntPtr Function(
    Int32 nCode, IntPtr wParam, IntPtr lParam);

// Initialised on first use — user32.dll is never opened on non-Windows.
DynamicLibrary? __user32;
DynamicLibrary get _user32 => __user32 ??= DynamicLibrary.open('user32.dll');

_SetAffinityDart? __setWindowDisplayAffinity;
_SetAffinityDart get _setWindowDisplayAffinity =>
    __setWindowDisplayAffinity ??= _user32
        .lookupFunction<_SetAffinityNative, _SetAffinityDart>(
            'SetWindowDisplayAffinity');

// Keyboard hook — module-level so the Pointer and hook ID stay alive for the
// lifetime of the process. Dart FFI requires the callback to be a top-level
// or static function (not a closure) to produce a stable native pointer.
final _keyboardProcPointer =
    Pointer.fromFunction<_LowLevelKeyboardProc>(_lowLevelKeyboardProc, 0);
int _keyboardHookId = 0;

// Top-level callback — required by Dart FFI (closures are not allowed).
// Intercepts VK_SNAPSHOT and swallows it; passes everything else through.
int _lowLevelKeyboardProc(int nCode, int wParam, int lParam) {
  if (nCode >= 0 && (wParam == WM_KEYDOWN || wParam == WM_SYSKEYDOWN)) {
    final kb = Pointer<KBDLLHOOKSTRUCT>.fromAddress(lParam);
    if (kb.ref.vkCode == VK_SNAPSHOT) {
      return 1; // consumed — do not pass to next hook
    }
  }
  return CallNextHookEx(_keyboardHookId, nCode, wParam, lParam);
}

// Top-level EnumWindows callback — must be static/top-level for FFI.
// Applies the given affinity to every window owned by this process.
// Uses a global to pass the affinity value since closures are forbidden.
int _currentAffinity = _wdaNone;
int _lastAffinityError = 0;

int _enumWindowsCallback(int hWnd, int lParam) {
  final pidPtr = calloc<Uint32>();
  try {
    GetWindowThreadProcessId(hWnd, pidPtr);
    if (pidPtr.value == GetCurrentProcessId()) {
      final result = _setWindowDisplayAffinity(hWnd, _currentAffinity);
      if (result == 0) _lastAffinityError = GetLastError();
    }
  } finally {
    free(pidPtr);
  }
  return TRUE;
}

final _enumWindowsCallbackPtr =
    Pointer.fromFunction<_EnumWindowsProc>(_enumWindowsCallback, 0);

/// Prevents screen capture and recording on Flutter Windows apps.
///
/// All methods are no-ops on non-Windows platforms — call them unconditionally
/// without platform guards.
abstract final class WindowsScreenGuard {
  /// Applies `SetWindowDisplayAffinity` (`WDA_MONITOR`) to every window owned
  /// by this process.
  ///
  /// After this call, any screen capture tool (PrintScreen, OBS, Xbox Game
  /// Bar, etc.) sees the window as solid black. The user's own display is
  /// unaffected.
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
  /// This blocks the physical key only. It does not block `Win + Shift + S`,
  /// `Win + G`, or capture tools that bypass the keyboard hook chain.
  /// Use [protect] for comprehensive capture prevention.
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
  ///
  /// Always `false` on non-Windows platforms.
  static bool get isPrintScreenBlocked =>
      Platform.isWindows && _keyboardHookId != 0;

  // ── internals ──────────────────────────────────────────────────────────────

  static ScreenGuardResult _applyAffinity(int affinity) {
    _currentAffinity = affinity;
    _lastAffinityError = 0;
    EnumWindows(_enumWindowsCallbackPtr, 0);
    return _lastAffinityError == 0
        ? const ScreenGuardResult(success: true)
        : ScreenGuardResult(success: false, errorCode: _lastAffinityError);
  }
}
