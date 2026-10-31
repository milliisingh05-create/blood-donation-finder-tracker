# Deployment & Operations Guide 🚀

This document covers end-to-end instructions for deploying **Blood Donation Finder & Tracker** to production across Android, iOS, Web, and Cloud Firestore.

---

## 1. Firebase Project Setup

### 1.1 Create Project
1. Navigate to the [Firebase Console](https://console.firebase.google.com).
2. Create a new project (e.g. `blood-donation-tracker-prod`).
3. Enable **Google Analytics** (recommended for crash and emergency broadcast metrics).

### 1.2 Enable Authentication Providers
In **Authentication > Sign-in method**:
1. Enable **Email/Password**.
2. Enable **Phone**:
   - Add testing phone numbers and verification codes under **Phone numbers for testing** if needed.
   - For Android, add your SHA-1 and SHA-256 fingerprint from `./gradlew signingReport`.

### 1.3 Deploy Cloud Firestore Rules & Indexes
Install the Firebase CLI:
```bash
npm install -g firebase-tools
firebase login
firebase use --add
```

Deploy the verified production security rules and compound indexes:
```bash
firebase deploy --only firestore:rules,firestore:indexes
```

---

## 2. Cloud Messaging & Notification Channels

### 2.1 Android Setup
1. In `android/app/`, ensure `google-services.json` is present.
2. In Google Cloud Console, ensure the **Firebase Cloud Messaging API (V1)** is enabled.
3. The app automatically registers the following notification channels upon first boot:
   - `emergency_sos_channel`: High-importance Heads-Up alert with vibration and sound.
   - `general_alerts_channel`: Default importance for badges and donation reminders.

### 2.2 iOS Setup
1. In `ios/Runner/`, ensure `GoogleService-Info.plist` is present.
2. In Apple Developer Console, enable **Push Notifications** and generate an **APNs Key (.p8)**.
3. Upload the APNs Key to **Firebase Console > Project Settings > Cloud Messaging > Apple app configuration**.

---

## 3. Maps Configuration (Dual-Engine)

The app is built with a **Dual-Engine Map** architecture:
- **No API Key**: Automatically falls back to **OpenStreetMap** with custom teardrop blood pins. No billing or configuration required.
- **Google Maps (Optional)**:
  - Obtain an API key from [Google Cloud Console](https://console.cloud.google.com) with **Maps SDK for Android** and **Maps SDK for iOS** enabled.
  - Set the key via environment variable:
    ```bash
    flutter run --dart-define=MAPS_API_KEY=YOUR_KEY_HERE
    ```
  - For Android release, supply `MAPS_API_KEY` in `android/local.properties` or CI secrets.

---

## 4. Building Production Artifacts

### 4.1 Web Deployment (Firebase Hosting)
```bash
# 1. Compile web release bundle
flutter build web --no-tree-shake-icons

# 2. Deploy to Firebase Hosting
firebase deploy --only hosting
```

### 4.2 Android Release (AAB / APK)
```bash
# Generate signed App Bundle for Google Play Store
flutter build appbundle --release

# Or generate universal APK for testing
flutter build apk --release
```
The output file will be located at:
`build/app/outputs/bundle/release/app-release.aab`

### 4.3 iOS Release (IPA)
```bash
flutter build ipa --release
```
Open `ios/Runner.xcworkspace` in Xcode to archive and submit to TestFlight / App Store.

---

## 5. Continuous Integration (GitHub Actions)

The repository includes a ready-to-run GitHub Actions workflow at [.github/workflows/flutter_ci.yml](../.github/workflows/flutter_ci.yml).
On every push or pull request to `main`, it automatically:
1. Validates code formatting and static analysis (`flutter analyze --fatal-infos`).
2. Runs all 102 automated tests (`flutter test --coverage`).
3. Enforces the strict zero-gradient design system.
4. Compiles the production Web bundle and Android debug APK.
