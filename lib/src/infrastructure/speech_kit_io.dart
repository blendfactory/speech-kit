import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io' show Platform;
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:speech_kit/src/application/speech_analysis_session.dart';
import 'package:speech_kit/src/domain/errors/speech_kit_exception.dart';
import 'package:speech_kit/src/domain/value_objects/analysis/analysis_context.dart';
import 'package:speech_kit/src/domain/value_objects/assets/asset_inventory_status.dart';
import 'package:speech_kit/src/domain/value_objects/audio/compatible_audio_format.dart';
import 'package:speech_kit/src/domain/value_objects/configuration/speech_analyzer_options.dart';
import 'package:speech_kit/src/domain/value_objects/configuration/speech_module_configuration.dart';
import 'package:speech_kit/src/domain/value_objects/identifiers/speech_analysis_session_id.dart';
import 'package:speech_kit/src/domain/value_objects/permissions/microphone_permission.dart';
import 'package:speech_kit/src/domain/value_objects/permissions/speech_recognition_permission.dart';
import 'package:speech_kit/src/domain/value_objects/results/transcription_segment.dart';

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

@Native<
  Void Function(
    Pointer<Utf8>,
    Pointer<NativeFunction<SkAssetCallbackNative>>,
  )
>(
  symbol: 'sk_speech_best_available_audio_format_async',
  assetId: 'package:speech_kit/speech_kit.dart',
)
external void _skSpeechBestAvailableAudioFormatAsync(
  Pointer<Utf8> jsonUtf8,
  Pointer<NativeFunction<SkAssetCallbackNative>> callback,
);

typedef SkSpeechAnalyzerEventCallbackNative =
    Void Function(
      Int32 eventType,
      Int32 errCode,
      Pointer<Utf8> msg,
    );

@Native<
  Int32 Function(
    Pointer<Utf8>,
    Pointer<Utf8>,
    Pointer<Utf8>,
    Pointer<Utf8>,
    Pointer<Utf8>,
    Int32,
    Pointer<NativeFunction<SkSpeechAnalyzerEventCallbackNative>>,
  )
>(
  symbol: 'sk_speech_analyzer_analyze_file_async',
  assetId: 'package:speech_kit/speech_kit.dart',
)
external int _skSpeechAnalyzerAnalyzeFileAsync(
  Pointer<Utf8> modulesJsonUtf8,
  Pointer<Utf8> audioFilePathUtf8,
  Pointer<Utf8> analysisContextJsonUtf8,
  Pointer<Utf8> analyzerOptionsJsonUtf8,
  Pointer<Utf8> prepareFormatJsonUtf8,
  int prepareProgressEnabled,
  Pointer<NativeFunction<SkSpeechAnalyzerEventCallbackNative>> callback,
);

@Native<
  Int32 Function(
    Pointer<Utf8>,
    Pointer<Utf8>,
    Pointer<Utf8>,
    Pointer<Uint8>,
    Int64,
    Pointer<Utf8>,
    Pointer<Utf8>,
    Int32,
    Pointer<NativeFunction<SkSpeechAnalyzerEventCallbackNative>>,
  )
>(
  symbol: 'sk_speech_analyzer_analyze_pcm_async',
  assetId: 'package:speech_kit/speech_kit.dart',
)
external int _skSpeechAnalyzerAnalyzePcmAsync(
  Pointer<Utf8> modulesJsonUtf8,
  Pointer<Utf8> formatJsonUtf8,
  Pointer<Utf8> analysisContextJsonUtf8,
  Pointer<Uint8> pcmBytes,
  int pcmByteLength,
  Pointer<Utf8> analyzerOptionsJsonUtf8,
  Pointer<Utf8> prepareFormatJsonUtf8,
  int prepareProgressEnabled,
  Pointer<NativeFunction<SkSpeechAnalyzerEventCallbackNative>> callback,
);

@Native<
  Int32 Function(
    Pointer<Utf8>,
    Pointer<Utf8>,
    Pointer<Utf8>,
    Pointer<Utf8>,
    Pointer<Utf8>,
    Int32,
    Pointer<NativeFunction<SkSpeechAnalyzerEventCallbackNative>>,
  )
>(
  symbol: 'sk_speech_analyzer_start_pcm_stream_async',
  assetId: 'package:speech_kit/speech_kit.dart',
)
external int _skSpeechAnalyzerStartPcmStreamAsync(
  Pointer<Utf8> modulesJsonUtf8,
  Pointer<Utf8> formatJsonUtf8,
  Pointer<Utf8> analysisContextJsonUtf8,
  Pointer<Utf8> analyzerOptionsJsonUtf8,
  Pointer<Utf8> prepareFormatJsonUtf8,
  int prepareProgressEnabled,
  Pointer<NativeFunction<SkSpeechAnalyzerEventCallbackNative>> callback,
);

@Native<
  Int32 Function(
    Int32,
    Pointer<Uint8>,
    Int64,
  )
>(
  symbol: 'sk_speech_analyzer_push_pcm_chunk',
  assetId: 'package:speech_kit/speech_kit.dart',
)
external int _skSpeechAnalyzerPushPcmChunk(
  int sessionId,
  Pointer<Uint8> pcmBytes,
  int pcmByteLength,
);

@Native<
  Void Function(
    Int32,
  )
>(
  symbol: 'sk_speech_analyzer_finish_pcm_input',
  assetId: 'package:speech_kit/speech_kit.dart',
)
external void _skSpeechAnalyzerFinishPcmInput(int sessionId);

@Native<
  Void Function(
    Int32,
  )
>(
  symbol: 'sk_speech_analyzer_cancel_and_finish_now',
  assetId: 'package:speech_kit/speech_kit.dart',
)
external void _skSpeechAnalyzerCancelAndFinishNow(int sessionId);

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

String? _encodeAnalysisContextJson(AnalysisContext? context) {
  if (context == null) {
    return null;
  }
  if (context.contextualStringsByTag.isEmpty) {
    return null;
  }
  return jsonEncode(<String, Object>{
    'contextualStrings': context.contextualStringsByTag,
  });
}

String? _encodeAnalyzerOptionsJson(SpeechAnalyzerOptions? options) {
  if (options == null) {
    return null;
  }
  return jsonEncode(options.toJson());
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
      case DictationTranscriberConfiguration(:final localeId, :final preset):
        list.add({
          'kind': 'dictation',
          'locale': localeId,
          'preset': preset.index,
        });
      case SpeechDetectorConfiguration(
        :final sensitivity,
        :final reportResults,
      ):
        list.add({
          'kind': 'speechDetector',
          'sensitivity': sensitivity.index,
          'reportResults': reportResults,
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

Future<CompatibleAudioFormat> bestAvailableAudioFormatImpl(
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
  final completer = Completer<CompatibleAudioFormat>();
  late final NativeCallable<Void Function(Int32, Int32, Pointer<Utf8>)>
  callback;
  callback = NativeCallable.listener((int _, int err, Pointer<Utf8> msg) {
    try {
      if (err != 0) {
        final text = _mallocUtf8ToDartAndFree(msg);
        completer.completeError(
          SpeechKitException(
            text ?? 'bestAvailableAudioFormat failed (error code $err)',
            failure: SpeechKitFailure.operationFailed,
          ),
        );
        return;
      }
      final text = _mallocUtf8ToDartAndFree(msg);
      if (text == null) {
        completer.completeError(
          const SpeechKitException(
            'bestAvailableAudioFormat returned empty payload.',
            failure: SpeechKitFailure.operationFailed,
          ),
        );
        return;
      }
      final payload = jsonDecode(text) as Map<String, dynamic>;
      completer.complete(CompatibleAudioFormat.fromJson(payload));
    } on Object catch (e, st) {
      if (!completer.isCompleted) {
        completer.completeError(e, st);
      }
    } finally {
      malloc.free(jsonPtr);
      callback.close();
    }
  });
  _skSpeechBestAvailableAudioFormatAsync(jsonPtr, callback.nativeFunction);
  return completer.future;
}

Duration _durationFromSeconds(double seconds) {
  if (!seconds.isFinite || seconds <= 0) {
    return Duration.zero;
  }
  final micros = (seconds * 1e6).round();
  if (micros <= 0) {
    return Duration.zero;
  }
  return Duration(microseconds: micros);
}

SpeechAnalysisSession _speechAnalysisSessionFromNative(
  List<SpeechModuleConfiguration> modules,
  AnalysisContext? analysisContext,
  int Function(Pointer<NativeFunction<SkSpeechAnalyzerEventCallbackNative>>)
  invokeNative, {
  void Function(double fractionCompleted)? onPrepareProgress,
  List<bool>? pcmStreamCancelFlag,
  void Function(int sessionId)? onSessionStarted,
}) {
  _ensureAppleDesktop();
  if (modules.isEmpty) {
    throw const SpeechKitException(
      'At least one SpeechModuleConfiguration is required.',
      failure: SpeechKitFailure.operationFailed,
    );
  }

  final prepareProgress = onPrepareProgress;

  final doneCompleter = Completer<void>();
  var cancelRequested = false;
  late int nativeSessionId;

  Future<void> sessionCancel() async {
    if (cancelRequested) {
      return;
    }
    cancelRequested = true;
    pcmStreamCancelFlag?[0] = true;
    if (nativeSessionId > 0) {
      _skSpeechAnalyzerCancelAndFinishNow(nativeSessionId);
    }
    // Wait for the native task to finish and close the callback.
    await doneCompleter.future;
  }

  final controller = StreamController<TranscriptionSegment>(
    onCancel: () async {
      // Stream cancellation maps to "cancel and finish now".
      await sessionCancel();
    },
  );

  late final NativeCallable<Void Function(Int32, Int32, Pointer<Utf8>)>
  callback;

  void closeIfDone() {
    if (!controller.isClosed) {
      unawaited(controller.close());
    }
  }

  callback = NativeCallable.listener(
    (int eventType, int errCode, Pointer<Utf8> msg) {
      final text = _mallocUtf8ToDartAndFree(msg);
      try {
        if (eventType == 2) {
          if (prepareProgress != null && text != null) {
            final payload = jsonDecode(text) as Map<String, dynamic>;
            final f = (payload['fractionCompleted'] as num).toDouble();
            if (f.isFinite) {
              prepareProgress(f);
            }
          }
          return;
        }

        if (eventType == 0) {
          if (text == null) {
            return;
          }
          final payload = jsonDecode(text) as Map<String, dynamic>;
          final segment = TranscriptionSegment(
            text: payload['text'] as String,
            rangeStart: _durationFromSeconds(
              (payload['rangeStartSeconds'] as num).toDouble(),
            ),
            rangeDuration: _durationFromSeconds(
              (payload['rangeDurationSeconds'] as num).toDouble(),
            ),
            resultsFinalizationOffset: _durationFromSeconds(
              (payload['resultsFinalizationOffsetSeconds'] as num).toDouble(),
            ),
            alternativeTexts: (payload['alternativeTexts'] as List<dynamic>)
                .map((e) => e as String)
                .toList(growable: false),
          );
          if (!controller.isClosed) {
            controller.add(segment);
          }
          return;
        }

        if (eventType == 1) {
          if (!doneCompleter.isCompleted) {
            doneCompleter.complete();
          }
          closeIfDone();
          return;
        }

        if (eventType == -1) {
          final message = text ?? 'SpeechAnalyzer failed.';
          final exception = SpeechKitException(
            message,
            failure: SpeechKitFailure.operationFailed,
          );
          if (!doneCompleter.isCompleted) {
            doneCompleter.completeError(exception);
          }
          if (!controller.isClosed) {
            controller.addError(exception);
          }
          closeIfDone();
          return;
        }
      } finally {
        if (eventType == 1 || eventType == -1) {
          callback.close();
        }
      }
    },
  );

  nativeSessionId = invokeNative(callback.nativeFunction);
  onSessionStarted?.call(nativeSessionId);

  return SpeechAnalysisSession(
    id: SpeechAnalysisSessionId(nativeSessionId),
    results: controller.stream,
    finalizeAndFinish: () => doneCompleter.future,
    cancelAndFinishNow: sessionCancel,
  );
}

Future<void> _pumpPcmStreamToNative(
  int sessionId,
  Stream<Uint8List> pcmChunks,
  List<bool> cancelFlag,
) async {
  try {
    await for (final chunk in pcmChunks) {
      if (cancelFlag[0]) {
        return;
      }
      if (chunk.isEmpty) {
        continue;
      }
      final ptr = malloc<Uint8>(chunk.length);
      ptr.asTypedList(chunk.length).setAll(0, chunk);
      try {
        final code = _skSpeechAnalyzerPushPcmChunk(
          sessionId,
          ptr,
          chunk.length,
        );
        if (code != 0) {
          throw SpeechKitException(
            code == -1
                ? 'PCM stream push failed: no active session or stream ended.'
                : 'PCM stream push failed: invalid buffer (frame alignment).',
            failure: SpeechKitFailure.operationFailed,
          );
        }
      } finally {
        malloc.free(ptr);
      }
    }
    if (!cancelFlag[0]) {
      _skSpeechAnalyzerFinishPcmInput(sessionId);
    }
  } on Object {
    if (!cancelFlag[0]) {
      _skSpeechAnalyzerCancelAndFinishNow(sessionId);
    }
  }
}

SpeechAnalysisSession analyzeFileImpl(
  String audioFilePath, {
  required List<SpeechModuleConfiguration> modules,
  AnalysisContext? analysisContext,
  SpeechAnalyzerOptions? analyzerOptions,
  CompatibleAudioFormat? prepareAudioFormat,
  void Function(double fractionCompleted)? onPrepareProgress,
}) {
  if (audioFilePath.isEmpty) {
    throw const SpeechKitException(
      'audioFilePath must be non-empty.',
      failure: SpeechKitFailure.operationFailed,
    );
  }

  final modulesJson = _encodeSpeechModulesJson(modules);
  final prepareJson = prepareAudioFormat == null
      ? null
      : jsonEncode(prepareAudioFormat.toJson());
  final analyzerOptsJson = _encodeAnalyzerOptionsJson(analyzerOptions);
  return _speechAnalysisSessionFromNative(
    modules,
    analysisContext,
    (nativeCb) {
      final modulesJsonPtr = modulesJson.toNativeUtf8();
      final audioFilePathPtr = audioFilePath.toNativeUtf8();
      final contextJson = _encodeAnalysisContextJson(analysisContext);
      final contextJsonPtr = contextJson == null
          ? nullptr
          : contextJson.toNativeUtf8();
      final analyzerOptsPtr = analyzerOptsJson == null
          ? nullptr
          : analyzerOptsJson.toNativeUtf8();
      final preparePtr = prepareJson == null
          ? nullptr
          : prepareJson.toNativeUtf8();

      try {
        return _skSpeechAnalyzerAnalyzeFileAsync(
          modulesJsonPtr,
          audioFilePathPtr,
          contextJsonPtr,
          analyzerOptsPtr,
          preparePtr,
          onPrepareProgress != null ? 1 : 0,
          nativeCb,
        );
      } finally {
        malloc.free(modulesJsonPtr);
        malloc.free(audioFilePathPtr);
        if (contextJsonPtr != nullptr) {
          malloc.free(contextJsonPtr);
        }
        if (analyzerOptsPtr != nullptr) {
          malloc.free(analyzerOptsPtr);
        }
        if (preparePtr != nullptr) {
          malloc.free(preparePtr);
        }
      }
    },
    onPrepareProgress: onPrepareProgress,
  );
}

SpeechAnalysisSession analyzePcmImpl(
  Uint8List pcmBytes, {
  required CompatibleAudioFormat format,
  required List<SpeechModuleConfiguration> modules,
  AnalysisContext? analysisContext,
  SpeechAnalyzerOptions? analyzerOptions,
  CompatibleAudioFormat? prepareAudioFormat,
  void Function(double fractionCompleted)? onPrepareProgress,
}) {
  if (pcmBytes.isEmpty) {
    throw const SpeechKitException(
      'pcmBytes must be non-empty.',
      failure: SpeechKitFailure.operationFailed,
    );
  }

  final modulesJson = _encodeSpeechModulesJson(modules);
  final formatJson = jsonEncode(format.toJson());
  final prepareJson = prepareAudioFormat == null
      ? null
      : jsonEncode(prepareAudioFormat.toJson());
  final analyzerOptsJson = _encodeAnalyzerOptionsJson(analyzerOptions);
  return _speechAnalysisSessionFromNative(
    modules,
    analysisContext,
    (nativeCb) {
      final modulesJsonPtr = modulesJson.toNativeUtf8();
      final formatJsonPtr = formatJson.toNativeUtf8();
      final contextJson = _encodeAnalysisContextJson(analysisContext);
      final contextJsonPtr = contextJson == null
          ? nullptr
          : contextJson.toNativeUtf8();
      final analyzerOptsPtr = analyzerOptsJson == null
          ? nullptr
          : analyzerOptsJson.toNativeUtf8();
      final preparePtr = prepareJson == null
          ? nullptr
          : prepareJson.toNativeUtf8();
      final pcmPtr = malloc<Uint8>(pcmBytes.length);
      pcmPtr.asTypedList(pcmBytes.length).setAll(0, pcmBytes);

      try {
        return _skSpeechAnalyzerAnalyzePcmAsync(
          modulesJsonPtr,
          formatJsonPtr,
          contextJsonPtr,
          pcmPtr,
          pcmBytes.length,
          analyzerOptsPtr,
          preparePtr,
          onPrepareProgress != null ? 1 : 0,
          nativeCb,
        );
      } finally {
        malloc.free(modulesJsonPtr);
        malloc.free(formatJsonPtr);
        if (contextJsonPtr != nullptr) {
          malloc.free(contextJsonPtr);
        }
        if (analyzerOptsPtr != nullptr) {
          malloc.free(analyzerOptsPtr);
        }
        if (preparePtr != nullptr) {
          malloc.free(preparePtr);
        }
        malloc.free(pcmPtr);
      }
    },
    onPrepareProgress: onPrepareProgress,
  );
}

SpeechAnalysisSession analyzePcmStreamImpl(
  Stream<Uint8List> pcmChunks, {
  required CompatibleAudioFormat format,
  required List<SpeechModuleConfiguration> modules,
  AnalysisContext? analysisContext,
  SpeechAnalyzerOptions? analyzerOptions,
  CompatibleAudioFormat? prepareAudioFormat,
  void Function(double fractionCompleted)? onPrepareProgress,
}) {
  final modulesJson = _encodeSpeechModulesJson(modules);
  final formatJson = jsonEncode(format.toJson());
  final prepareJson = prepareAudioFormat == null
      ? null
      : jsonEncode(prepareAudioFormat.toJson());
  final analyzerOptsJson = _encodeAnalyzerOptionsJson(analyzerOptions);
  final pcmStreamCancelFlag = <bool>[false];

  return _speechAnalysisSessionFromNative(
    modules,
    analysisContext,
    (nativeCb) {
      final modulesJsonPtr = modulesJson.toNativeUtf8();
      final formatJsonPtr = formatJson.toNativeUtf8();
      final contextJson = _encodeAnalysisContextJson(analysisContext);
      final contextJsonPtr = contextJson == null
          ? nullptr
          : contextJson.toNativeUtf8();
      final analyzerOptsPtr = analyzerOptsJson == null
          ? nullptr
          : analyzerOptsJson.toNativeUtf8();
      final preparePtr = prepareJson == null
          ? nullptr
          : prepareJson.toNativeUtf8();

      try {
        return _skSpeechAnalyzerStartPcmStreamAsync(
          modulesJsonPtr,
          formatJsonPtr,
          contextJsonPtr,
          analyzerOptsPtr,
          preparePtr,
          onPrepareProgress != null ? 1 : 0,
          nativeCb,
        );
      } finally {
        malloc.free(modulesJsonPtr);
        malloc.free(formatJsonPtr);
        if (contextJsonPtr != nullptr) {
          malloc.free(contextJsonPtr);
        }
        if (analyzerOptsPtr != nullptr) {
          malloc.free(analyzerOptsPtr);
        }
        if (preparePtr != nullptr) {
          malloc.free(preparePtr);
        }
      }
    },
    onPrepareProgress: onPrepareProgress,
    pcmStreamCancelFlag: pcmStreamCancelFlag,
    onSessionStarted: (sessionId) {
      unawaited(
        _pumpPcmStreamToNative(sessionId, pcmChunks, pcmStreamCancelFlag),
      );
    },
  );
}
