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
    return StorageService().isLoggedIn();
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
          if (!snapshot.hasData) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          return snapshot.data == true
              ? const MainContentScreen()
              : const AuthScreen();
        },
      ),
    );
  }
}