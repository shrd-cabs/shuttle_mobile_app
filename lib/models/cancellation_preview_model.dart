// ===============================================================
// cancellation_preview_model.dart
// ---------------------------------------------------------------
// Cancellation Preview Model
// ===============================================================

class CancellationPreviewModel {
  final double totalAmount;
  final double fixedDeduction;
  final double percentDeduction;
  final double percentDeductionAmount;
  final double deductionAmount;
  final double refundAmount;
  final String ruleLabel;

  const CancellationPreviewModel({
    required this.totalAmount,
    required this.fixedDeduction,
    required this.percentDeduction,
    required this.percentDeductionAmount,
    required this.deductionAmount,
    required this.refundAmount,
    required this.ruleLabel,
  });

  factory CancellationPreviewModel.fromJson(Map<String, dynamic> json) {
    return CancellationPreviewModel(
      totalAmount: double.tryParse('${json['total_amount'] ?? 0}') ?? 0,
      fixedDeduction:
          double.tryParse('${json['fixed_deduction'] ?? 0}') ?? 0,
      percentDeduction:
          double.tryParse('${json['percent_deduction'] ?? 0}') ?? 0,
      percentDeductionAmount:
          double.tryParse('${json['percent_deduction_amount'] ?? 0}') ?? 0,
      deductionAmount:
          double.tryParse('${json['deduction_amount'] ?? 0}') ?? 0,
      refundAmount:
          double.tryParse('${json['refund_amount'] ?? 0}') ?? 0,
      ruleLabel: '${json['rule_label'] ?? ''}',
    );
  }
}