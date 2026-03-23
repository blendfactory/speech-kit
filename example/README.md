# speech_kit example

Sample command-line app demonstrating speech recognition and microphone
permission queries with `speech_kit`. If speech recognition status is
`notDetermined`, the sample calls `SpeechKit.requestSpeechRecognitionPermission()`.
If the microphone is `undetermined`, it calls `SpeechKit.requestMicrophonePermission()`.
Either flow may only work fully in a signed app with the right usage strings.

Without `NSSpeechRecognitionUsageDescription` / `NSMicrophoneUsageDescription`
in the **host app** `Info.plist`, Apple can **abort** the process if the native
permission request runs. This package checks for those keys first; a plain
`dart run` therefore skips the risky native call and prints a `SpeechKitException`
message instead.

### Why a loose `Info.plist` on disk does not help

`NSBundle.mainBundle` is the **bundle that contains the running executable**.
`dart run` uses the Dart VM binary as the process image, so its main bundle is
the SDK layout—not a file you dropped next to the script. To “break through”
from a CLI workflow you need a **real `.app` directory** whose
`Contents/MacOS/<executable>` is **your** binary (for example produced with
`dart compile exe`), and `Contents/Info.plist` must carry the usage strings.

### Minimal `.app` bundle (correct `mainBundle`, not a loose plist file)

You cannot fix this by creating a random `Info.plist` on disk: the system only
reads usage strings from **`[NSBundle mainBundle]`**, i.e. the `.app` that owns
the **running executable**. `dart compile exe` does not run build hooks; use
`dart build cli` and copy its `bundle/bin` + `bundle/lib` output into an app
skeleton. The helper script does that layout:

```bash
bash scripts/build_macos_permission_app.sh
build/PermissionStatusDemo.app/Contents/MacOS/permission_status
```

That binary sees your template `macos_bundle/Info.plist` (so this package’s
native “is the key present?” check passes). **However**, on current macOS,
`SFSpeechRecognizer`’s `requestAuthorization` may still **abort** for a
headless/AOT tool even inside a minimal `.app` (no normal `NSApplication`
lifecycle). If you hit `SIGABRT` after “Requesting…”, treat **Xcode macOS App**
or **Flutter macOS** as the supported path for the permission dialog. Ad-hoc
signing sometimes helps TCC attribution:

```bash
codesign -s - --force --deep build/PermissionStatusDemo.app
```

## Requirements

- macOS with **Dart SDK 3.10+** (aligned with the main package)
- **Speech recognition** and **microphone** usage strings in the app bundle
  when embedding in a real app (`NSSpeechRecognitionUsageDescription`, etc.);
  this CLI may still prompt or reflect TCC state depending on context
- Native dylib from the parent package’s Dart build hooks (run `dart pub get`
  in the repo root or here so hooks can compile)

## Run

From this directory:

```bash
dart pub get
dart run bin/permission_status.dart
```

On non-macOS hosts the tool exits with code `2` and prints a short message.

### Asset inventory (SpeechTranscriber models)

`bin/asset_inventory.dart` calls `SpeechKit.assetInventoryStatus` for one
`SpeechTranscriberConfiguration` (default locale `en-US`). With `--install`, it
also runs `ensureAssetsInstalled`, which may **download on-device assets**
(network / time).

**Requires macOS 26+** (same as the parent package’s Swift `AssetInventory`).

```bash
dart pub get
dart run bin/asset_inventory.dart
dart run bin/asset_inventory.dart --locale ja-JP
dart run bin/asset_inventory.dart --locale en-US --install
```

## Layout

| Path | Role |
|------|------|
| `bin/permission_status.dart` | CLI entry |
| `lib/permission_status_sample.dart` | Shared sample logic |
| `bin/asset_inventory.dart` | CLI entry for AssetInventory |
| `lib/asset_inventory_sample.dart` | Asset status / optional install sample |
| `bin/analyze_file.dart` | CLI entry for file-based transcription |
| `lib/analyze_file_sample.dart` | Shared logic for `analyzeFile` |
| `macos_bundle/Info.plist` | Template plist for the bundled AOT demo |
| `scripts/build_macos_permission_app.sh` | Builds `build/PermissionStatusDemo.app` |

## Analyze a local audio file (SpeechAnalyzer)

Place a supported audio file yourself (for example under `assets/`) and pass
its path when you run the sample. **No audio is downloaded or committed** by
this repository; you are responsible for licensing and format.

**Requires macOS 26+** (same as the parent package’s `SpeechAnalyzer` bridge).

```bash
dart pub get
# Example: file you copied to example/assets/ (gitignored except README)
dart run bin/analyze_file.dart assets/my_sample.wav
dart run bin/analyze_file.dart --audio /absolute/path/to/sample.m4a --locale ja-JP
dart run bin/analyze_file.dart assets/my_sample.wav --install
```

See `example/assets/README.md` for notes on local assets.
