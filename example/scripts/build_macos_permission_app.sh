#!/usr/bin/env bash
# Builds a minimal macOS .app around `dart build cli` output so the AOT binary
# lives under Contents/MacOS/ with Info.plist at Contents/Info.plist. That layout
# is what makes NSBundle.mainBundle expose NSSpeechRecognitionUsageDescription
# to native checks (unlike `dart run`, which uses the VM bundle).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

dart pub get

CLI_STAGING="build/cli_staging"
APP_DIR="build/PermissionStatusDemo.app"
CONTENTS="$APP_DIR/Contents"
EXE_NAME="permission_status"

rm -rf "$CLI_STAGING" "$APP_DIR"
dart build cli -o "$CLI_STAGING" --target bin/permission_status.dart

mkdir -p "$CONTENTS/MacOS" "$CONTENTS/lib"
cp "$CLI_STAGING/bundle/bin/$EXE_NAME" "$CONTENTS/MacOS/$EXE_NAME"
cp "$CLI_STAGING/bundle/lib/"*.dylib "$CONTENTS/lib/"
cp macos_bundle/Info.plist "$CONTENTS/Info.plist"
printf 'APPL????' > "$CONTENTS/PkgInfo"
chmod +x "$CONTENTS/MacOS/$EXE_NAME"

echo "Built: $APP_DIR"
echo "Run:"
echo "  $CONTENTS/MacOS/$EXE_NAME"
echo ""
echo "Apple may still require a GUI app (NSApplication) for the speech prompt in"
echo "some configurations; if the process aborts, use an Xcode macOS App target."
echo ""
echo "Optional ad-hoc sign:"
echo "  codesign -s - --force --deep \"$APP_DIR\""
