# Local audio assets (example)

This directory is for **your own** audio files when you run the example CLI
(`bin/analyze_file.dart`). **Do not commit** binary audio to git unless your
license and team policy allow it.

## Git

Everything under `assets/` is ignored except this `README.md` (see
`example/.gitignore`).

## Usage

1. Copy a supported audio file here (for example `assets/my_sample.wav`), or
   keep it anywhere on disk.
2. Pass the path when you run:

```bash
cd example
dart run bin/analyze_file.dart assets/my_sample.wav
```

## License

You are responsible for rights to any file you place here. The `speech_kit`
package does not ship sample speech audio.
