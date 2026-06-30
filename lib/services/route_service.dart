// ===============================================================
// route_service.dart
// ---------------------------------------------------------------
// Route Service
//
// PURPOSE
// ---------------------------------------------------------------
// Calls searchRoutes API for one-way and round-trip availability.
// ===============================================================

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/constants/app_constants.dart';
import '../models/route_model.dart';

class RouteSearchResult {
  final bool success;
  final String tripType;
  final String message;
  final List<RouteModel> routes;
  final List<RouteModel> onwardRoutes;
  final List<RouteModel> returnRoutes;

  const RouteSearchResult({
    required this.success,
    required this.tripType,
    required this.message,
    required this.routes,
    required this.onwardRoutes,
    required this.returnRoutes,
  });
}

class RouteService {
  Future<RouteSearchResult> searchRoutes({
    required String tripType,
    required String travelDate,
    required String fromStop,
    required String toStop,
    required int seatsRequired,
  }) async {
    final url = Uri.parse(
      '${AppConstants.apiUrl}'
      '?action=searchRoutes'
      '&trip_type=${Uri.encodeComponent(tripType.toUpperCase())}'
      '&travel_date=${Uri.encodeComponent(travelDate)}'
      '&from_stop=${Uri.encodeComponent(fromStop)}'
      '&to_stop=${Uri.encodeComponent(toStop)}'
      '&seats_required=${Uri.encodeComponent('$seatsRequired')}',
    );

    try {
      final response = await http.get(url);

      if (response.statusCode != 200) {
        throw Exception('Server error: ${response.statusCode}');
      }

      final data = jsonDecode(response.body);

      if (data['success'] != true) {
        return RouteSearchResult(
          success: false,
          tripType: tripType.toUpperCase(),
          message: data['error'] ?? 'No trips available',
          routes: const [],
          onwardRoutes: const [],
          returnRoutes: const [],
        );
      }

      final oneWayRoutes = data['routes'] is List
          ? (data['routes'] as List)
              .map((e) => RouteModel.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : <RouteModel>[];

      final onwardRoutes = data['onward_routes'] is List
          ? (data['onward_routes'] as List)
              .map((e) => RouteModel.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : <RouteModel>[];

      final returnRoutes = data['return_routes'] is List
          ? (data['return_routes'] as List)
              .map((e) => RouteModel.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : <RouteModel>[];

      return RouteSearchResult(
        success: true,
        tripType: tripType.toUpperCase(),
        message: 'Routes found successfully',
        routes: oneWayRoutes,
        onwardRoutes: onwardRoutes,
        returnRoutes: returnRoutes,
      );
    } catch (error) {
      return RouteSearchResult(
        success: false,
        tripType: tripType.toUpperCase(),
        message: 'Error connecting to server',
        routes: const [],
        onwardRoutes: const [],
        returnRoutes: const [],
      );
    }
  }
}