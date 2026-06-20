// ===============================================================
// app_theme.dart
// ---------------------------------------------------------------
// Global Theme Configuration
//
// PURPOSE
// ---------------------------------------------------------------
// Centralized design system.
//
// This file controls:
//
// 1. Colors
// 2. Text styles
// 3. Input fields
// 4. Buttons
// 5. Card styles
//
// Any future design changes should happen here.
//
// ===============================================================

import 'package:flutter/material.dart';

class AppTheme {

  // ===========================================================
  // COLORS
  // ===========================================================

  static const Color primary = Color(0xff6B46C1);

  static const Color primaryDark = Color(0xff5A3DB4);

  static const Color screenBg = Color(0xffF5F5F5);

  static const Color border = Color(0xffE5E7EB);

  static const Color textDark = Color(0xff111111);

  static const Color textMedium = Color(0xff555555);

  static const Color buttonBg = Color(0xffF3EDFF);

  // ===========================================================
  // THEME
  // ===========================================================

  static ThemeData get theme {

    return ThemeData(

      useMaterial3: true,

      scaffoldBackgroundColor: screenBg,

      fontFamily: 'Inter',

      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
      ),

      inputDecorationTheme: InputDecorationTheme(

        filled: true,

        fillColor: Colors.white,

        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),

        border: OutlineInputBorder(

          borderRadius: BorderRadius.circular(6),

          borderSide: BorderSide(
            color: border,
          ),

        ),

        enabledBorder: OutlineInputBorder(

          borderRadius: BorderRadius.circular(6),

          borderSide: BorderSide(
            color: border,
          ),

        ),

        focusedBorder: OutlineInputBorder(

          borderRadius: BorderRadius.circular(6),

          borderSide: BorderSide(
            color: primary,
            width: 2,
          ),

        ),

      ),

      elevatedButtonTheme: ElevatedButtonThemeData(

        style: ElevatedButton.styleFrom(

          backgroundColor: primary,

          foregroundColor: Colors.white,

          minimumSize: const Size(
            double.infinity,
            55,
          ),

          shape: RoundedRectangleBorder(

            borderRadius: BorderRadius.circular(6),

          ),

        ),

      ),

    );
  }
}