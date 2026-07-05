// ===============================================================
// wallet_service.dart
// ---------------------------------------------------------------
// Wallet Service
//
// PURPOSE
// ---------------------------------------------------------------
// Handles wallet balance and wallet transactions API calls.
// ===============================================================

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/constants/app_constants.dart';
import '../models/wallet_transaction_model.dart';

class WalletService {
  Future<double> getWalletBalance({
    required String email,
  }) async {
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

  Future<List<WalletTransactionModel>> getWalletTransactions({
    required String email,
    int limit = 10,
  }) async {
    final url = Uri.parse(
      '${AppConstants.apiUrl}'
      '?action=getWalletTransactions'
      '&email=${Uri.encodeComponent(email)}'
      '&limit=$limit',
    );

    final response = await http.get(url);
    final data = jsonDecode(response.body);

    if (data['success'] != true) {
      throw Exception(data['error'] ?? 'Failed to fetch wallet transactions');
    }

    final list = data['transactions'] ?? [];

    return (list as List)
        .map(
          (e) => WalletTransactionModel.fromJson(
            Map<String, dynamic>.from(e),
          ),
        )
        .toList();
  }

  Future<Map<String, dynamic>> createWalletOrder({
    required double amount,
    }) async {
    final amountInPaise = (amount * 100).round();

    final url = Uri.parse(
        '${AppConstants.apiUrl}'
        '?action=createWalletOrder'
        '&amount=$amountInPaise',
    );

    final response = await http.get(url);
    final data = jsonDecode(response.body);

    if (data['success'] != true) {
        throw Exception(data['error'] ?? 'Failed to create wallet order');
    }

    return Map<String, dynamic>.from(data);
    }

    Future<Map<String, dynamic>> verifyWalletPayment({
    required String email,
    required double amount,
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
    }) async {
    final url = Uri.parse(
        '${AppConstants.apiUrl}'
        '?action=verifyWalletPayment'
        '&email=${Uri.encodeComponent(email)}'
        '&amount=${Uri.encodeComponent('$amount')}'
        '&razorpay_order_id=${Uri.encodeComponent(razorpayOrderId)}'
        '&razorpay_payment_id=${Uri.encodeComponent(razorpayPaymentId)}'
        '&razorpay_signature=${Uri.encodeComponent(razorpaySignature)}',
    );

    final response = await http.get(url);
    final data = jsonDecode(response.body);

    if (data['success'] != true) {
        throw Exception(data['error'] ?? 'Wallet verification failed');
    }

    return Map<String, dynamic>.from(data);
    }
}