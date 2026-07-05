// ===============================================================
// main.dart
// ---------------------------------------------------------------
// Application Entry Point
//
// PURPOSE
// ---------------------------------------------------------------
// Initializes SHRD app and restores saved login session.
// ===============================================================

import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'screens/auth/auth_screen.dart';
import 'screens/main/main_content_screen.dart';
import 'services/storage_service.dart';

void main() {
  runApp(const ShuttleApp());
}

class ShuttleApp extends StatelessWidget {
  const ShuttleApp({super.key});

  Future<bool> checkLoginStatus() async {
    try {
      return await StorageService().isLoggedIn();
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SHRD',
      theme: AppTheme.theme,
      home: FutureBuilder<bool>(
        future: checkLoginStatus(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          if (snapshot.hasError || snapshot.data != true) {
            return const AuthScreen();
          }

          return const MainContentScreen();
        },
      ),
    );
  }
}