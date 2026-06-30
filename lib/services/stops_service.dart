// ===============================================================
// stops_service.dart
// ---------------------------------------------------------------
// Stops Service
//
// PURPOSE
// ---------------------------------------------------------------
// Fetches shuttle stops from Google Apps Script API.
// ===============================================================

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/constants/app_constants.dart';
import '../models/stop_model.dart';

class StopsService {
  Future<List<StopModel>> getStops() async {
    final url = '${AppConstants.apiUrl}?action=getStops';

    try {
      final response = await http.get(Uri.parse(url));
      final data = jsonDecode(response.body);

      if (data['success'] != true) {
        throw Exception(data['error'] ?? 'Failed to load stops');
      }

      final stops = data['stops'];

      if (stops is! List) {
        return [];
      }

      return stops
          .asMap()
          .entries
          .map((entry) => StopModel.fromDynamic(entry.value, entry.key))
          .where((stop) => stop.stopName.isNotEmpty)
          .toList();
    } catch (error) {
      throw Exception('Unable to load stops: $error');
    }
  }
}