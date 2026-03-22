/// App authorization to use speech recognition (Apple `SFSpeechRecognizer`).
///
/// Values align with `SFSpeechRecognizerAuthorizationStatus` in the native
/// bridge; `SpeechKit` maps integers from FFI to this enum.
enum SpeechRecognitionPermission {
  notDetermined,
  denied,
  restricted,
  authorized,
}
