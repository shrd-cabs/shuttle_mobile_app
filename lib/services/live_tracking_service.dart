// ===============================================================
// live_tracking_service.dart
// ---------------------------------------------------------------
// Live Tracking Service
//
// PURPOSE
// ---------------------------------------------------------------
// Handles customer-side live tracking API calls.
// ===============================================================

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/constants/app_constants.dart';
import '../models/live_tracking_model.dart';

class LiveTrackingService {
  Future<Map<String, dynamic>> getMyTripsForLiveTracking({
    required String email,
  }) async {
    final url = Uri.parse(
      '${AppConstants.apiUrl}'
      '?action=getMyTrips'
      '&email=${Uri.encodeComponent(email)}',
    );

    final response = await http.get(url);
    final data = jsonDecode(response.body);

    if (data['success'] != true) {
      throw Exception(data['error'] ?? 'Live trips fetch failed');
    }

    return Map<String, dynamic>.from(data);
  }

  Future<LiveTrackingModel> getLiveTrackingDetails({
    required String bookingId,
    required String email,
  }) async {
    final url = Uri.parse(
      '${AppConstants.apiUrl}'
      '?action=getLiveTrackingDetails'
      '&booking_id=${Uri.encodeComponent(bookingId)}'
      '&email=${Uri.encodeComponent(email)}',
    );

    final response = await http.get(url);
    final data = jsonDecode(response.body);

    if (data['success'] != true) {
      throw Exception(data['error'] ?? 'Tracking fetch failed');
    }

    return LiveTrackingModel.fromJson(
      Map<String, dynamic>.from(data),
    );
  }

  List<Map<String, dynamic>> parseCurrentTrips(
    Map<String, dynamic> data,
  ) {
    return ((data['current_trips'] ?? []) as List)
        .map(
          (e) => Map<String, dynamic>.from(e),
        )
        .toList();
  }

  List<Map<String, dynamic>> getTrackableTrips(
    List<Map<String, dynamic>> trips,
  ) {
    return trips.where((trip) => !isTripPassed(trip)).toList();
  }

  bool isTripPassed(
    Map<String, dynamic> trip,
  ) {
    final travelDate = '${trip['travel_date'] ?? ''}';
    final scheduledDropTime = '${trip['scheduled_drop_time'] ?? ''}';

    if (travelDate.isEmpty || scheduledDropTime.isEmpty) {
      return false;
    }

    final endTime = LiveTrackingModel.formatTimeOnly(scheduledDropTime);

    if (endTime.isEmpty) {
      return false;
    }

    final tripEnd = DateTime.tryParse(
      '${travelDate}T$endTime:00',
    );

    if (tripEnd == null) {
      return false;
    }

    return DateTime.now().isAfter(tripEnd);
  }

  String getTripLiveState(
    Map<String, dynamic> trip,
  ) {
    final travelDate = '${trip['travel_date'] ?? ''}';
    final scheduledPickupTime = '${trip['scheduled_pickup_time'] ?? ''}';
    final scheduledDropTime = '${trip['scheduled_drop_time'] ?? ''}';

    if (travelDate.isEmpty ||
        scheduledPickupTime.isEmpty ||
        scheduledDropTime.isEmpty) {
      return 'UPCOMING';
    }

    final pickupTime = LiveTrackingModel.formatTimeOnly(
      scheduledPickupTime,
    );

    final dropTime = LiveTrackingModel.formatTimeOnly(
      scheduledDropTime,
    );

    final pickupDateTime = DateTime.tryParse(
      '${travelDate}T$pickupTime:00',
    );

    final dropDateTime = DateTime.tryParse(
      '${travelDate}T$dropTime:00',
    );

    if (pickupDateTime == null || dropDateTime == null) {
      return 'UPCOMING';
    }

    final now = DateTime.now();

    if (now.isAfter(pickupDateTime) && now.isBefore(dropDateTime)) {
      return 'LIVE';
    }

    if (now.isAtSameMomentAs(pickupDateTime) ||
        now.isAtSameMomentAs(dropDateTime)) {
      return 'LIVE';
    }

    return 'UPCOMING';
  }

  String formatLiveTripTimeRange(
    Map<String, dynamic> trip,
  ) {
    final pickupTime = LiveTrackingModel.formatTimeOnly(
      trip['scheduled_pickup_time'],
    );

    final dropTime = LiveTrackingModel.formatTimeOnly(
      trip['scheduled_drop_time'],
    );

    return '$pickupTime - $dropTime';
  }
}