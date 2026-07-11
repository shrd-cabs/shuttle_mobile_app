import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../core/constants/app_constants.dart';

class FcmService {
  Future<void> registerToken({
    required String email,
    required String phone,
    required String token,
    required String deviceName,
  }) async {
    try {
      final parameters = {
        "action": "registerFcmToken",
        "user_email": email,
        "user_phone": phone,
        "device_name": deviceName,
        "platform": "android",
        "fcm_token": token,
      };

      final uri = Uri.parse(
        AppConstants.apiUrl,
      ).replace(
        queryParameters: parameters,
      );

      final response = await http.get(uri);

      debugPrint("FCM Register Response: ${response.body}");

      final json = jsonDecode(response.body);

      debugPrint(json.toString());
    } catch (e) {
      debugPrint("FCM Register Error: $e");
    }
  }
}