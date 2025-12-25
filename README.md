# Car NFC Admin App

This Flutter application powers an admin experience for creating parking bookings, writing booking details to NFC tags, managing active bookings, and handling mall/slot data backed by Firebase. Use this guide to bootstrap a new local environment after cloning the repository.

## Prerequisites

| Tool / Service | Notes |
| -------------- | ----- |
| [Flutter SDK](https://docs.flutter.dev/get-started/install) | Use Flutter 3.19+ (stable channel recommended). |
| Dart SDK | Bundled with Flutter; verify with `dart --version`. |
| Android Studio or VS Code | For device/emulator management. |
| Xcode (macOS only) | Required to build/run on iOS. |
| Firebase project | Firestore + Authentication enabled. |
| Google Services configs | `android/app/google-services.json` and `ios/Runner/GoogleService-Info.plist`. |

## 1. Clone & Install Dependencies

```bash
git clone <repo-url>
cd flutter_app
flutter pub get
```

If you encounter iOS build issues, ensure CocoaPods is installed and run `pod install` inside `ios/`.

## 2. Configure Firebase

1. Create or reuse a Firebase project.
2. Enable Firestore and Authentication (email/password is sufficient for admin portal access).
3. Download the following files and place them in the repo:
   - `android/app/google-services.json`
   - `ios/Runner/GoogleService-Info.plist`
4. Update Firebase console settings (SHA-1/SHA-256 fingerprints) if you plan to distribute Android builds.

## 3. Environment Setup

- Ensure devices/emulators have NFC hardware enabled if you intend to test tag writing.
- Update any environment-specific constants (API keys, admin IDs) in `lib/` if required.
- Review `docs/manual_nfc_documentation.html` for a deep dive into architecture, NFC flows, and troubleshooting.

## Running the App

```bash
flutter run -d <device_id>
```

Common targets:
- Android emulator / physical device: `flutter run -d android`
- iOS simulator / device: `flutter run -d ios`
- Web (debug only, NFC not supported): `flutter run -d chrome`

During development:
- Use `flutter pub run build_runner build --delete-conflicting-outputs` if you add code generation later.
- Hot reload with `r` in the terminal or IDE buttons.

## Building for Release

### Android
```bash
# Debug APK
flutter build apk

# Play Store bundle
flutter build appbundle
```
Configure `android/key.properties` and signing configs before producing release artifacts.

### iOS
```bash
flutter build ios --release
```
Open the generated Xcode workspace (`ios/Runner.xcworkspace`) to archive and sign builds.

## Useful Scripts & Tips

- Format code: `flutter format lib/`
- Analyze static issues: `flutter analyze`
- Run widget tests: `flutter test`
- NFC testing:
  - Manual booking flow: `ManualBookingScreen` (admin menu)
  - Dedicated NFC write screen: `ManualBookingNfcScreen`
  - Hardware sandbox: `WriteNfcScreen`

## Documentation

Extended technical documentation lives at `docs/manual_nfc_documentation.html`. Open it in a browser for:
- Architecture overview
- Module-by-module descriptions
- NFC implementation details
- Deployment considerations
- PDF export instructions

For questions or onboarding support, contact the project maintainer listed in your internal documentation.
