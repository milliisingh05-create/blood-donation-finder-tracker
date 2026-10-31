# Blood Donation Finder & Tracker 🩸

> **Enterprise-Ready Flutter + Firebase Application**  
> *Connecting Donors, Patients, and Hospitals in Real-Time During Critical Medical Emergencies.*

[![Flutter](https://img.shields.io/badge/Flutter-3.38.1-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.10.0-0175C2?logo=dart)](https://dart.dev)
[![Architecture](https://img.shields.io/badge/Architecture-Riverpod%203.0%20+%20GoRouter-red)](https://riverpod.dev)
[![Tests](https://img.shields.io/badge/Tests-Passing%20(100%25)-2ECC71)](test/)
[![Design System](https://img.shields.io/badge/Design%20System-Flat%20Light--Red%20(Zero%20Gradients)-FF4B5C)](lib/core/theme/)
[![Maps](https://img.shields.io/badge/Maps-Dual--Engine%20(Google%20Maps%20+%20OSM%20Fallback)-orange)](lib/core/widgets/)

---

## 🌟 Overview & Mission

In traumatic emergencies, surgeries, and critical care units, immediate access to compatible blood is the deciding factor between life and death. 

Traditional blood search workflows rely on fragmented phone calls, delayed group broadcasts, and opaque hospital inventories. Voluntary donors frequently face privacy invasion through unregulated phone number exposure, while recipients lose vital minutes traveling to facilities with depleted stock.

**Blood Donation Finder & Tracker** provides an end-to-end, high-reliability platform that bridges donors, recipients, and healthcare providers:
- **Instant Emergency SOS Broadcast**: Rapid expanding geofence alert system ($5\text{ km} \to 10\text{ km} \to 25\text{ km}$) with sustained-hold trigger.
- **Privacy-First Handshake**: Strict contact shielding until a donation request is explicitly accepted by the voluntary donor.
- **Dual-Engine Mapping**: Zero-downtime location mapping with automatic OpenStreetMap fallback whenever Google Maps API keys are absent.
- **Live Hospital Stock Matrix**: Real-time units tracking across all 8 blood groups with immediate shortage alerts ($<3\text{ units}$) and hospital staff updates.
- **90-Day Medical Eligibility Tracker**: Clinical interval enforcement, lifelong impact metrics, and gamified recognition.

---

## 🎨 Design Philosophy: Flat Light-Red (Zero Gradients)

The application enforces a **Strict Flat-Color Design System** across all platforms (Mobile, Tablet, Web, Desktop):
- **Zero Gradients**: No `LinearGradient`, `RadialGradient`, or `SweepGradient` are permitted anywhere in the UI.
- **Curated Palette**:
  - **Primary Red** (`#FF4B5C`): Urgent, vibrant, recognizable.
  - **Primary Dark** (`#E63946`): Interactive press states, high-contrast borders, key callouts.
  - **Light Red Tint** (`#FFE3E6`): Gentle chip containers, badge backgrounds, and secondary highlights.
  - **Canvas Background** (`#FFF6F7`): Warm, soft off-white red tint designed to reduce visual fatigue.
  - **Surface** (`#FFFFFF`): Cards, sheets, and elevated overlays.
  - **Text Primary** (`#2B1A1C`): Deep charcoal burgundy for sharp legibility.
  - **Text Secondary** (`#7A5C60`): Muted supportive typography.
  - **Status Tokens**: Success (`#2ECC71`), Shortage/Warning (`#FFB020`), Inactive/Cooldown (`#B8AEB0`).
- **LifeLine Animated Engine**: Custom 60fps vector painter featuring falling blood droplets, real-time synchronized ECG heartbeat pulse lines, and subtle ripples.

---

## 📦 Core Architecture & Feature Modules

```
lib/
├── core/
│   ├── constants/       # App-wide strings and dimension tokens
│   ├── data/            # Seed data and mock repositories for local development
│   ├── router/          # GoRouter configuration & route paths
│   ├── theme/           # AppColors, AppTheme, and Typography
│   └── widgets/         # LifeLineBackground, AppErrorWidget, Dual-engine AppMapView, Buttons, Badges
└── features/
    ├── auth/            # AuthRepository, Login, Register, Forgot Password, Phone OTP
    ├── dashboard/       # Stat cards, Availability switch, Quick Actions, Emergency hero
    ├── donations/       # 90-day medical interval countdown, milestone badges, logging
    ├── donor_finder/    # GPS map view, radius filtering, blood group compatibility filter
    ├── hospitals/       # Blood bank inventory matrix, shortage indicators, staff stock adjustments
    ├── leaderboard/     # Community donor rankings, top-3 podium, points leaderboard
    ├── notifications/   # In-app alerts, FCM push notifications, native system notification channels
    ├── onboarding/      # First-launch walkthrough & permissions explanation
    ├── profile/         # Donor profile, badges showcase, settings
    ├── requests/        # Blood request creation, incoming/created inbox tabs
    └── sos/             # Emergency SOS 2-second hold trigger, expanding radar visualizer
```

### 1. Authentication & Security
- Email/Password authentication with strong credential validation.
- Phone number verification with OTP challenge and simulated fallback.
- Automatic session restoration with Riverpod state listeners.
- Production-grade Cloud Firestore security rules with granular read/write privileges.

### 2. Privacy-Gate Handshake
- **Public Discovery**: When searching for nearby donors, only approximate distance, blood type, and availability status are rendered.
- **Contact Shielding**: Phone numbers and exact addresses remain hidden behind `PrivacyGateDialog`.
- **Mutual Handshake**: Contact details and direct native dialer (`tel:`) capabilities are unlocked only when the donor accepts a specific donation request.

### 3. Dual-Engine Map (Zero-Config Fallback)
- Automatically initializes **Google Maps SDK** on mobile if valid API keys are configured.
- Seamlessly falls back to **`flutter_map` + OpenStreetMap** on Web, Desktop, or devices lacking Google Play Services.
- Displays custom teardrop blood pins and radius search perimeters without third-party billing blockers.

### 4. Emergency SOS Engine
- 2-second sustained hold button with circular progress indicator and haptic feedback to prevent accidental triggers.
- Live animated radar view showing automated distance expansion ($5\text{ km} \to 10\text{ km} \to 25\text{ km}$).
- Broadcast dispatch notifying eligible matching donors within the active search radius.

### 5. Hospital Inventory Matrix & Staff Authorization
- Real-time stock status across all 8 blood groups (A+, A-, B+, B-, AB+, AB-, O+, O-).
- Automated shortage alerts when inventory drops below 3 units.
- Role-based authorization (`isStaffOrAdmin`) protecting direct blood bank inventory modifications.

### 6. Medical Eligibility & Lifelong Impact
- Clinically accurate 90-day cooldown timer for whole blood donations.
- Clinical safety validation enforcing minimum 45 kg donor weight and 18+ age requirement.
- Milestone badge achievements (First Drop, Lifesaver, Golden Heart, Century Donor).
- Lifelong volume tracking and estimated lives saved calculation.

### 7. Community Donor Leaderboard
- Real-time points standings and community rankings.
- Top-3 podium display with Gold, Silver, and Bronze tier badges.
- Category filtering for universal O- donors.
- Sticky footer tracking the active donor's standing.

### 8. Native Notification Channels & Error Boundary
- Native Android notification channels (`emergency_sos_channel` max priority, `general_alerts_channel`).
- Production `AppErrorWidget` graceful recovery interface preventing unexpected rendering crashes.

---

## 🚀 Getting Started

### Prerequisites
- **Flutter SDK**: `>= 3.10.0` (Tested on `3.38.1` • Dart `3.10.0`)
- **Platforms**: Android (API 23+), iOS (12+), Web (Chrome/Edge/Firefox), macOS, Linux, Windows.

### Installation

1. **Clone the repository**:
   ```bash
   git clone https://github.com/org-blooddonation/blood-donation-tracker.git
   cd blood-donation-tracker
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Verify static analysis**:
   ```bash
   flutter analyze
   ```

4. **Execute test suite**:
   ```bash
   flutter test
   ```

5. **Run the application**:
   ```bash
   # Web
   flutter run -d chrome

   # Mobile (Android/iOS)
   flutter run

   # Windows Desktop
   flutter run -d windows
   ```

---

## ⚙️ Configuration & Environment

### Firebase Setup
1. Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com).
2. Enable **Authentication** (Email/Password & Phone).
3. Enable **Cloud Firestore** and deploy the rules:
   ```bash
   firebase deploy --only firestore:rules
   ```
4. Run `flutterfire configure` to generate updated `firebase_options.dart`.

### Offline & Development Mode
When Firebase credentials are not yet configured or when running in offline testing environments:
- The app automatically initializes local in-memory repositories populated with verified seed data.
- All core workflows (Donor Finder, Emergency SOS, Stock Matrix, Donation Logging) remain fully testable without network requirements.

---

## 🧪 Testing

The repository maintains full unit, widget, and integration coverage across all core features:

```bash
# Run all tests
flutter test

# Run tests with coverage reporting
flutter test --coverage
```

Test suites verify:
- Blood compatibility matrix logic (Universal donors & recipients).
- Emergency SOS hold-to-activate timer and radar expansions.
- Privacy gate contact shielding behavior.
- Hospital inventory increment/decrement validation.
- Flat light-red theme and zero-gradient enforcement.

---

## 📄 License & Contribution

This project is open-source under the MIT License. Contributions from healthcare professionals, software engineers, and voluntary donors are welcome.
