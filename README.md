# 🚌 VCE Bus Tracking System

A real-time college bus tracking app built with **Flutter** and **Firebase**. Students can track buses live on a map, and designated drivers can broadcast their GPS location — all in real-time.

---

## ✨ Features

- **🔐 Authentication** — Email/password signup & login via Firebase Auth
- **🚌 Bus Listing** — View all college buses with live Active/Idle status
- **🚗 Driver Mode** — Claim a bus and broadcast GPS location in real-time (one driver per bus)
- **📍 Tracker Mode** — Track a bus live on Google Maps with route directions
- **🗺️ Google Maps Integration** — Directions, walking navigation, and route visualization
- **🛡️ Admin Panel** — Manage buses and routes
- **⚡ Real-time Updates** — Powered by Cloud Firestore real-time listeners

---

## 📁 Project Structure

```
lib/
├── main.dart                        # App entry point, Firebase init, auth routing
├── firebase_options.dart            # Auto-generated Firebase config (gitignored)
├── models/
│   ├── bus_model.dart               # Bus data model with Firestore serialization
│   └── bus_stop_model.dart          # Bus stop data model
├── services/
│   ├── auth_service.dart            # Firebase Auth wrapper (sign in/up/out)
│   └── firestore_service.dart       # Firestore CRUD, bus claiming, GPS streams
├── screens/
│   ├── login_screen.dart            # Login UI
│   ├── signup_screen.dart           # Signup UI
│   ├── bus_list_screen.dart         # List of all buses with status
│   ├── driver_mode_screen.dart      # Driver GPS broadcasting screen
│   ├── tracker_screen.dart          # Live bus tracking map (student view)
│   ├── admin_login_screen.dart      # Admin authentication
│   └── admin_panel_screen.dart      # Admin bus/route management
└── widgets/
    └── bus_card.dart                # Reusable bus card widget

assets/
└── map.html                         # Google Maps WebView with JS functions
```

---

## 🛠️ Prerequisites

Before setting up, make sure you have the following installed:

| Tool | Version | Check |
|---|---|---|
| [Flutter SDK](https://docs.flutter.dev/get-started/install) | 3.10+ | `flutter --version` |
| [Dart SDK](https://dart.dev/get-dart) | 3.10+ | `dart --version` |
| [Android Studio](https://developer.android.com/studio) | Latest | For Android emulator & SDK |
| [Firebase CLI](https://firebase.google.com/docs/cli) | Latest | `npm install -g firebase-tools` |
| [FlutterFire CLI](https://firebase.flutter.dev/docs/cli/) | Latest | `dart pub global activate flutterfire_cli` |
| [Node.js & npm](https://nodejs.org/) | 18+ | `node --version` |

---

## 🚀 Setup Guide

### 1. Clone the Repository

```bash
git clone https://github.com/YOUR_USERNAME/VCE-BusTracking.git
cd VCE-BusTracking
```

### 2. Install Flutter Dependencies

```bash
flutter pub get
```

### 3. Firebase Setup

This project uses Firebase for authentication and real-time database. You need to configure it for your own Firebase project.

#### a) Login to Firebase

```bash
firebase login
```

#### b) Configure FlutterFire

This command auto-generates `google-services.json`, `GoogleService-Info.plist`, and `lib/firebase_options.dart`:

```bash
# If 'flutterfire' is not on your PATH, use the full path:
# Windows: & "$env:LOCALAPPDATA\Pub\Cache\bin\flutterfire.bat" configure --project=YOUR_PROJECT_ID
# macOS/Linux: ~/.pub-cache/bin/flutterfire configure --project=YOUR_PROJECT_ID

flutterfire configure --project=YOUR_PROJECT_ID
```

> **Note:** Replace `YOUR_PROJECT_ID` with your Firebase project ID (e.g., `vce-bustracking`).

#### c) Enable Firebase Services

In the [Firebase Console](https://console.firebase.google.com):

1. **Authentication** → Sign-in method → Enable **Email/Password**
2. **Cloud Firestore** → Create database → Start in **test mode**

#### d) Seed Bus Data in Firestore

Go to Firestore → **+ Start collection** → Collection ID: `buses`

Add documents with these fields:

| Field | Type | Example Value |
|---|---|---|
| `name` | string | `Bus 1` |
| `route` | string | `Ameerpet → VCE College` |

That's all you need — the `activeDriverId`, `lat`, `lng` fields are set automatically by the app.

### 4. Google Maps API Key

This app uses Google Maps JavaScript API and Directions API.

#### a) Get an API Key

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create or select a project
3. Enable these APIs:
   - **Maps JavaScript API**
   - **Directions API**
4. Go to **Credentials** → Create an **API Key**

#### b) Add the Key

**For the WebView map** — open `assets/map.html` and replace the placeholder in the `<script>` tag at the bottom:

```html
<script
    src="https://maps.googleapis.com/maps/api/js?key=YOUR_API_KEY_HERE&libraries=geometry,directions&callback=initMap"
    async defer>
</script>
```

**For Android native** — open `android/app/src/main/AndroidManifest.xml` and replace the API key:

```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_API_KEY_HERE" />
```

> ⚠️ **Do NOT commit your API key to git.** The `map.html` and `AndroidManifest.xml` files contain your key locally. Consider using environment variables or `local.properties` for production.

### 5. Run the App

```bash
# List available emulators
flutter emulators

# Launch an emulator
flutter emulators --launch <emulator_name>

# Run the app
flutter run
```

---

## 📦 Build APK

To generate a release APK:

```bash
flutter build apk --release
```

The APK will be at: `build/app/outputs/flutter-apk/app-release.apk`

---

## 🔑 Gitignored Files (You Must Generate Locally)

These files contain sensitive API keys and are **not** included in the repo:

| File | How to Generate |
|---|---|
| `android/app/google-services.json` | `flutterfire configure` or download from Firebase Console |
| `ios/Runner/GoogleService-Info.plist` | `flutterfire configure` or download from Firebase Console |
| `lib/firebase_options.dart` | `flutterfire configure` |

---

## 🗄️ Firestore Data Model

### `buses` collection

| Field | Type | Description |
|---|---|---|
| `name` | string | Bus display name (e.g., "Bus 1") |
| `route` | string | Route description |
| `activeDriverId` | string \| null | UID of current driver (`null` = idle) |
| `activeDriverName` | string \| null | Display name of current driver |
| `lat` | number \| null | Current latitude (set by driver) |
| `lng` | number \| null | Current longitude (set by driver) |
| `lastUpdated` | timestamp \| null | Last GPS update time |
| `stops` | array | List of route stops with lat/lng |

### `users` collection

| Field | Type | Description |
|---|---|---|
| `email` | string | User email |
| `name` | string | Display name |
| `role` | string | `"student"` or `"driver"` |
| `createdAt` | timestamp | Account creation time |

---

## 🧪 Testing

### On Emulator
```bash
flutter emulators --launch Medium_Phone_API_36.1
flutter run
```

### On Physical Device
1. Enable **Developer Mode** and **USB Debugging** on your Android phone
2. Connect via USB
3. Run `flutter run`

### Testing Driver + Tracker Together
You need **two devices/emulators** running simultaneously:
- **Device 1:** Login as driver → tap "Drive" on a bus
- **Device 2:** Login as student → tap "Track" on the same bus
- The student should see the driver's location moving in real-time

> **Tip:** You can also manually update `lat`/`lng` fields in the Firebase Console to simulate bus movement while testing tracker mode on a single device.

---

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Follow the [Setup Guide](#-setup-guide) to configure Firebase
4. Make your changes
5. Test on an emulator or device
6. Commit (`git commit -m 'Add amazing feature'`)
7. Push (`git push origin feature/amazing-feature`)
8. Open a Pull Request

---

