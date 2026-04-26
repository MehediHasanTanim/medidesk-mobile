# Runbook: Release

→ [Back to runbooks](README.md)

Build a signed release binary and submit to the App Store or Play Store.

---

## Pre-Release Checks

Run all checks from `medidesk/` before building:

```bash
flutter analyze                   # zero issues
flutter test                      # all tests pass
flutter pub run build_runner build --delete-conflicting-outputs  # generated files current
```

Confirm in `pubspec.yaml`:
- [ ] `version` is bumped: `<semver>+<build-number>` (e.g., `1.1.0+5`)
- [ ] `environment.flutter` constraint is still satisfied by the build machine's Flutter version

---

## Android — Release APK / AAB

```bash
cd medidesk

# App Bundle (recommended for Play Store)
flutter build appbundle --release

# APK (for direct distribution or testing)
flutter build apk --release --split-per-abi
```

Output locations:
- AAB: `build/app/outputs/bundle/release/app-release.aab`
- APK: `build/app/outputs/apk/release/`

**Signing:** keystore must be configured in `android/key.properties` (never committed).  
`android/app/build.gradle.kts` reads signing config from `key.properties`.

---

## iOS — Archive and Upload

```bash
cd medidesk
flutter build ipa --release
```

Output: `build/ios/ipa/*.ipa`

Then open Xcode Organizer (`Window → Organizer`) to validate and upload, or use `xcrun altool`:

```bash
xcrun altool --upload-app \
  --type ios \
  --file "build/ios/ipa/medidesk.ipa" \
  --username "$APPLE_ID" \
  --password "$APP_SPECIFIC_PASSWORD"
```

**Signing:** requires a valid distribution certificate and provisioning profile in Xcode / Apple Developer account.

---

## Version Bump Checklist

- [ ] `pubspec.yaml` version incremented
- [ ] Both Android (`versionCode` via build number) and iOS (`CFBundleVersion`) align
- [ ] Release notes drafted (what changed for the user)
- [ ] Internal testing (TestFlight / internal track) verified before external submission

---

## Post-Release

Within 1 hour of going live:
- [ ] Verify the app is downloadable from the store
- [ ] Run a smoke test on a fresh install (no cached local data):
  - Login works
  - Patient list loads
  - Appointment booking completes
  - Sync status badge clears after network request
- [ ] Monitor crash reporting for the first 30 minutes

If a critical issue is found after release, use [Incident Response](incident-response.md).

---

## Environment Configuration

`AppConfig` reads the base URL from compile-time constants. Set the correct environment before building:

```bash
# Production
flutter build appbundle --release --dart-define=ENV=production

# Staging (for internal testing builds)
flutter build appbundle --release --dart-define=ENV=staging
```

Confirm `AppConfig.current.baseUrl` points to the correct backend before submitting to stores.
