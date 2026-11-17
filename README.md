# 2048 — Flutter

OLED-first 2048 puzzle game for Android and iOS.

## Requirements
- Flutter stable (Dart 3.5+)
- Android Studio / Xcode
- Android minSdk 24

## Run
```bash
flutter pub get
flutter test
flutter run
```
Tests cover the game engine, the controller (undo/win, Clear 2s, saved lost games), the game-over dialog after a restart, and touch swipes.

## Build Android APK
```bash
flutter build apk --release
```
APK: `build/app/outputs/flutter-apk/app-release.apk`

## AdMob
The project uses Google's official Android test app/ad unit IDs. Replace all test IDs before production release. Android app ID is in `android/app/src/main/AndroidManifest.xml`; iOS app ID is in `ios/Runner/Info.plist`.

Rewarded actions are granted only from `onUserEarnedReward`. The interstitial cooldown timestamp is persisted locally.

## Notes
- Offline game state uses `SharedPreferencesAsync`.
- Five-step board/score undo history is stored with the game state.
- No backend is required.
- Add sound assets under `assets/audio/` and declare them in `pubspec.yaml` to enable audio playback.

## Web and phone testing
Ads only run on Android/iOS; on web they are skipped. Keyboard (arrows / WASD) and swipes both work.

```bash
flutter run -d chrome
```

To test on a phone over Wi-Fi, build a release web version and serve it on the local network:
```bash
flutter build web --release --dart-define=FREE_REWARDS=true
python3 tools/serve_web.py 8090
```
Then open `http://<your-mac-ip>:8090` on the phone. `FREE_REWARDS=true` grants the rewarded power-ups without ads (test builds only). Add `?debug=1` to the URL to print the phone's sound/vibration diagnostics in the server's terminal.

On the web, sound and vibration come from `web/feedback.js` (browsers only allow them inside a touch event). iOS Safari has no vibration API; iOS 18+ gets a haptic tick through a hidden switch control.

## Dev environment (GitHub Pages)
Every push to the `dev` branch runs the tests, builds the web app and publishes it to the `gh-pages` branch (`.github/workflows/deploy-dev.yml`). It is served at **https://neelakandan1905.github.io/2048/**; `build.txt` there shows the deployed commit. Add `?debug=1` to show sound/vibration diagnostics on screen.

## VS Code
Install the Flutter extension, then use **Run and Debug → "2048 (Chrome)"** (`.vscode/launch.json`).
