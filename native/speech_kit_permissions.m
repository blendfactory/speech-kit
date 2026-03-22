#import <AVFAudio/AVFAudio.h>
#import <Foundation/Foundation.h>
#import <Speech/Speech.h>
#import <stdint.h>

void sk_request_speech_authorization(void (*callback)(int32_t status)) {
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
  [AVAudioApplication
      requestRecordPermissionWithCompletionHandler:^(BOOL granted) {
        if (callback != NULL) {
          callback(granted ? 1 : 0);
        }
      }];
}
