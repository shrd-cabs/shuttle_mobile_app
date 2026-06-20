# SHRD Mobile App

Mobile application for **Shri Radhey Travel Services (SHRD)**.

The mobile application uses the same backend as the existing SHRD Web Application.

---

# Project Information

- Project Name: SHRD
- Company: Shri Radhey Travel Services
- Mobile Repository: https://github.com/shrd-cabs/shuttle_mobile_app
- Backend: Google Apps Script
- Database: Google Sheets
- Framework: Flutter
- Language: Dart
- Version: 1.0.0+1

---

# Current Development Status

## Environment Setup

Completed:

- Flutter installed and configured
- Dart SDK installed
- Android Studio installed
- Android Emulator configured
- GitHub repository connected
- Hot Reload working
- Release APK generation working
- Physical Android device testing working

---

## Authentication Module

Completed:

- Login Screen
- Signup Screen
- Forgot Password
- Header Widget
- Footer Widget
- SHRD Branding
- API Integration

---

## Backend Integration

Completed:

- Google Apps Script integration
- Login API working
- Signup API working
- Forgot Password API working

Backend Flow:

Flutter App
↓
Google Apps Script
↓
Google Sheets

---

# Current Folder Structure

```
shuttle_mobile_app
│
├── android/
├── ios/
├── assets/
│   ├── images/
│   └── icons/
│
├── lib/
│   │
│   ├── core/
│   │   ├── constants/
│   │   └── theme/
│   │
│   ├── services/
│   │   └── auth_service.dart
│   │
│   ├── screens/
│   │   ├── auth/
│   │   │   ├── auth_screen.dart
│   │   │   └── widgets/
│   │   │       ├── header_widget.dart
│   │   │       ├── login_form_widget.dart
│   │   │       ├── signup_form_widget.dart
│   │   │       └── footer_widget.dart
│   │   │
│   │   └── dashboard/
│   │
│   └── main.dart
│
├── pubspec.yaml
├── .gitignore
└── README.md
```

---

# API Configuration

Google Apps Script Production Endpoint:

```dart
https://script.google.com/macros/s/AKfycbwIZE9kQ5ONEJB8ejsHknLWyllNL2pQAR8Q2lioo7KG8c4D2CW5LCO5JwZOF_rK7Ztq/exec
```

Current App Constants:

```dart
class AppConstants {
  static const String apiUrl =
      'https://script.google.com/macros/s/AKfycbwIZE9kQ5ONEJB8ejsHknLWyllNL2pQAR8Q2lioo7KG8c4D2CW5LCO5JwZOF_rK7Ztq/exec';
}
```

---

# App Branding

App Name:

```
SHRD
```

Header Title:

```
SHRD Shuttle Booking
```

Company Name:

```
Shri Radhey Travel Services
```

Logo Location:

```
assets/images/logo.jpeg
```

---

# Running the App on Android Emulator

## Step 1

Start Emulator.

Check available devices:

```bash
flutter devices
```

Expected Output:

```bash
emulator-5554
```

---

## Step 2

Run Application:

```bash
flutter run -d emulator-5554
```

---

## Hot Reload

While app is running:

```bash
r
```

Hot Restart:

```bash
R
```

Quit:

```bash
q
```

---

# Running on Physical Android Device

## Step 1

Enable Developer Options.

Enable:

- USB Debugging

---

## Step 2

Connect device using USB.

Check device:

```bash
flutter devices
```

Expected Output:

```bash
Your device name
```

---

## Step 3

Run:

```bash
flutter run
```

---

# Build Release APK

Generate APK:

```bash
flutter build apk --release
```

APK Location:

```text
build/app/outputs/flutter-apk/app-release.apk
```

---

# Clean and Rebuild

Use this whenever unexpected issues occur.

```bash
flutter clean
flutter pub get
flutter run -d emulator-5554
```

---

# App Updates

To distribute updates through APK:

Update version inside:

```yaml
pubspec.yaml
```

Example:

Old:

```yaml
version: 1.0.0+1
```

New:

```yaml
version: 1.0.1+2
```

Rules:

- First part = User Visible Version
- Second part = Android Build Number
- Build Number must always increase.

Example:

```yaml
1.0.0+1
1.0.1+2
1.0.2+3
1.1.0+4
```

---

# Android Configuration

Android Manifest:

```
android/app/src/main/AndroidManifest.xml
```

Internet Permission:

```xml
<uses-permission android:name="android.permission.INTERNET" />
```

App Label:

```xml
android:label="SHRD"
```

---

# GitHub Workflow

Check Status:

```bash
git status
```

Add Files:

```bash
git add .
```

Commit:

```bash
git commit -m "Commit Message"
```

Push:

```bash
git push
```

Pull Latest:

```bash
git pull
```

---

# Important Files to Protect

Never commit:

```
android/key.properties
*.jks
*.keystore
*.p12
*.pem
.env
.env.*
```

---

# Completed Milestones

Completed:

- Flutter Setup
- Android Setup
- Emulator Setup
- GitHub Setup
- Physical Device Setup
- SHRD Branding
- Authentication UI
- Login API
- Signup API
- Forgot Password API
- APK Generation
- APK Installation
- Production Git Ignore

---

# Next Development Phase

Planned Modules:

1. Auto Login
2. Main Post Login Screen
3. Booking Screen
4. Search Routes
5. Seat Selection
6. Booking Confirmation
7. Wallet Integration
8. My Trips
9. Travel Pass
10. Profile
11. Notifications
12. iOS Support
13. Play Store Release

---

# Project Vision

Build a production-ready shuttle booking ecosystem consisting of:

- Web Application
- Android Application
- iOS Application
- Google Apps Script Backend
- Google Sheets Database
- Admin Portal
- Driver/Captain Portal

under a single SHRD ecosystem.