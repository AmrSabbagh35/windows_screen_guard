## 0.1.0

* Initial release.
* `WindowsScreenGuard.protect()` — blocks all screen capture via `SetWindowDisplayAffinity` (WDA_MONITOR).
* `WindowsScreenGuard.unprotect()` — removes display affinity protection.
* `WindowsScreenGuard.blockPrintScreen()` — installs a low-level keyboard hook to swallow `VK_SNAPSHOT`.
* `WindowsScreenGuard.unblockPrintScreen()` — removes the keyboard hook.
* `WindowsScreenGuard.isPrintScreenBlocked` — query hook state.
* `ScreenGuardResult` — carries success flag and Win32 error code on failure.
* All methods are no-ops on non-Windows platforms.
