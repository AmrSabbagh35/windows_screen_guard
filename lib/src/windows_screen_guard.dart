import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';

import 'screen_guard_status.dart';

const int _wdaMonitor = 0x00000001;
const int _wdaNone = 0x00000000;
const int _whKeyboardLl = 13;
const int _wmKeydown = 0x0100;
const int _wmSyskeydown = 0x0104;
const int _vkSnapshot = 0x2C;
const int _true = 1;

// ── FFI typedefs ─────────────────────────────────────────────────────────────

typedef _SetAffinityNative = Uint32 Function(IntPtr hWnd, Uint32 dwAffinity);
typedef _SetAffinityDart = int Function(int hWnd, int dwAffinity);

typedef _EnumWindowsNative = Int32 Function(
    Pointer<NativeFunction<_EnumWindowsProc>> lpEnumFunc, IntPtr lParam);
typedef _EnumWindowsDart = int Function(
    Pointer<NativeFunction<_EnumWindowsProc>> lpEnumFunc, int lParam);
typedef _EnumWindowsProc = Int32 Function(IntPtr hWnd, IntPtr lParam);

typedef _GetWindowThreadProcessIdNative = Uint32 Function(
    IntPtr hWnd, Pointer<Uint32> lpdwProcessId);
typedef _GetWindowThreadProcessIdDart = int Function(
    int hWnd, Pointer<Uint32> lpdwProcessId);

typedef _GetCurrentProcessIdNative = Uint32 Function();
typedef _GetCurrentProcessIdDart = int Function();

typedef _GetLastErrorNative = Uint32 Function();
typedef _GetLastErrorDart = int Function();

typedef _SetWindowsHookExNative = IntPtr Function(
    Int32 idHook,
    Pointer<NativeFunction<_LowLevelKeyboardProc>> lpfn,
    IntPtr hmod,
    Uint32 dwThreadId);
typedef _SetWindowsHookExDart = int Function(
    int idHook,
    Pointer<NativeFunction<_LowLevelKeyboardProc>> lpfn,
    int hmod,
    int dwThreadId);

typedef _UnhookWindowsHookExNative = Int32 Function(IntPtr hhk);
typedef _UnhookWindowsHookExDart = int Function(int hhk);

typedef _CallNextHookExNative = IntPtr Function(
    IntPtr hhk, Int32 nCode, IntPtr wParam, IntPtr lParam);
typedef _CallNextHookExDart = int Function(
    int hhk, int nCode, int wParam, int lParam);

typedef _GetModuleHandleNative = IntPtr Function(Pointer<Utf16> lpModuleName);
typedef _GetModuleHandleDart = int Function(Pointer<Utf16> lpModuleName);

typedef _LowLevelKeyboardProc = IntPtr Function(
    Int32 nCode, IntPtr wParam, IntPtr lParam);

// ── KBDLLHOOKSTRUCT layout ────────────────────────────────────────────────────

final class _KbdllHookStruct extends Struct {
  @Uint32()
  external int vkCode;
  @Uint32()
  external int scanCode;
  @Uint32()
  external int flags;
  @Uint32()
  external int time;
  @IntPtr()
  external int dwExtraInfo;
}

// ── Lazy-initialised bindings (never touch user32.dll on non-Windows) ─────────

DynamicLibrary? __user32;
DynamicLibrary get _user32 => __user32 ??= DynamicLibrary.open('user32.dll');

_SetAffinityDart? __setWindowDisplayAffinity;
_SetAffinityDart get _setWindowDisplayAffinity =>
    __setWindowDisplayAffinity ??= _user32
        .lookupFunction<_SetAffinityNative, _SetAffinityDart>(
            'SetWindowDisplayAffinity');

_EnumWindowsDart? __enumWindows;
_EnumWindowsDart get _enumWindows => __enumWindows ??=
    _user32.lookupFunction<_EnumWindowsNative, _EnumWindowsDart>('EnumWindows');

_GetWindowThreadProcessIdDart? __getWindowThreadProcessId;
_GetWindowThreadProcessIdDart get _getWindowThreadProcessId =>
    __getWindowThreadProcessId ??= _user32.lookupFunction<
        _GetWindowThreadProcessIdNative,
        _GetWindowThreadProcessIdDart>('GetWindowThreadProcessId');

_GetCurrentProcessIdDart? __getCurrentProcessId;
_GetCurrentProcessIdDart get _getCurrentProcessId =>
    __getCurrentProcessId ??= DynamicLibrary.open('kernel32.dll')
        .lookupFunction<_GetCurrentProcessIdNative, _GetCurrentProcessIdDart>(
            'GetCurrentProcessId');

_GetLastErrorDart? __getLastError;
_GetLastErrorDart get _getLastError =>
    __getLastError ??= DynamicLibrary.open('kernel32.dll')
        .lookupFunction<_GetLastErrorNative, _GetLastErrorDart>('GetLastError');

_SetWindowsHookExDart? __setWindowsHookEx;
_SetWindowsHookExDart get _setWindowsHookEx =>
    __setWindowsHookEx ??= _user32.lookupFunction<_SetWindowsHookExNative,
        _SetWindowsHookExDart>('SetWindowsHookExW');

_UnhookWindowsHookExDart? __unhookWindowsHookEx;
_UnhookWindowsHookExDart get _unhookWindowsHookEx =>
    __unhookWindowsHookEx ??= _user32.lookupFunction<
        _UnhookWindowsHookExNative,
        _UnhookWindowsHookExDart>('UnhookWindowsHookEx');

_CallNextHookExDart? __callNextHookEx;
_CallNextHookExDart get _callNextHookEx =>
    __callNextHookEx ??= _user32.lookupFunction<_CallNextHookExNative,
        _CallNextHookExDart>('CallNextHookEx');

_GetModuleHandleDart? __getModuleHandle;
_GetModuleHandleDart get _getModuleHandle =>
    __getModuleHandle ??= DynamicLibrary.open('kernel32.dll')
        .lookupFunction<_GetModuleHandleNative, _GetModuleHandleDart>(
            'GetModuleHandleW');

// ── Module-level state (globals required by FFI top-level callbacks) ──────────

final _keyboardProcPointer =
    Pointer.fromFunction<_LowLevelKeyboardProc>(_lowLevelKeyboardProc, 0);
int _keyboardHookId = 0;

int _currentAffinity = _wdaNone;
int _lastAffinityError = 0;

// ── Top-level FFI callbacks (closures are forbidden by Dart FFI) ──────────────

int _lowLevelKeyboardProc(int nCode, int wParam, int lParam) {
  if (nCode >= 0 && (wParam == _wmKeydown || wParam == _wmSyskeydown)) {
    final kb = Pointer<_KbdllHookStruct>.fromAddress(lParam);
    if (kb.ref.vkCode == _vkSnapshot) return 1;
  }
  return _callNextHookEx(_keyboardHookId, nCode, wParam, lParam);
}

int _enumWindowsCallback(int hWnd, int lParam) {
  final pidPtr = calloc<Uint32>();
  try {
    _getWindowThreadProcessId(hWnd, pidPtr);
    if (pidPtr.value == _getCurrentProcessId()) {
      final result = _setWindowDisplayAffinity(hWnd, _currentAffinity);
      if (result == 0) _lastAffinityError = _getLastError();
    }
  } finally {
    calloc.free(pidPtr);
  }
  return _true;
}

final _enumWindowsCallbackPtr =
    Pointer.fromFunction<_EnumWindowsProc>(_enumWindowsCallback, 0);

// ── Public API ────────────────────────────────────────────────────────────────

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
    _keyboardHookId = _setWindowsHookEx(
        _whKeyboardLl, _keyboardProcPointer, _getModuleHandle(nullptr), 0);
    return _keyboardHookId != 0;
  }

  /// Removes the keyboard hook installed by [blockPrintScreen].
  static void unblockPrintScreen() {
    if (!Platform.isWindows) return;
    if (_keyboardHookId != 0) {
      _unhookWindowsHookEx(_keyboardHookId);
      _keyboardHookId = 0;
    }
  }

  /// Whether the PrintScreen keyboard hook is currently active.
  ///
  /// Always `false` on non-Windows platforms.
  static bool get isPrintScreenBlocked =>
      Platform.isWindows && _keyboardHookId != 0;

  static ScreenGuardResult _applyAffinity(int affinity) {
    _currentAffinity = affinity;
    _lastAffinityError = 0;
    _enumWindows(_enumWindowsCallbackPtr, 0);
    return _lastAffinityError == 0
        ? const ScreenGuardResult(success: true)
        : ScreenGuardResult(success: false, errorCode: _lastAffinityError);
  }
}
