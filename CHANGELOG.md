## 0.1.2

* Drop `win32` dependency — rewritten with raw Dart FFI against `user32.dll` and `kernel32.dll` directly. Eliminates the `win32` version constraint that was blocking the pub points downgrade test.
* Replace `WNDENUMPROC` typedef alias with an explicit `Int32 Function(IntPtr, IntPtr)` native type — compatible with all `ffi` versions from `^2.1.0`.
* Resolves 0/20 pub points on "Compatible with dependency constraint lower bounds".

## 0.1.1

* Fix critical FFI bug: `EnumWindows` callback was a closure — moved to a top-level function as required by Dart FFI.
* Fix: `user32.dll` was opened at module init on all platforms — now lazy-initialised, never touched on non-Windows.
* Fix: `isPrintScreenBlocked` now correctly returns `false` on non-Windows platforms.
* Rewrite README with professional structure, standardized API docs, and coverage table.
* Remove placeholder GIFs.

## 0.1.0

* Initial release.
* `WindowsScreenGuard.protect()` — blocks all screen capture via `SetWindowDisplayAffinity` (WDA_MONITOR).
* `WindowsScreenGuard.unprotect()` — removes display affinity protection.
* `WindowsScreenGuard.blockPrintScreen()` — installs a low-level keyboard hook to swallow `VK_SNAPSHOT`.
* `WindowsScreenGuard.unblockPrintScreen()` — removes the keyboard hook.
* `WindowsScreenGuard.isPrintScreenBlocked` — query hook state.
* `ScreenGuardResult` — carries success flag and Win32 error code on failure.
* All methods are no-ops on non-Windows platforms.
