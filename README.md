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

## Settings
Open with the gear icon. The page follows the device: iOS Settings style (grouped lists, checkmarks, iOS alerts) on iPhone/iPad/Mac, including Safari on iPhone; Material settings (list rows with radio-button dialogs) on Android. Saved separately from the game (`settings_v1`).
- **Difficulty** — changing it restarts the game (with a confirmation once a move has been made):
  - Easy: new tiles are 2 or 4 at random (50/50), 3 free undos.
  - Medium: classic spawns (90% 2s), 1 free undo.
  - Hard: classic spawns, no free undos, every 4th move drops two tiles.
- **Theme** — Automatic / System default (follows the phone), Light or Dark. Applies immediately.
- **Tile colours** — Warm sunset, Ocean cool or Vibrant rainbow. Applies immediately.
- **Sound** — on/off. Applies immediately.

## Notes
- Offline game state uses `SharedPreferencesAsync`.
- Five-step board/score undo history is stored with the game state.
- No backend is required.

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
Then open `http://<your-mac-ip>:8090` on the phone. `FREE_REWARDS=true` grants the rewarded power-ups without ads (test builds only). Add `?debug=1` to the URL to print the phone's sound diagnostics in the server's terminal.

On the web, sound and vibration come from `web/feedback.js` (browsers only allow them inside a touch event). iOS Safari has no vibration API; iOS 18+ gets a haptic tick through a hidden switch control.

## Dev environment (GitHub Pages)
Every push to the `dev` branch runs the tests, builds the web app and publishes it to the `gh-pages` branch (`.github/workflows/deploy-dev.yml`). It is served at **https://neelakandan1905.github.io/2048/**; `build.txt` there shows the deployed commit. Add `?debug=1` to show sound diagnostics on screen.

## VS Code
Install the Flutter extension, then use **Run and Debug → "2048 (Chrome)"** (`.vscode/launch.json`).
