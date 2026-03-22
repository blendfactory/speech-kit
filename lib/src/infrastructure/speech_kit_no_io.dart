import 'package:speech_kit/src/domain/value_objects/assets/asset_inventory_status.dart';
import 'package:speech_kit/src/domain/value_objects/configuration/speech_module_configuration.dart';
import 'package:speech_kit/src/domain/value_objects/permissions/microphone_permission.dart';
import 'package:speech_kit/src/domain/value_objects/permissions/speech_recognition_permission.dart';

UnsupportedError _noIo() => UnsupportedError(
  'speech_kit requires dart:io (VM or native embedder). '
  'This configuration has no platform IO library.',
);

Future<SpeechRecognitionPermission> speechRecognitionAuthorizationStatusImpl() {
  return Future.error(_noIo());
}

Future<SpeechRecognitionPermission> requestSpeechRecognitionPermissionImpl() {
  return Future.error(_noIo());
}

Future<MicrophonePermission> microphonePermissionStatusImpl() {
  return Future.error(_noIo());
}

Future<bool> requestMicrophonePermissionImpl() {
  return Future.error(_noIo());
}

Future<AssetInventoryStatus> assetInventoryStatusImpl(
  List<SpeechModuleConfiguration> modules,
) {
  return Future.error(_noIo());
}

Future<void> ensureAssetsInstalledImpl(
  List<SpeechModuleConfiguration> modules,
) {
  return Future.error(_noIo());
}
