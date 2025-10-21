# project_fda_mobile_app

A Flutter app with Firebase Authentication and Realtime Database to send real-time GPS coordinates under `locations/{uid}/{timestamp}`. **Now supports background location tracking!**

## Features
- Email/Password login (Firebase Auth)
- **Foreground location tracking** - Real-time GPS streaming while app is open
- **Background location tracking** - Continues sharing location every 30 seconds even when app is closed
- Writes to Realtime Database at `locations/{uid}/{timestamp}` → `{ latitude, longitude, readableTimestamp, source }`
- Splash screen auto-routes based on auth
- Logout from Home screen
- Persistent notification during background tracking

## Setup

### 1) Flutter & Dependencies
- Install Flutter SDK and Android Studio/SDK tools
- In this folder, run:

```bash
flutter pub get
```

### 2) Firebase Project
- Create a Firebase project
- Enable Authentication → Email/Password
- Create a Realtime Database (in test mode for development)

Database path example:
```
locations/{uid}/{timestamp}: { latitude, longitude, readableTimestamp, source }
```

### 3) Android Setup
- Add Android app in Firebase console using your Android package name (example: `com.example.project_fda_mobile_app`)
- Download `google-services.json` from Firebase console and place it at:
  - `android/app/google-services.json` (replace the example file in this repo)

- In `android/build.gradle` add in `buildscript` dependencies:
```gradle
classpath 'com.google.gms:google-services:4.4.2'
```

- In `android/app/build.gradle` apply plugin at the bottom:
```gradle
apply plugin: 'com.google.gms.google-services'
```

- In `android/app/src/main/AndroidManifest.xml` add permissions inside `<manifest>`:
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_LOCATION" />
<uses-permission android:name="android.permission.WAKE_LOCK" />
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
```

And inside `<application>` ensure internet:
```xml
<uses-permission android:name="android.permission.INTERNET" />
```

> Note: For Android 10+ background location requires additional permission and compliance. This app handles background location with proper permissions and notifications.

### 4) Run
```bash
flutter run
```

## Where to add credentials
- Replace placeholders in `android/app/google-services.json` with the file from Firebase console.
- Ensure the Android `applicationId` matches the package name used to register the app in Firebase.

## Code Structure
- `lib/main.dart`: Firebase init, routes, background service init
- `lib/pages/splash_page.dart`: Splash routing based on `authStateChanges()`
- `lib/pages/login_page.dart`: Email/password login & register
- `lib/pages/home_page.dart`: Start/Stop foreground/background GPS; Logout
- `lib/services/background_location_service.dart`: Background service for location tracking

## Background Location Tracking

### How it works:
1. **Start Background** button starts a background service
2. Service runs independently of the app
3. Sends location updates every 30 seconds to Firebase
4. Shows persistent notification while tracking
5. Continues even when app is closed or phone is locked

### Database Structure:
```json
{
  "locations": {
    "driverId": {
      "timestamp": {
        "latitude": 40.7128,
        "longitude": -74.0060,
        "readableTimestamp": "2024-01-01T12:00:00.000Z",
        "source": "background_service" // or "foreground"
      }
    }
  }
}
```

### Battery Optimization:
- Users may need to disable battery optimization for the app
- Android will show a notification during background tracking
- Service automatically handles location permission requests

## Notes
- Geolocator handles permission prompts; we also check and provide status feedback in UI.
- Timestamps are stored as the node key (milliseconds since epoch) and a human-readable ISO string (`readableTimestamp`).
- Background tracking uses `flutter_background_service` for reliable location sharing.
- Source field indicates whether location came from foreground or background service.