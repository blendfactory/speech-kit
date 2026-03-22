import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io' show Platform;

import 'package:ffi/ffi.dart';
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

typedef SkAssetCallbackNative = Void Function(Int32, Int32, Pointer<Utf8>);

@Native<
  Void Function(
    Pointer<Utf8>,
    Pointer<NativeFunction<SkAssetCallbackNative>>,
  )
>(
  symbol: 'sk_asset_inventory_status_async',
  assetId: 'package:speech_kit/speech_kit.dart',
)
external void _skAssetInventoryStatusAsync(
  Pointer<Utf8> jsonUtf8,
  Pointer<NativeFunction<SkAssetCallbackNative>> callback,
);

@Native<
  Void Function(
    Pointer<Utf8>,
    Pointer<NativeFunction<SkAssetCallbackNative>>,
  )
>(
  symbol: 'sk_asset_ensure_installed_async',
  assetId: 'package:speech_kit/speech_kit.dart',
)
external void _skAssetEnsureInstalledAsync(
  Pointer<Utf8> jsonUtf8,
  Pointer<NativeFunction<SkAssetCallbackNative>> callback,
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

String? _mallocUtf8ToDartAndFree(Pointer<Utf8> ptr) {
  if (ptr == nullptr) {
    return null;
  }
  try {
    return ptr.toDartString();
  } finally {
    malloc.free(ptr);
  }
}

String _encodeSpeechModulesJson(List<SpeechModuleConfiguration> modules) {
  final list = <Map<String, Object>>[];
  for (final m in modules) {
    switch (m) {
      case SpeechTranscriberConfiguration(:final localeId, :final preset):
        list.add({
          'kind': 'transcriber',
          'locale': localeId,
          'preset': preset.index,
        });
    }
  }
  return jsonEncode(list);
}

AssetInventoryStatus _assetInventoryStatusFromNativeCode(int code) {
  switch (code) {
    case 0:
      return AssetInventoryStatus.unsupported;
    case 1:
      return AssetInventoryStatus.supported;
    case 2:
      return AssetInventoryStatus.downloading;
    case 3:
      return AssetInventoryStatus.installed;
    default:
      throw SpeechKitException(
        'Unknown asset inventory status code: $code',
        failure: SpeechKitFailure.operationFailed,
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
  final json = _encodeSpeechModulesJson(modules);
  final jsonPtr = json.toNativeUtf8();
  final completer = Completer<AssetInventoryStatus>();
  late final NativeCallable<Void Function(Int32, Int32, Pointer<Utf8>)>
  callback;
  callback = NativeCallable.listener((int primary, int err, Pointer<Utf8> msg) {
    try {
      if (err != 0) {
        final text = _mallocUtf8ToDartAndFree(msg);
        completer.completeError(
          SpeechKitException(
            text ?? 'AssetInventory.status failed (error code $err)',
            failure: SpeechKitFailure.operationFailed,
          ),
        );
        return;
      }
      completer.complete(_assetInventoryStatusFromNativeCode(primary));
    } on Object catch (e, st) {
      if (!completer.isCompleted) {
        completer.completeError(e, st);
      }
    } finally {
      malloc.free(jsonPtr);
      callback.close();
    }
  });
  _skAssetInventoryStatusAsync(jsonPtr, callback.nativeFunction);
  return completer.future;
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
  final json = _encodeSpeechModulesJson(modules);
  final jsonPtr = json.toNativeUtf8();
  final completer = Completer<void>();
  late final NativeCallable<Void Function(Int32, Int32, Pointer<Utf8>)>
  callback;
  callback = NativeCallable.listener((int _, int err, Pointer<Utf8> msg) {
    try {
      if (err != 0) {
        final text = _mallocUtf8ToDartAndFree(msg);
        completer.completeError(
          SpeechKitException(
            text ?? 'ensureAssetsInstalled failed (error code $err)',
            failure: SpeechKitFailure.operationFailed,
          ),
        );
        return;
      }
      completer.complete();
    } on Object catch (e, st) {
      if (!completer.isCompleted) {
        completer.completeError(e, st);
      }
    } finally {
      malloc.free(jsonPtr);
      callback.close();
    }
  });
  _skAssetEnsureInstalledAsync(jsonPtr, callback.nativeFunction);
  return completer.future;
}
