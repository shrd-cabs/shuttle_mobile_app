import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/constants/app_config.dart';

class AuthService {

  // ===========================
  // LOGIN
  // ===========================
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {

    final url =
        '${AppConfig.apiUrl}'
        '?action=validateUser'
        '&email=${Uri.encodeComponent(email)}'
        '&password=${Uri.encodeComponent(password)}';

    try {

      final response = await http.get(
        Uri.parse(url),
      );

      return jsonDecode(response.body);

    } catch (e) {

      return {
        'success': false,
        'error': e.toString(),
      };

    }
  }

  // ===========================
  // SIGNUP
  // ===========================
  Future<Map<String, dynamic>> signup({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {

    final url =
        '${AppConfig.apiUrl}'
        '?action=addUser'
        '&name=${Uri.encodeComponent(name)}'
        '&email=${Uri.encodeComponent(email)}'
        '&phone=${Uri.encodeComponent(phone)}'
        '&password=${Uri.encodeComponent(password)}'
        '&role=user';

    try {

      final response = await http.get(
        Uri.parse(url),
      );

      return jsonDecode(response.body);

    } catch (e) {

      return {
        'success': false,
        'error': e.toString(),
      };

    }
  }

  // ===========================
  // FORGOT PASSWORD
  // ===========================
  Future<Map<String, dynamic>> forgotPassword(
    String email,
  ) async {

    final url =
        '${AppConfig.apiUrl}'
        '?action=forgotPassword'
        '&email=${Uri.encodeComponent(email)}';

    try {

      final response = await http.get(
        Uri.parse(url),
      );

      return jsonDecode(response.body);

    } catch (e) {

      return {
        'success': false,
        'error': e.toString(),
      };

    }
  }

}