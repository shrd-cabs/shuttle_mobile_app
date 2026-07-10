// ===============================================================
// route_details_service.dart
// ---------------------------------------------------------------
// Calls the getRouteDetails Apps Script endpoint.
//
// PURPOSE:
// ---------------------------------------------------------------
// Loads:
// - Selected passenger journey
// - Scheduled stops
// - Complete route
// - Bus details
// - Journey duration
//
// This service is separate from RouteService because RouteService
// handles availability search, while this service handles route
// information after a route card is displayed.
// ===============================================================

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../core/constants/app_constants.dart';
import '../models/route_details_model.dart';

class RouteDetailsService {
  // =============================================================
  // GET ROUTE DETAILS
  // =============================================================
  Future<RouteDetailsModel> getRouteDetails({
    required String routeId,
    required String fromStopId,
    required String toStopId,
    required String fromStopName,
    required String toStopName,
  }) async {
    final cleanRouteId = routeId.trim();

    if (cleanRouteId.isEmpty) {
      throw Exception('Route ID is missing');
    }

    final queryParameters = <String, String>{
      'action': 'getRouteDetails',
      'route_id': cleanRouteId,
    };

    // Stop IDs are preferred by the backend.
    if (fromStopId.trim().isNotEmpty) {
      queryParameters['from_stop_id'] =
          fromStopId.trim();
    }

    if (toStopId.trim().isNotEmpty) {
      queryParameters['to_stop_id'] =
          toStopId.trim();
    }

    // Stop names are also sent as fallback.
    if (fromStopName.trim().isNotEmpty) {
      queryParameters['from_stop'] =
          fromStopName.trim();
    }

    if (toStopName.trim().isNotEmpty) {
      queryParameters['to_stop'] =
          toStopName.trim();
    }

    final baseUri = Uri.parse(
      AppConstants.apiUrl,
    );

    final uri = baseUri.replace(
      queryParameters: queryParameters,
    );

    debugPrint(
      '🗺️ Route Details API URL: $uri',
    );

    try {
      final response = await http
          .get(uri)
          .timeout(
            const Duration(seconds: 25),
          );

      debugPrint(
        '📶 Route Details status: '
        '${response.statusCode}',
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Server error: ${response.statusCode}',
        );
      }

      final decoded = jsonDecode(
        response.body,
      );

      if (decoded is! Map) {
        throw Exception(
          'Invalid route details response',
        );
      }

      final data = Map<String, dynamic>.from(
        decoded,
      );

      final result =
          RouteDetailsModel.fromJson(data);

      if (!result.success) {
        throw Exception(
          result.error.isNotEmpty
              ? result.error
              : 'Unable to load route details',
        );
      }

      if (result.stops.isEmpty) {
        throw Exception(
          'No scheduled stops found for this route',
        );
      }

      return result;
    } on FormatException catch (error) {
      debugPrint(
        '❌ Route Details JSON error: $error',
      );

      throw Exception(
        'Invalid response received from server',
      );
    } catch (error) {
      debugPrint(
        '❌ Route Details request failed: $error',
      );

      final message = error
          .toString()
          .replaceFirst('Exception: ', '');

      throw Exception(
        message.isEmpty
            ? 'Unable to connect to server'
            : message,
      );
    }
  }
}