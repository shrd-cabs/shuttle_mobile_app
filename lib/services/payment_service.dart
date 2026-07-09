// ===============================================================
// payment_service.dart
// ---------------------------------------------------------------
// Payment Service
//
// PURPOSE
// ---------------------------------------------------------------
// Handles payment preparation and booking hold creation.
// Supports ONEWAY and ROUNDTRIP payment confirmation.
// ===============================================================

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/constants/app_constants.dart';
import '../models/payment_summary_model.dart';
import '../models/selected_booking_model.dart';

class PaymentService {
  Future<double> getWalletBalance(String email) async {
    final url = Uri.parse(
      '${AppConstants.apiUrl}'
      '?action=getWalletBalance'
      '&email=${Uri.encodeComponent(email)}',
    );

    final response = await http.get(url);
    final data = jsonDecode(response.body);

    if (data['success'] != true) {
      throw Exception(data['error'] ?? 'Failed to fetch wallet balance');
    }

    return double.tryParse('${data['wallet_balance'] ?? 0}') ?? 0;
  }

  Future<Map<String, dynamic>> getApplicablePass({
    required String email,
    required String routeId,
    required String tripType,
    required double totalAmount,
  }) async {
    final url = Uri.parse(
      '${AppConstants.apiUrl}'
      '?action=getApplicablePassForBooking'
      '&user_email=${Uri.encodeComponent(email)}'
      '&route_id=${Uri.encodeComponent(routeId)}'
      '&trip_type=${Uri.encodeComponent(tripType)}'
      '&total_amount=${Uri.encodeComponent('$totalAmount')}',
    );

    final response = await http.get(url);
    final data = jsonDecode(response.body);

    if (data['success'] != true) {
      throw Exception(data['error'] ?? 'Failed to fetch applicable pass');
    }

    return Map<String, dynamic>.from(data);
  }

  Future<PaymentSummaryModel> preparePaymentSummary({
    required SelectedBookingModel booking,
    required String userEmail,
  }) async {
    if (!booking.isValid) {
      throw Exception('Please select a route first');
    }

    final originalAmount = booking.originalAmount;
    final walletBalance = await getWalletBalance(userEmail);

    Map<String, dynamic>? passDetails;
    bool passApplied = false;
    double finalAmount = originalAmount;
    double passDiscountAmount = 0;

    try {
      final passData = await getApplicablePass(
        email: userEmail,
        routeId: booking.routeIdForPass,
        tripType: booking.tripType,
        totalAmount: originalAmount,
      );

      if (passData['hasPass'] == true &&
          passData['applicable'] == true &&
          passData['passDetails'] != null) {
        passApplied = true;
        passDetails = Map<String, dynamic>.from(passData['passDetails']);

        passDiscountAmount =
            double.tryParse('${passDetails['discount_amount'] ?? 0}') ?? 0;

        finalAmount =
            double.tryParse('${passDetails['final_amount'] ?? originalAmount}') ??
                originalAmount;
      }
    } catch (_) {
      passApplied = false;
      passDetails = null;
      passDiscountAmount = 0;
      finalAmount = originalAmount;
    }

    return PaymentSummaryModel(
      booking: booking,
      originalAmount: originalAmount,
      finalAmount: finalAmount,
      walletBalance: walletBalance,
      passApplied: passApplied,
      passDetails: passDetails,
      passDiscountAmount: passDiscountAmount,
    );
  }

  Future<List<String>> createHoldBooking({
    required SelectedBookingModel booking,
    required Map<String, dynamic> user,
  }) async {
    if (booking.tripType == 'ROUNDTRIP') {
      return createRoundTripHoldBooking(
        booking: booking,
        user: user,
      );
    }

    return createOneWayHoldBooking(
      booking: booking,
      user: user,
    );
  }

  String buildRoundTripLegQueryString({
    required PaymentSummaryModel summary,
  }) {
    if (summary.booking.tripType != 'ROUNDTRIP') {
      return '';
    }

    final onward = summary.booking.onwardRoute!;
    final ret = summary.booking.returnRoute!;

    final onwardOriginal = onward.totalAmount;
    final returnOriginal = ret.totalAmount;
    final combinedOriginal = onwardOriginal + returnOriginal;
    final combinedFinal = summary.finalAmount;

    double onwardFinal = onwardOriginal;
    double returnFinal = returnOriginal;

    if (summary.passApplied &&
        combinedOriginal > 0 &&
        combinedFinal < combinedOriginal) {
      onwardFinal = ((onwardOriginal / combinedOriginal) * combinedFinal).roundToDouble();
      returnFinal = combinedFinal - onwardFinal;
    }

    return '&onward_original_total_amount=${Uri.encodeComponent('$onwardOriginal')}'
        '&onward_final_total_amount=${Uri.encodeComponent('$onwardFinal')}'
        '&return_original_total_amount=${Uri.encodeComponent('$returnOriginal')}'
        '&return_final_total_amount=${Uri.encodeComponent('$returnFinal')}';
  }

  String buildPassQueryString({
    required PaymentSummaryModel summary,
  }) {
    return '&original_total_amount=${Uri.encodeComponent('${summary.originalAmount}')}'
        '&pass_applied=${summary.passApplied ? "YES" : "NO"}'
        '&user_pass_id=${Uri.encodeComponent('${summary.passDetails?['user_pass_id'] ?? "NA"}')}'
        '&pass_type_id=${Uri.encodeComponent('${summary.passDetails?['pass_type_id'] ?? "NA"}')}'
        '&pass_name=${Uri.encodeComponent('${summary.passDetails?['pass_name'] ?? "NA"}')}'
        '&pass_discount_percent=${Uri.encodeComponent('${summary.passDetails?['discount_percent'] ?? 0}')}'
        '&pass_discount_amount=${Uri.encodeComponent('${summary.passDiscountAmount}')}'
        '&final_total_amount=${Uri.encodeComponent('${summary.finalAmount}')}';
  }

  Future<Map<String, dynamic>> processWalletBookingPayment({
    required List<String> bookingIds,
    required String tripType,
    required String email,
    required double amount,
    required PaymentSummaryModel summary,
  }) async {
    final url = Uri.parse(
      '${AppConstants.apiUrl}'
      '?action=processWalletBookingPayment'
      '&booking_ids=${Uri.encodeComponent(bookingIds.join(","))}'
      '&trip_type=${Uri.encodeComponent(tripType)}'
      '&email=${Uri.encodeComponent(email)}'
      '&amount=${Uri.encodeComponent('$amount')}'
      '${buildPassQueryString(summary: summary)}'
      '${buildRoundTripLegQueryString(summary: summary)}',
    );

    final response = await http.get(url);
    final data = jsonDecode(response.body);

    if (data['success'] != true) {
      throw Exception(data['error'] ?? 'Wallet payment failed');
    }

    return Map<String, dynamic>.from(data);
  }

  Future<List<String>> createOneWayHoldBooking({
    required SelectedBookingModel booking,
    required Map<String, dynamic> user,
  }) async {
    final route = booking.oneWayRoute!;
    final farePerSeat = route.totalAmount / booking.pax;

    final url = Uri.parse(
      '${AppConstants.apiUrl}'
      '?action=createHoldBooking'
      '&trip_type=ONEWAY'
      '&booking_date=${Uri.encodeComponent(DateTime.now().toIso8601String().split('T').first)}'
      '&travel_date=${Uri.encodeComponent(booking.travelDate)}'
      '&route_id=${Uri.encodeComponent(route.routeId)}'
      '&bus_id=${Uri.encodeComponent(route.busId)}'
      '&bus_number=${Uri.encodeComponent(route.busNumber)}'
      '&driver_name=${Uri.encodeComponent(route.driverName)}'
      '&driver_phone=${Uri.encodeComponent(route.driverPhone)}'
      '&fromStop=${Uri.encodeComponent(booking.fromStop)}'
      '&toStop=${Uri.encodeComponent(booking.toStop)}'
      '&scheduled_pickup_time=${Uri.encodeComponent(route.arrivalTime)}'
      '&scheduled_drop_time=${Uri.encodeComponent(route.reachingTime)}'
      '&passenger_name=${Uri.encodeComponent('${user['name'] ?? ''}')}'
      '&passenger_email=${Uri.encodeComponent('${user['email'] ?? ''}')}'
      '&passenger_phone=${Uri.encodeComponent('${user['phone'] ?? ''}')}'
      '&seats_booked=${Uri.encodeComponent('${booking.pax}')}'
      '&fare_per_seat=${Uri.encodeComponent('$farePerSeat')}'
      '&total_amount=${Uri.encodeComponent('${route.totalAmount}')}',
    );

    final response = await http.get(url);
    final data = jsonDecode(response.body);

    if (data['success'] != true) {
      throw Exception(data['error'] ?? 'Failed to create booking hold');
    }

    if (data['booking_id'] != null) {
      return ['${data['booking_id']}'];
    }

    if (data['booking_ids'] is List) {
      return (data['booking_ids'] as List).map((e) => '$e').toList();
    }

    throw Exception('Hold created but booking ID missing');
  }

  Future<List<String>> createRoundTripHoldBooking({
    required SelectedBookingModel booking,
    required Map<String, dynamic> user,
  }) async {
    final onward = booking.onwardRoute!;
    final ret = booking.returnRoute!;

    final onwardFare = onward.totalAmount / booking.pax;
    final returnFare = ret.totalAmount / booking.pax;

    final url = Uri.parse(
      '${AppConstants.apiUrl}'
      '?action=createHoldBooking'
      '&trip_type=ROUNDTRIP'
      '&booking_date=${Uri.encodeComponent(DateTime.now().toIso8601String().split('T').first)}'
      '&travel_date=${Uri.encodeComponent(booking.travelDate)}'
      '&onward_route_id=${Uri.encodeComponent(onward.routeId)}'
      '&onward_bus_id=${Uri.encodeComponent(onward.busId)}'
      '&onward_bus_number=${Uri.encodeComponent(onward.busNumber)}'
      '&onward_driver_name=${Uri.encodeComponent(onward.driverName)}'
      '&onward_driver_phone=${Uri.encodeComponent(onward.driverPhone)}'
      '&onward_fromStop=${Uri.encodeComponent(booking.fromStop)}'
      '&onward_toStop=${Uri.encodeComponent(booking.toStop)}'
      '&onward_scheduled_pickup_time=${Uri.encodeComponent(onward.arrivalTime)}'
      '&onward_scheduled_drop_time=${Uri.encodeComponent(onward.reachingTime)}'
      '&onward_fare_per_seat=${Uri.encodeComponent('$onwardFare')}'
      '&onward_total_amount=${Uri.encodeComponent('${onward.totalAmount}')}'
      '&return_route_id=${Uri.encodeComponent(ret.routeId)}'
      '&return_bus_id=${Uri.encodeComponent(ret.busId)}'
      '&return_bus_number=${Uri.encodeComponent(ret.busNumber)}'
      '&return_driver_name=${Uri.encodeComponent(ret.driverName)}'
      '&return_driver_phone=${Uri.encodeComponent(ret.driverPhone)}'
      '&return_fromStop=${Uri.encodeComponent(booking.toStop)}'
      '&return_toStop=${Uri.encodeComponent(booking.fromStop)}'
      '&return_scheduled_pickup_time=${Uri.encodeComponent(ret.arrivalTime)}'
      '&return_scheduled_drop_time=${Uri.encodeComponent(ret.reachingTime)}'
      '&return_fare_per_seat=${Uri.encodeComponent('$returnFare')}'
      '&return_total_amount=${Uri.encodeComponent('${ret.totalAmount}')}'
      '&passenger_name=${Uri.encodeComponent('${user['name'] ?? ''}')}'
      '&passenger_email=${Uri.encodeComponent('${user['email'] ?? ''}')}'
      '&passenger_phone=${Uri.encodeComponent('${user['phone'] ?? ''}')}'
      '&seats_booked=${Uri.encodeComponent('${booking.pax}')}',
    );

    final response = await http.get(url);
    final data = jsonDecode(response.body);

    if (data['success'] != true) {
      throw Exception(data['error'] ?? 'Failed to create round-trip booking hold');
    }

    if (data['booking_ids'] is List) {
      return (data['booking_ids'] as List).map((e) => '$e').toList();
    }

    if (data['booking_id'] != null) {
      return ['${data['booking_id']}'];
    }

    throw Exception('Round-trip hold created but booking IDs missing');
  }

  Future<Map<String, dynamic>> createOrder({
    required double amount,
  }) async {
    final url = Uri.parse(
      '${AppConstants.apiUrl}'
      '?action=createOrder'
      '&amount=${(amount * 100).round()}',
    );

    final response = await http.get(url);
    final data = jsonDecode(response.body);

    if (data['success'] != true) {
      throw Exception(data['error'] ?? 'Failed to create Razorpay order');
    }

    return Map<String, dynamic>.from(data);
  }

  Future<Map<String, dynamic>> confirmBooking({
    required List<String> bookingIds,
    required String tripType,
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
    required PaymentSummaryModel summary,
  }) async {
    final url = Uri.parse(
      '${AppConstants.apiUrl}'
      '?action=confirmBooking'
      '&booking_ids=${Uri.encodeComponent(bookingIds.join(","))}'
      '&trip_type=${Uri.encodeComponent(tripType)}'
      '&razorpay_order_id=${Uri.encodeComponent(razorpayOrderId)}'
      '&razorpay_payment_id=${Uri.encodeComponent(razorpayPaymentId)}'
      '&razorpay_signature=${Uri.encodeComponent(razorpaySignature)}'
      '${buildPassQueryString(summary: summary)}'
      '${buildRoundTripLegQueryString(summary: summary)}',
    );

    final response = await http.get(url);
    final data = jsonDecode(response.body);

    if (data['success'] != true) {
      throw Exception(data['error'] ?? 'Booking confirmation failed');
    }

    return Map<String, dynamic>.from(data);
  }

  Future<Map<String, dynamic>> verifyMixedBookingPayment({
    required List<String> bookingIds,
    required String tripType,
    required String email,
    required double walletAmount,
    required double onlineAmount,
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
    required PaymentSummaryModel summary,
  }) async {
    final url = Uri.parse(
      '${AppConstants.apiUrl}'
      '?action=verifyMixedBookingPayment'
      '&booking_ids=${Uri.encodeComponent(bookingIds.join(","))}'
      '&trip_type=${Uri.encodeComponent(tripType)}'
      '&email=${Uri.encodeComponent(email)}'
      '&wallet_amount=${Uri.encodeComponent('$walletAmount')}'
      '&online_amount=${Uri.encodeComponent('$onlineAmount')}'
      '&razorpay_order_id=${Uri.encodeComponent(razorpayOrderId)}'
      '&razorpay_payment_id=${Uri.encodeComponent(razorpayPaymentId)}'
      '&razorpay_signature=${Uri.encodeComponent(razorpaySignature)}'
      '${buildPassQueryString(summary: summary)}'
      '${buildRoundTripLegQueryString(summary: summary)}',
    );

    final response = await http.get(url);
    final data = jsonDecode(response.body);

    if (data['success'] != true) {
      throw Exception(data['error'] ?? 'Mixed payment verification failed');
    }

    return Map<String, dynamic>.from(data);
  }
}