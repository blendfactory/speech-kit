/// Dart bindings for Apple's Speech framework (SpeechAnalyzer pipeline).
library;

export 'src/application/speech_analysis_session.dart'
    show SpeechAnalysisSession;
export 'src/application/speech_kit.dart' show SpeechKit;
export 'src/domain/errors/speech_kit_exception.dart';
export 'src/domain/value_objects/assets/asset_inventory_status.dart';
export 'src/domain/value_objects/audio/compatible_audio_format.dart';
export 'src/domain/value_objects/configuration/dictation_transcriber_preset.dart';
export 'src/domain/value_objects/configuration/speech_detector_sensitivity.dart';
export 'src/domain/value_objects/configuration/speech_module_configuration.dart';
export 'src/domain/value_objects/configuration/speech_transcriber_preset.dart';
export 'src/domain/value_objects/identifiers/speech_analysis_session_id.dart';
export 'src/domain/value_objects/permissions/microphone_permission.dart';
export 'src/domain/value_objects/permissions/speech_recognition_permission.dart';
export 'src/domain/value_objects/results/transcription_segment.dart';
