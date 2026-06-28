/// Prevent screen capture, recording, and PrintScreen on Flutter Windows apps.
///
/// Uses the Windows [SetWindowDisplayAffinity] API (WDA_MONITOR flag) to make
/// your app's window show as black in any capture tool — the same technique
/// used by Netflix, banking apps, and enterprise software.
///
/// ```dart
/// import 'package:windows_screen_guard/windows_screen_guard.dart';
///
/// // Protect on startup
/// WindowsScreenGuard.protect();
///
/// // Also block the PrintScreen key (best-effort)
/// WindowsScreenGuard.blockPrintScreen();
///
/// // Remove all protection
/// WindowsScreenGuard.unprotect();
/// WindowsScreenGuard.unblockPrintScreen();
/// ```
library;

export 'src/windows_screen_guard.dart';
export 'src/screen_guard_status.dart';
