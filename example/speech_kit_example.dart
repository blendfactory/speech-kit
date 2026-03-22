import 'dart:developer' as developer;

import 'package:speech_kit/speech_kit.dart';

void main() {
  const kit = SpeechKit();
  developer.log('$kit', name: 'speech_kit.example');
}
