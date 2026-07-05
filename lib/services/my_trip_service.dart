// ===============================================================
// my_trip_service.dart
// ---------------------------------------------------------------
// My Trips Service
//
// PURPOSE
// ---------------------------------------------------------------
// Fetches user bookings from Google Apps Script.
//
// RESPONSIBILITIES
// ---------------------------------------------------------------
// • Load Current Trips
// • Load Upcoming Trips
// • Load Past Trips
//
// NOTE
// ---------------------------------------------------------------
// All JSON parsing happens here.
// UI never deals with raw JSON.
// ===============================================================

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/constants/app_constants.dart';
import '../models/trip_model.dart';
import '../models/cancellation_preview_model.dart';

class MyTripService {

  // =============================================================
  // LOAD MY TRIPS
  // =============================================================

  Future<MyTripsResponse> getMyTrips({
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
      throw Exception(
        data['error'] ?? 'Unable to load trips',
      );
    }

    return MyTripsResponse.fromJson(data);
  }

  // =============================================================
  // CANCELLATION PREVIEW
  // =============================================================

  Future<CancellationPreviewModel> getCancellationPreview({
    required String bookingId,
  }) async {
    final url = Uri.parse(
      '${AppConstants.apiUrl}'
      '?action=getCancellationPreview'
      '&booking_id=${Uri.encodeComponent(bookingId)}',
    );

    final response = await http.get(url);

    final data = jsonDecode(response.body);

    if (data['success'] != true) {
      throw Exception(
        data['error'] ?? 'Unable to calculate cancellation',
      );
    }

    return CancellationPreviewModel.fromJson(data);
  }

  // =============================================================
  // CANCEL BOOKING
  // =============================================================

  Future<Map<String, dynamic>> cancelBooking({
    required String bookingId,
    required String userEmail,
  }) async {
    final url = Uri.parse(
      '${AppConstants.apiUrl}'
      '?action=cancelBooking'
      '&booking_id=${Uri.encodeComponent(bookingId)}'
      '&user_email=${Uri.encodeComponent(userEmail)}',
    );

    final response = await http.get(url);

    final data = jsonDecode(response.body);

    if (data['success'] != true) {
      throw Exception(
        data['error'] ?? 'Unable to cancel booking',
      );
    }

    return Map<String, dynamic>.from(data);
  }
}


// ===============================================================
// MY TRIPS RESPONSE
// ===============================================================

class MyTripsResponse {

  final List<TripModel> currentTrips;

  final List<TripModel> upcomingTrips;

  final List<TripModel> pastTrips;

  const MyTripsResponse({
    required this.currentTrips,
    required this.upcomingTrips,
    required this.pastTrips,
  });

    factory MyTripsResponse.fromJson(Map<String, dynamic> json) {
        List<TripModel> parse(dynamic value) {
            if (value == null) return [];

            return (value as List)
                .map(
                (e) => TripModel.fromJson(
                    Map<String, dynamic>.from(e),
                ),
                )
                .toList();
        }

        return MyTripsResponse(
            currentTrips: parse(json['current_trips'] ?? json['currentTrips']),
            upcomingTrips: parse(json['upcoming_trips'] ?? json['upcomingTrips']),
            pastTrips: parse(json['past_trips'] ?? json['pastTrips']),
        );
    }   
}