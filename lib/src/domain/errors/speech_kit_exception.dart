import 'package:meta/meta.dart';

/// Failure modes for `SpeechKit` operations.
enum SpeechKitFailure {
  /// Host OS is not supported (e.g. not Apple, or below minimum).
  unsupportedPlatform,

  /// Native asset / dylib is missing or symbols failed to link.
  nativeBridgeUnavailable,

  /// Feature is planned but not wired in the native layer yet.
  notImplemented,

  /// Underlying framework returned an error (see `message` / `cause`).
  operationFailed,

  /// Required `Info.plist` usage description is missing (Apple may abort if
  /// the native request were invoked).
  missingPrivacyUsageDescription,
}

/// Exception thrown when `SpeechKit` API fails.
@immutable
class SpeechKitException implements Exception {
  const SpeechKitException(
    this.message, {
    required this.failure,
    this.cause,
  });

  final String message;
  final SpeechKitFailure failure;
  final Object? cause;

  @override
  String toString() {
    if (cause == null) {
      return 'SpeechKitException(${failure.name}): $message';
    }
    return 'SpeechKitException(${failure.name}): $message (cause: $cause)';
  }
}
