// ===============================================================
// payment_summary_model.dart
// ---------------------------------------------------------------
// Payment Summary Model
//
// PURPOSE
// ---------------------------------------------------------------
// Holds fare, wallet and pass details before payment confirmation.
// ===============================================================

import 'selected_booking_model.dart';

class PaymentSummaryModel {
  final SelectedBookingModel booking;
  final double originalAmount;
  final double finalAmount;
  final double walletBalance;
  final bool passApplied;
  final Map<String, dynamic>? passDetails;
  final double passDiscountAmount;
  final bool useWallet;

  const PaymentSummaryModel({
    required this.booking,
    required this.originalAmount,
    required this.finalAmount,
    required this.walletBalance,
    required this.passApplied,
    required this.passDetails,
    required this.passDiscountAmount,
    this.useWallet = false,
  });

  double get walletUsed {
    if (!useWallet) return 0;
    return walletBalance > finalAmount ? finalAmount : walletBalance;
  }

  double get onlineAmount {
    return finalAmount - walletUsed;
  }

  PaymentSummaryModel copyWith({
    bool? useWallet,
  }) {
    return PaymentSummaryModel(
      booking: booking,
      originalAmount: originalAmount,
      finalAmount: finalAmount,
      walletBalance: walletBalance,
      passApplied: passApplied,
      passDetails: passDetails,
      passDiscountAmount: passDiscountAmount,
      useWallet: useWallet ?? this.useWallet,
    );
  }
}