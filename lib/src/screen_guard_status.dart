/// Result returned by [WindowsScreenGuard.protect] and related methods.
class ScreenGuardResult {
  const ScreenGuardResult({required this.success, this.errorCode});

  /// Whether the operation succeeded.
  final bool success;

  /// Win32 error code if [success] is false. Null on success.
  final int? errorCode;

  @override
  String toString() => success
      ? 'ScreenGuardResult(success: true)'
      : 'ScreenGuardResult(success: false, errorCode: $errorCode)';
}
