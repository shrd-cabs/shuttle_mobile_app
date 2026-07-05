# SHRD Mobile App

Mobile application for **Shri Radhey Travel Services (SHRD)**.

The mobile application uses the same backend as the existing SHRD Web
Application.

------------------------------------------------------------------------

# Project Information

-   **Project Name:** SHRD
-   **Company:** Shri Radhey Travel Services
-   **Mobile Repository:**
    https://github.com/shrd-cabs/shuttle_mobile_app
-   **Backend:** Google Apps Script
-   **Database:** Google Sheets
-   **Framework:** Flutter
-   **Language:** Dart
-   **Current Version:** 1.0.1+2

------------------------------------------------------------------------

# Current Development Status

## Environment Setup ✅

-   Flutter installed and configured
-   Dart SDK installed
-   Android Studio installed
-   Android Emulator configured
-   GitHub repository connected
-   Hot Reload working
-   Release APK generation working
-   Physical Android device testing working
-   Razorpay Flutter SDK integrated
-   Production & Staging configuration added

## Authentication Module ✅

-   Login
-   Signup
-   Forgot Password
-   Auto Login
-   Logout
-   Local Session Storage
-   Header & Footer
-   SHRD Branding
-   Google Apps Script Integration

## Dashboard Module ✅

-   Header
-   Wallet Balance
-   Logout
-   Navigation Tabs
-   Booking Screen Routing
-   My Trips Routing
-   Travel Pass Placeholder
-   Live Tracking Placeholder

## Booking Module ✅

-   Search Routes
-   One Way Booking
-   Round Trip Booking
-   Passenger Selection
-   Fare Calculation
-   Hold Booking
-   Payment Summary
-   Wallet Payment
-   Travel Pass Detection
-   Razorpay Booking Integration

## Wallet Module ✅

-   Wallet Balance
-   Wallet Transactions
-   Wallet Dialog
-   Add Money UI
-   Razorpay Wallet Top-up
-   Wallet Verification API
-   Wallet Refresh

## My Trips Module ✅

-   Current Trips
-   Upcoming Trips
-   Past Trips
-   Pull to Refresh
-   Trip Cards
-   Trip Details Dialog
-   Cancellation Policy Dialog
-   Cancellation Preview Dialog
-   Booking Cancellation
-   Wallet Refund Flow
-   Responsive Empty State

## Backend APIs Connected ✅

-   Login
-   Signup
-   Forgot Password
-   Search Routes
-   Wallet Balance
-   Wallet Transactions
-   Applicable Pass
-   Create Hold Booking
-   Wallet Booking Payment
-   Create Wallet Order
-   Verify Wallet Payment
-   My Trips
-   Cancellation Preview
-   Cancel Booking

Backend Flow:

Flutter App

↓

Google Apps Script

↓

Google Sheets

------------------------------------------------------------------------

# Build

``` bash
flutter clean
flutter pub get
flutter run -d emulator-5554
```

Release APK:

``` bash
flutter build apk --release
```

Output:

``` text
build/app/outputs/flutter-apk/app-release.apk
```

------------------------------------------------------------------------

# Completed Milestones

-   Flutter Setup
-   Android Setup
-   Emulator Setup
-   Physical Device Setup
-   APK Generation
-   Authentication
-   Dashboard
-   Booking
-   Wallet
-   Razorpay
-   My Trips
-   Trip Details
-   Cancellation Preview
-   Booking Cancellation
-   Wallet Refund

------------------------------------------------------------------------

# Next Development Phase

1.  Send Ticket Email
2.  Travel Pass Purchase
3.  Live Tracking
4.  Profile
5.  Notifications
6.  iOS Support
7.  Play Store Release
8.  App Store Release

------------------------------------------------------------------------

# Project Vision

Build a production-ready shuttle booking ecosystem consisting of:

-   Web Application
-   Android Application
-   iOS Application
-   Google Apps Script Backend
-   Google Sheets Database
-   Admin Portal
-   Driver/Captain Portal
