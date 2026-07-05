// ===============================================================
// wallet_transaction_model.dart
// ---------------------------------------------------------------
// Wallet Transaction Model
//
// PURPOSE
// ---------------------------------------------------------------
// Represents one wallet transaction returned by backend API.
// ===============================================================

class WalletTransactionModel {
  final String transactionId;
  final String emailId;
  final String transactionType;
  final double amount;
  final double balanceBefore;
  final double balanceAfter;
  final String status;
  final String paymentMode;
  final String referenceId;
  final String remarks;
  final String createdAt;
  final String createdBy;

  const WalletTransactionModel({
    required this.transactionId,
    required this.emailId,
    required this.transactionType,
    required this.amount,
    required this.balanceBefore,
    required this.balanceAfter,
    required this.status,
    required this.paymentMode,
    required this.referenceId,
    required this.remarks,
    required this.createdAt,
    required this.createdBy,
  });

  factory WalletTransactionModel.fromJson(Map<String, dynamic> json) {
    return WalletTransactionModel(
      transactionId: '${json['transaction_id'] ?? ''}',
      emailId: '${json['email_id'] ?? ''}',
      transactionType: '${json['transaction_type'] ?? ''}',
      amount: double.tryParse('${json['amount'] ?? 0}') ?? 0,
      balanceBefore: double.tryParse('${json['balance_before'] ?? 0}') ?? 0,
      balanceAfter: double.tryParse('${json['balance_after'] ?? 0}') ?? 0,
      status: '${json['status'] ?? ''}',
      paymentMode: '${json['payment_mode'] ?? ''}',
      referenceId: '${json['reference_id'] ?? ''}',
      remarks: '${json['remarks'] ?? ''}',
      createdAt: '${json['created_at'] ?? ''}',
      createdBy: '${json['created_by'] ?? ''}',
    );
  }

  bool get isCredit {
    final type = transactionType.toUpperCase();
    return type == 'CREDIT' || type == 'REFUND';
  }

  String get amountLabel {
    final sign = isCredit ? '+' : '-';
    return '$sign₹${amount.toStringAsFixed(0)}';
  }

  String get title {
    if (remarks.isNotEmpty) return remarks;
    if (transactionType.isNotEmpty) return transactionType;
    return 'Wallet Transaction';
  }
}