import 'dart:async';
import 'dart:ffi';
import 'dart:io' show Platform;

import 'package:speech_kit/src/domain/errors/speech_kit_exception.dart';
import 'package:speech_kit/src/domain/value_objects/assets/asset_inventory_status.dart';
import 'package:speech_kit/src/domain/value_objects/configuration/speech_module_configuration.dart';
import 'package:speech_kit/src/domain/value_objects/permissions/microphone_permission.dart';
import 'package:speech_kit/src/domain/value_objects/permissions/speech_recognition_permission.dart';

@Native<Int32 Function()>(
  symbol: 'sk_speech_authorization_status',
  assetId: 'package:speech_kit/speech_kit.dart',
)
external int _skSpeechAuthorizationStatus();

@Native<Int32 Function()>(
  symbol: 'sk_speech_recognition_usage_description_present',
  assetId: 'package:speech_kit/speech_kit.dart',
)
external int _skSpeechRecognitionUsageDescriptionPresent();

@Native<Int32 Function()>(
  symbol: 'sk_microphone_usage_description_present',
  assetId: 'package:speech_kit/speech_kit.dart',
)
external int _skMicrophoneUsageDescriptionPresent();

@Native<
  Void Function(
    Pointer<NativeFunction<Void Function(Int32)>>,
  )
>(
  symbol: 'sk_request_speech_authorization',
  assetId: 'package:speech_kit/speech_kit.dart',
)
external void _skRequestSpeechAuthorization(
  Pointer<NativeFunction<Void Function(Int32)>> callback,
);

@Native<Int32 Function()>(
  symbol: 'sk_microphone_record_permission',
  assetId: 'package:speech_kit/speech_kit.dart',
)
external int _skMicrophoneRecordPermission();

@Native<
  Void Function(
    Pointer<NativeFunction<Void Function(Int32)>>,
  )
>(
  symbol: 'sk_request_microphone_permission',
  assetId: 'package:speech_kit/speech_kit.dart',
)
external void _skRequestMicrophonePermission(
  Pointer<NativeFunction<Void Function(Int32)>> callback,
);

SpeechRecognitionPermission _speechRecognitionPermissionFromCode(int code) {
  switch (code) {
    case -1:
      throw const SpeechKitException(
        'Missing NSSpeechRecognitionUsageDescription in the app Info.plist. '
        'Apple aborts the process if speech authorization is requested without '
        'this key.',
        failure: SpeechKitFailure.missingPrivacyUsageDescription,
      );
    case 0:
      return SpeechRecognitionPermission.notDetermined;
    case 1:
      return SpeechRecognitionPermission.denied;
    case 2:
      return SpeechRecognitionPermission.restricted;
    case 3:
      return SpeechRecognitionPermission.authorized;
    default:
      throw SpeechKitException(
        'Unknown speech authorization code: $code',
        failure: SpeechKitFailure.operationFailed,
      );
  }
}

MicrophonePermission _microphonePermissionFromCode(int code) {
  switch (code) {
    case 0:
      return MicrophonePermission.undetermined;
    case 1:
      return MicrophonePermission.denied;
    case 2:
      return MicrophonePermission.granted;
    default:
      throw SpeechKitException(
        'Unknown microphone permission code: $code',
        failure: SpeechKitFailure.operationFailed,
      );
  }
}

void _ensureAppleDesktop() {
  if (!Platform.isMacOS) {
    throw UnsupportedError(
      'speech_kit native permissions are implemented for macOS only in this '
      'release. Current platform: ${Platform.operatingSystem}',
    );
  }
}

Future<SpeechRecognitionPermission> speechRecognitionAuthorizationStatusImpl() {
  _ensureAppleDesktop();
  final code = _skSpeechAuthorizationStatus();
  return Future.value(_speechRecognitionPermissionFromCode(code));
}

Future<SpeechRecognitionPermission> requestSpeechRecognitionPermissionImpl() {
  _ensureAppleDesktop();
  if (_skSpeechRecognitionUsageDescriptionPresent() == 0) {
    return Future.error(
      const SpeechKitException(
        'Cannot request speech recognition authorization: '
        'NSSpeechRecognitionUsageDescription is missing from the main bundle '
        'Info.plist. A plain `dart run` CLI has no such plist; use a macOS app '
        'target or omit the request.',
        failure: SpeechKitFailure.missingPrivacyUsageDescription,
      ),
    );
  }
  final completer = Completer<SpeechRecognitionPermission>();
  late final NativeCallable<Void Function(Int32)> callback;
  callback = NativeCallable.listener((int code) {
    try {
      completer.complete(_speechRecognitionPermissionFromCode(code));
    } on Object catch (e, st) {
      if (!completer.isCompleted) {
        completer.completeError(e, st);
      }
    } finally {
      callback.close();
    }
  });
  _skRequestSpeechAuthorization(callback.nativeFunction);
  return completer.future;
}

Future<MicrophonePermission> microphonePermissionStatusImpl() {
  _ensureAppleDesktop();
  final code = _skMicrophoneRecordPermission();
  return Future.value(_microphonePermissionFromCode(code));
}

Future<bool> requestMicrophonePermissionImpl() {
  _ensureAppleDesktop();
  if (_skMicrophoneUsageDescriptionPresent() == 0) {
    return Future.error(
      const SpeechKitException(
        'Cannot request microphone access: NSMicrophoneUsageDescription is '
        'missing from the main bundle Info.plist. Use a proper app bundle or '
        'omit the request.',
        failure: SpeechKitFailure.missingPrivacyUsageDescription,
      ),
    );
  }
  final completer = Completer<bool>();
  late final NativeCallable<Void Function(Int32)> callback;
  callback = NativeCallable.listener((int granted) {
    try {
      if (granted < 0) {
        completer.completeError(
          const SpeechKitException(
            'Missing NSMicrophoneUsageDescription in the app Info.plist.',
            failure: SpeechKitFailure.missingPrivacyUsageDescription,
          ),
        );
        return;
      }
      completer.complete(granted != 0);
    } on Object catch (e, st) {
      if (!completer.isCompleted) {
        completer.completeError(e, st);
      }
    } finally {
      callback.close();
    }
  });
  _skRequestMicrophonePermission(callback.nativeFunction);
  return completer.future;
}

Future<AssetInventoryStatus> assetInventoryStatusImpl(
  List<SpeechModuleConfiguration> modules,
) {
  _ensureAppleDesktop();
  if (modules.isEmpty) {
    return Future.error(
      const SpeechKitException(
        'At least one SpeechModuleConfiguration is required.',
        failure: SpeechKitFailure.operationFailed,
      ),
    );
  }
  return Future.error(
    const SpeechKitException(
      'AssetInventory.status(forModules:) requires the Swift SpeechAnalyzer '
      'bridge; not implemented yet.',
      failure: SpeechKitFailure.notImplemented,
    ),
  );
}

Future<void> ensureAssetsInstalledImpl(
  List<SpeechModuleConfiguration> modules,
) {
  _ensureAppleDesktop();
  if (modules.isEmpty) {
    return Future.error(
      const SpeechKitException(
        'At least one SpeechModuleConfiguration is required.',
        failure: SpeechKitFailure.operationFailed,
      ),
    );
  }
  return Future.error(
    const SpeechKitException(
      'AssetInventory.assetInstallationRequest(supporting:) requires the '
      'Swift bridge; not implemented yet.',
      failure: SpeechKitFailure.notImplemented,
    ),
  );
}
