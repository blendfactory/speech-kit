# speech_kit example

Sample command-line apps demonstrating **`speech_kit`** on **macOS** (native FFI).
The **Run (overview)** table below lists each `bin/*.dart` entry point.

Permission flows (`permission_status`) may only work fully in a signed app with
the right usage strings.

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

Most samples require **macOS 26+** for the same APIs as the parent package
(`AssetInventory`, `SpeechAnalyzer`, `SFCustomLanguageModelData`, etc.).

## Run (overview)

From this directory:

```bash
dart pub get
```

On non-macOS hosts, tools exit with code `2` and print a short message.

| Command | What it demonstrates |
|---------|----------------------|
| `permission_status` | Speech + microphone permission status / request |
| `asset_inventory` | `AssetInventory` for `SpeechTranscriber` (optional `--install`) |
| `best_audio_format` | `bestAvailableAudioFormat` (use `--install` if assets missing) |
| `supported_phonemes` | `supportedCustomLanguagePhonemes` (custom LM ARPAbet subset) |
| `export_custom_lm` | `exportCustomLanguageModelData` (minimal phrase counts) |
| `end_model_retention` | `endSpeechModelRetention` |
| `analyze_file` | `analyzeFile` on a local audio path (optional bias / analyzer options) |

## Permission status

```bash
dart pub get
dart run bin/permission_status.dart
```

## Asset inventory (SpeechTranscriber models)

Calls `SpeechKit.assetInventoryStatus` for one `SpeechTranscriberConfiguration`
(default locale `en-US`). With `--install`, it also runs `ensureAssetsInstalled`,
which may **download on-device assets** (network / time).

```bash
dart run bin/asset_inventory.dart
dart run bin/asset_inventory.dart --locale ja-JP
dart run bin/asset_inventory.dart --locale en-US --install
```

## Best available audio format

Uses the same transcriber module list as other samples and prints
`CompatibleAudioFormat` fields (useful before recording PCM for `analyzePcm`).

If you see “install on-device assets first”, run with **`--install`** once (may
download models), or run `asset_inventory.dart --install` for the same locale
first.

```bash
dart run bin/best_audio_format.dart
dart run bin/best_audio_format.dart --install
dart run bin/best_audio_format.dart --locale ja-JP --install
```

## Supported phonemes (custom language model)

Lists phoneme strings valid for `CustomLanguageModelPronunciation` in the given
locale.

```bash
dart run bin/supported_phonemes.dart
dart run bin/supported_phonemes.dart --locale en-US
```

## Export custom language model training data

Writes a **small** training file (phrase counts only) to the path you pass. Use
as input to `prepareCustomLanguageModel` in a full app workflow.

```bash
dart run bin/export_custom_lm.dart --output /tmp/speech_kit_lm.dat
dart run bin/export_custom_lm.dart -o /tmp/out.dat --locale en-US
```

## End model retention

Calls `SpeechModels.endRetention()` via `SpeechKit`. Use after analysis when
you used `SpeechAnalyzerOptions` with lingering / process-lifetime retention and
no longer need models kept in memory.

```bash
dart run bin/end_model_retention.dart
```

## Analyze a local audio file (SpeechAnalyzer)

Place a supported audio file yourself (for example under `assets/`) and pass
its path. **No audio is downloaded or committed** by this repository.

Optional flags:

- `--bias` / `-b` — comma-separated words biased under the `general` tag
  (`AnalysisContext`)
- `--task-priority` — `high` | `medium` | `low` | `background`
- `--model-retention` — `whileInUse` | `lingering` | `processLifetime`

```bash
dart pub get
dart run bin/analyze_file.dart assets/my_sample.wav
dart run bin/analyze_file.dart --audio /absolute/path/to/sample.m4a --locale ja-JP
dart run bin/analyze_file.dart assets/my_sample.wav --install
dart run bin/analyze_file.dart assets/sample.wav --bias AcmeCorp,SpeechKit \
  --task-priority high --model-retention whileInUse
```

See `example/assets/README.md` for notes on local assets.

## Layout

Approximate directory layout (same idea as running `tree` from the `example/`
directory; omitting `.dart_tool/` and other generated paths):

```text
.
├── analysis_options.yaml
├── pubspec.yaml
├── README.md
├── assets
│   └── README.md
├── bin
│   ├── analyze_file.dart
│   ├── asset_inventory.dart
│   ├── best_audio_format.dart
│   ├── end_model_retention.dart
│   ├── export_custom_lm.dart
│   ├── permission_status.dart
│   └── supported_phonemes.dart
├── lib
│   ├── analyze_file_sample.dart
│   ├── asset_inventory_sample.dart
│   ├── best_audio_format_sample.dart
│   ├── end_model_retention_sample.dart
│   ├── export_custom_lm_sample.dart
│   ├── example_common.dart
│   ├── permission_status_sample.dart
│   └── supported_phonemes_sample.dart
├── macos_bundle
│   └── Info.plist
└── scripts
    └── build_macos_permission_app.sh
```

- **`bin/`** — thin CLIs: parse args, then call the matching `lib/*_sample.dart`.
- **`lib/`** — shared logic and `example_common.dart` (macOS-only guards).
- **`macos_bundle/`** — template plist for the AOT permission demo (`scripts/`).
- **`assets/`** — optional local audio; see `assets/README.md` (binary files are
  gitignored).
