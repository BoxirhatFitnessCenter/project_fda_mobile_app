# project_fda_mobile_app

A minimal Flutter app using Firebase Authentication and Realtime Database to send real-time GPS coordinates under `locations/{uid}/{timestamp}`.

## Features
- Email/Password login (Firebase Auth)
- Start/Stop buttons to control live GPS streaming
- Writes to Realtime Database at `locations/{uid}/{timestamp}` → `{ latitude, longitude, readableTimestamp }`
- Splash screen auto-routes based on auth
- Logout from Home screen

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
locations/{uid}/{timestamp}: { latitude, longitude, readableTimestamp }
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
```

And inside `<application>` ensure internet:
```xml
<uses-permission android:name="android.permission.INTERNET" />
```

> Note: For Android 10+ background location requires additional permission and compliance. This sample tracks while app is foreground using a stream. Do not add background location permissions unless necessary for your use case.

### 4) Run
```bash
flutter run
```

## Where to add credentials
- Replace placeholders in `android/app/google-services.json` with the file from Firebase console.
- Ensure the Android `applicationId` matches the package name used to register the app in Firebase.

## Code Structure
- `lib/main.dart`: Firebase init, routes
- `lib/pages/splash_page.dart`: Splash routing based on `authStateChanges()`
- `lib/pages/login_page.dart`: Email/password login & register
- `lib/pages/home_page.dart`: Start/Stop sending GPS; Logout

## Notes
- Geolocator handles permission prompts; we also check and provide status feedback in UI.
- Timestamps are stored as the node key (milliseconds since epoch) and a human-readable ISO string (`readableTimestamp`).
- If you need background updates, consider a background service or WorkManager; this sample focuses on foreground live tracking.
