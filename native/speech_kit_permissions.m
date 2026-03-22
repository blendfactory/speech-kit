#import <AVFAudio/AVFAudio.h>
#import <Foundation/Foundation.h>
#import <Speech/Speech.h>
#import <stdint.h>

static BOOL sk_nonempty_info_plist_string(NSString *key) {
  id value = [[NSBundle mainBundle] objectForInfoDictionaryKey:key];
  if (![value isKindOfClass:[NSString class]]) {
    return NO;
  }
  return [(NSString *)value length] > 0;
}

int32_t sk_speech_recognition_usage_description_present(void) {
  return sk_nonempty_info_plist_string(@"NSSpeechRecognitionUsageDescription")
             ? 1
             : 0;
}

int32_t sk_microphone_usage_description_present(void) {
  return sk_nonempty_info_plist_string(@"NSMicrophoneUsageDescription") ? 1
                                                                        : 0;
}

void sk_request_speech_authorization(void (*callback)(int32_t status)) {
  if (!sk_nonempty_info_plist_string(@"NSSpeechRecognitionUsageDescription")) {
    if (callback != NULL) {
      callback((int32_t)-1);
    }
    return;
  }
  [SFSpeechRecognizer
      requestAuthorization:^(SFSpeechRecognizerAuthorizationStatus status) {
        if (callback != NULL) {
          callback((int32_t)status);
        }
      }];
}

int32_t sk_speech_authorization_status(void) {
  return (int32_t)[SFSpeechRecognizer authorizationStatus];
}

int32_t sk_microphone_record_permission(void) {
  switch (AVAudioApplication.sharedInstance.recordPermission) {
    case AVAudioApplicationRecordPermissionUndetermined:
      return 0;
    case AVAudioApplicationRecordPermissionDenied:
      return 1;
    case AVAudioApplicationRecordPermissionGranted:
      return 2;
    default:
      return 0;
  }
}

void sk_request_microphone_permission(void (*callback)(int32_t granted)) {
  if (!sk_nonempty_info_plist_string(@"NSMicrophoneUsageDescription")) {
    if (callback != NULL) {
      callback((int32_t)-1);
    }
    return;
  }
  [AVAudioApplication
      requestRecordPermissionWithCompletionHandler:^(BOOL granted) {
        if (callback != NULL) {
          callback(granted ? 1 : 0);
        }
      }];
}
