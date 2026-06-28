import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:windows_screen_guard/windows_screen_guard.dart';

void main() {
  group('ScreenGuardResult', () {
    test('success result has no error code', () {
      const result = ScreenGuardResult(success: true);
      expect(result.success, isTrue);
      expect(result.errorCode, isNull);
    });

    test('failure result carries error code', () {
      const result = ScreenGuardResult(success: false, errorCode: 5);
      expect(result.success, isFalse);
      expect(result.errorCode, equals(5));
    });
  });

  // On non-Windows platforms (e.g. macOS CI) the calls are no-ops.
  group('WindowsScreenGuard — non-Windows no-op', () {
    test('protect returns success on non-Windows', () {
      if (Platform.isWindows) return;
      final result = WindowsScreenGuard.protect();
      expect(result.success, isTrue);
    });

    test('unprotect returns success on non-Windows', () {
      if (Platform.isWindows) return;
      final result = WindowsScreenGuard.unprotect();
      expect(result.success, isTrue);
    });

    test('blockPrintScreen returns true on non-Windows', () {
      if (Platform.isWindows) return;
      expect(WindowsScreenGuard.blockPrintScreen(), isTrue);
    });

    test('isPrintScreenBlocked is false initially', () {
      if (Platform.isWindows) return;
      expect(WindowsScreenGuard.isPrintScreenBlocked, isFalse);
    });
  });
}
