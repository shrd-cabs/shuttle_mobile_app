import 'package:shared_preferences/shared_preferences.dart';

class StorageService {

  static Future<void> saveUser(String userData) async {

    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      'currentUser',
      userData,
    );
  }

  static Future<String?> getUser() async {

    final prefs = await SharedPreferences.getInstance();

    return prefs.getString(
      'currentUser',
    );
  }

  static Future<void> removeUser() async {

    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(
      'currentUser',
    );
  }
}