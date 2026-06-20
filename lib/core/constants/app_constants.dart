// ===============================================================
// app_constants.dart
// ---------------------------------------------------------------
// Global application constants
//
// PURPOSE
// ---------------------------------------------------------------
// Stores reusable constants used throughout the application.
//
// SAFE TO STORE
// ---------------------------------------------------------------
// ✅ API URLs
// ✅ Application colors
// ✅ App name
// ✅ UI dimensions
//
// DO NOT STORE
// ---------------------------------------------------------------
// ❌ Private keys
// ❌ Secrets
// ❌ Database credentials
// ===============================================================

import 'package:flutter/material.dart';

class AppConstants {

  // =============================================================
  // APPLICATION INFO
  // =============================================================

  static const String appName = 'SHRD Shuttle Booking';

  // =============================================================
  // API CONFIGURATION
  // =============================================================

  static const String apiUrl =
      'https://script.google.com/macros/s/AKfycbwIZE9kQ5ONEJB8ejsHknLWyllNL2pQAR8Q2lioo7KG8c4D2CW5LCO5JwZOF_rK7Ztq/exec';

  // =============================================================
  // APPLICATION COLORS
  // =============================================================

  static const Color primaryColor = Color(0xff6B46C1);

  static const Color backgroundColor = Color(0xfff5f5f5);

  static const Color footerColor = Color(0xff5A3DB4);

  static const Color whiteColor = Colors.white;

  static const Color blackColor = Colors.black;

}