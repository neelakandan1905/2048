#!/usr/bin/env bash
set -euo pipefail

# Run from the project root on a Mac with Flutter + Android SDK installed.
flutter pub get
flutter test
flutter build apk --release
printf '\nAPK: %s\n' "$(pwd)/build/app/outputs/flutter-apk/app-release.apk"
