// ===============================================================
// storage_service.dart
// ---------------------------------------------------------------
// Local Storage Service
//
// PURPOSE
// ---------------------------------------------------------------
// Stores and restores logged-in user session.
// ===============================================================

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String currentUserKey = 'currentUser';

  Future<void> saveCurrentUser(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(currentUserKey, jsonEncode(user));
  }

  Future<Map<String, dynamic>?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userString = prefs.getString(currentUserKey);

    if (userString == null || userString.trim().isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(userString);

      if (decoded is! Map<String, dynamic>) {
        await prefs.remove(currentUserKey);
        return null;
      }

      return Map<String, dynamic>.from(decoded);
    } catch (_) {
      await prefs.remove(currentUserKey);
      return null;
    }
  }

  Future<void> clearCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(currentUserKey);
  }

  Future<bool> isLoggedIn() async {
    final user = await getCurrentUser();
    return user != null;
  }
}