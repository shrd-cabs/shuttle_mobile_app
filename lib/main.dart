// ===============================================================
// main.dart
// ---------------------------------------------------------------
// Application Entry Point
//
// PURPOSE
// ---------------------------------------------------------------
// Initializes the SHRD Shuttle Booking application.
//
// RESPONSIBILITIES
// ---------------------------------------------------------------
//
// 1. Starts Flutter application
// 2. Loads global application theme
// 3. Opens Authentication Screen
//
// NOTES
// ---------------------------------------------------------------
// - AuthScreen is the first screen
// - Future navigation will be handled here
// ===============================================================

import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';

import 'screens/auth/auth_screen.dart';

void main() {

  runApp(const ShuttleApp());

}

class ShuttleApp extends StatelessWidget {

  const ShuttleApp({super.key});

  @override
  Widget build(BuildContext context) {

    return MaterialApp(

      debugShowCheckedModeBanner: false,

      title: 'SHRD',

      theme: AppTheme.theme,

      home: const AuthScreen(),

    );

  }

}