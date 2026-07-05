// ===============================================================
// app_constants.dart
// ---------------------------------------------------------------
// Global application constants
//
// SAFE TO STORE
// ---------------------------------------------------------------
// ✅ API URLs
// ✅ Script IDs
// ✅ Spreadsheet IDs
// ✅ Razorpay public key
//
// DO NOT STORE
// ---------------------------------------------------------------
// ❌ Razorpay key secret
// ❌ Private tokens
// ===============================================================

import 'package:flutter/material.dart';

class AppConstants {
  // =============================================================
  // APPLICATION INFO
  // =============================================================

  static const String appName = 'SHRD Shuttle Booking';

  // =============================================================
  // GOOGLE APPS SCRIPT CONFIG - PRODUCTION
  // =============================================================

  static const String scriptId = 'AKfycbwIZE9kQ5ONEJB8ejsHknLWyllNL2pQAR8Q2lioo7KG8c4D2CW5LCO5JwZOF_rK7Ztq';

  static const String spreadsheetId = '1AFyDz6GsimoI8CTXJYMI81W8VhyZDtRC6xLvT8_tbJE';

  // =============================================================
  // GOOGLE APPS SCRIPT CONFIG - STAGING
  // =============================================================

  // static const String scriptId = 'AKfycby-ipJy8giLt4C-jO-HAryu8swwVnseJo7Y0D7uF0Bn2ExlCrJgsbiSnEcthNalj6oXnw';

  // static const String spreadsheetId = '1-mF84tkEqDumCUKXUxybqRf8ewYrXCkcqq4gE0-c3rg';

  // =============================================================
  // API ENDPOINT - PRODUCTION
  // =============================================================

  static const String apiUrl =  'https://script.google.com/macros/s/AKfycbwIZE9kQ5ONEJB8ejsHknLWyllNL2pQAR8Q2lioo7KG8c4D2CW5LCO5JwZOF_rK7Ztq/exec';

  // =============================================================
  // API ENDPOINT - STAGING
  // =============================================================

  // static const String apiUrl = 'https://script.google.com/macros/s/AKfycby-ipJy8giLt4C-jO-HAryu8swwVnseJo7Y0D7uF0Bn2ExlCrJgsbiSnEcthNalj6oXnw/exec';

  // =============================================================
  // RAZORPAY CONFIG - TEST
  // =============================================================

  // static const String razorpayKeyId = 'rzp_test_SToJcqhAImfHOY';

  // =============================================================
  // RAZORPAY CONFIG - LIVE
  // =============================================================

    static const String razorpayKeyId = 'rzp_live_STnSll8AkTlMTl';

  // =============================================================
  // APPLICATION COLORS
  // =============================================================

  static const Color primaryColor = Color(0xff6B46C1);
  static const Color backgroundColor = Color(0xfff5f5f5);
  static const Color footerColor = Color(0xff5A3DB4);
  static const Color whiteColor = Colors.white;
  static const Color blackColor = Colors.black;
}