// ===============================================================
// travel_pass_service.dart
// ---------------------------------------------------------------
// Travel Pass Service
//
// PURPOSE
// ---------------------------------------------------------------
// Handles Travel Pass API calls.
// ===============================================================

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/constants/app_constants.dart';

class TravelPassService {
  Map<String, dynamic> _decodeResponse(http.Response response) {
    try {
      final data = jsonDecode(response.body);
      return Map<String, dynamic>.from(data);
    } catch (_) {
      throw Exception('Invalid JSON response from server');
    }
  }

  Future<Map<String, dynamic>> getPassTypes() async {
    final url = Uri.parse(
      '${AppConstants.apiUrl}'
      '?action=getPassTypes',
    );

    final response = await http.get(url);
    final data = _decodeResponse(response);

    if (data['success'] != true) {
      throw Exception(data['error'] ?? 'Failed to fetch pass types');
    }

    return data;
  }

  Future<Map<String, dynamic>> getMyPasses({
    required String userEmail,
  }) async {
    final url = Uri.parse(
      '${AppConstants.apiUrl}'
      '?action=getMyPasses'
      '&user_email=${Uri.encodeComponent(userEmail)}',
    );

    final response = await http.get(url);
    final data = _decodeResponse(response);

    if (data['success'] != true) {
      throw Exception(data['error'] ?? 'Failed to fetch my passes');
    }

    return data;
  }

  Future<Map<String, dynamic>> getPassUsageHistory({
    required String userEmail,
  }) async {
    final url = Uri.parse(
      '${AppConstants.apiUrl}'
      '?action=getPassUsageHistory'
      '&user_email=${Uri.encodeComponent(userEmail)}',
    );

    final response = await http.get(url);
    final data = _decodeResponse(response);

    if (data['success'] != true) {
      throw Exception(data['error'] ?? 'Failed to fetch pass usage history');
    }

    return data;
  }

  Future<Map<String, dynamic>> getPassDetails({
    required String userPassId,
    required String userEmail,
  }) async {
    final url = Uri.parse(
      '${AppConstants.apiUrl}'
      '?action=getPassDetails'
      '&user_pass_id=${Uri.encodeComponent(userPassId)}'
      '&user_email=${Uri.encodeComponent(userEmail)}',
    );

    final response = await http.get(url);
    final data = _decodeResponse(response);

    if (data['success'] != true) {
      throw Exception(data['error'] ?? 'Failed to fetch pass details');
    }

    return data;
  }

  Future<double> getWalletBalance({
    required String email,
  }) async {
    final url = Uri.parse(
      '${AppConstants.apiUrl}'
      '?action=getWalletBalance'
      '&email=${Uri.encodeComponent(email)}',
    );

    final response = await http.get(url);
    final data = _decodeResponse(response);

    if (data['success'] != true) {
      throw Exception(data['error'] ?? 'Failed to fetch wallet balance');
    }

    return double.tryParse('${data['wallet_balance'] ?? 0}') ?? 0;
  }

  Future<Map<String, dynamic>> createPassOrder({
    required double amount,
    required String email,
    required String passTypeId,
  }) async {
    final amountInPaise = (amount * 100).round();

    final url = Uri.parse(
      '${AppConstants.apiUrl}'
      '?action=createOrder'
      '&amount=$amountInPaise'
      '&email=${Uri.encodeComponent(email)}'
      '&pass_type_id=${Uri.encodeComponent(passTypeId)}',
    );

    final response = await http.get(url);
    final data = _decodeResponse(response);

    if (data['success'] != true) {
      throw Exception(data['error'] ?? 'Failed to create pass order');
    }

    return data;
  }

  Future<Map<String, dynamic>> processWalletPassPayment({
    required String userEmail,
    required String passTypeId,
    required double amount,
  }) async {
    final url = Uri.parse(
      '${AppConstants.apiUrl}'
      '?action=processWalletPassPayment'
      '&user_email=${Uri.encodeComponent(userEmail)}'
      '&pass_type_id=${Uri.encodeComponent(passTypeId)}'
      '&amount=${Uri.encodeComponent('$amount')}',
    );

    final response = await http.get(url);
    final data = _decodeResponse(response);

    if (data['success'] != true) {
      throw Exception(data['error'] ?? 'Wallet pass payment failed');
    }

    return data;
  }

  Future<Map<String, dynamic>> verifyPassPayment({
    required String userEmail,
    required String passTypeId,
    required double amount,
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  }) async {
    final url = Uri.parse(
      '${AppConstants.apiUrl}'
      '?action=verifyPassPayment'
      '&user_email=${Uri.encodeComponent(userEmail)}'
      '&pass_type_id=${Uri.encodeComponent(passTypeId)}'
      '&amount=${Uri.encodeComponent('$amount')}'
      '&razorpay_order_id=${Uri.encodeComponent(razorpayOrderId)}'
      '&razorpay_payment_id=${Uri.encodeComponent(razorpayPaymentId)}'
      '&razorpay_signature=${Uri.encodeComponent(razorpaySignature)}',
    );

    final response = await http.get(url);
    final data = _decodeResponse(response);

    if (data['success'] != true) {
      throw Exception(data['error'] ?? 'Pass payment verification failed');
    }

    return data;
  }

  Future<Map<String, dynamic>> verifyMixedPassPayment({
    required String userEmail,
    required String passTypeId,
    required double walletAmount,
    required double onlineAmount,
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  }) async {
    final url = Uri.parse(
      '${AppConstants.apiUrl}'
      '?action=verifyMixedPassPayment'
      '&user_email=${Uri.encodeComponent(userEmail)}'
      '&pass_type_id=${Uri.encodeComponent(passTypeId)}'
      '&wallet_amount=${Uri.encodeComponent('$walletAmount')}'
      '&online_amount=${Uri.encodeComponent('$onlineAmount')}'
      '&razorpay_order_id=${Uri.encodeComponent(razorpayOrderId)}'
      '&razorpay_payment_id=${Uri.encodeComponent(razorpayPaymentId)}'
      '&razorpay_signature=${Uri.encodeComponent(razorpaySignature)}',
    );

    final response = await http.get(url);
    final data = _decodeResponse(response);

    if (data['success'] != true) {
      throw Exception(data['error'] ?? 'Mixed pass payment verification failed');
    }

    return data;
  }
}