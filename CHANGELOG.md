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
