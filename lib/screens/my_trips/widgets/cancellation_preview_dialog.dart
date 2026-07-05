// ===============================================================
// cancellation_preview_dialog.dart
// ---------------------------------------------------------------
// Cancellation Preview Dialog
//
// PURPOSE
// ---------------------------------------------------------------
// Shows cancellation breakup and confirms cancellation.
// ===============================================================

import 'package:flutter/material.dart';

import '../../../models/cancellation_preview_model.dart';
import '../../../models/trip_model.dart';
import '../../../services/my_trip_service.dart';

class CancellationPreviewDialog extends StatefulWidget {
  final TripModel trip;
  final Future<void> Function() onRefresh;

  const CancellationPreviewDialog({
    super.key,
    required this.trip,
    required this.onRefresh,
  });

  @override
  State<CancellationPreviewDialog> createState() =>
      _CancellationPreviewDialogState();
}

class _CancellationPreviewDialogState extends State<CancellationPreviewDialog> {
  final myTripService = MyTripService();

  bool isLoading = true;
  bool isCancelling = false;

  CancellationPreviewModel? preview;

  @override
  void initState() {
    super.initState();
    loadPreview();
  }

  Future<void> loadPreview() async {
    try {
      final result = await myTripService.getCancellationPreview(
        bookingId: widget.trip.bookingId,
      );

      if (!mounted) return;

      setState(() {
        preview = result;
        isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() => isLoading = false);
      showMessage(error.toString());
    }
  }

  Future<void> confirmCancellation() async {
    if (preview == null) return;

    try {
      setState(() => isCancelling = true);

      await myTripService.cancelBooking(
        bookingId: widget.trip.bookingId,
        userEmail: widget.trip.passengerEmail,
      );

      await widget.onRefresh();

      if (!mounted) return;

      Navigator.pop(context);
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Booking cancelled. Refund ₹${preview!.refundAmount.toStringAsFixed(0)} credited to wallet.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      setState(() => isCancelling = false);
      showMessage(error.toString());
    }
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 650),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: isLoading
              ? const SizedBox(
                  height: 260,
                  child: Center(child: CircularProgressIndicator()),
                )
              : preview == null
                  ? _errorView(context)
                  : _previewView(context),
        ),
      ),
    );
  }

  Widget _errorView(BuildContext context) {
    return Column(
      children: [
        const Text(
          'Cancellation Breakup',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 20),
        const Text('Unable to load cancellation preview.'),
        const SizedBox(height: 20),
        _button(
          text: 'Close',
          color: const Color(0xff6B46C1),
          textColor: Colors.white,
          onTap: () => Navigator.pop(context),
        ),
      ],
    );
  }

  Widget _previewView(BuildContext context) {
    final data = preview!;

    return Column(
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Cancellation Breakup',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Color(0xff111827),
                ),
              ),
            ),
            IconButton(
              onPressed: isCancelling ? null : () => Navigator.pop(context),
              icon: const Icon(Icons.close),
            ),
          ],
        ),

        const SizedBox(height: 18),

        _infoTile('Booking ID', widget.trip.bookingId),
        _infoTile('Total Fare', '₹${data.totalAmount.toStringAsFixed(0)}'),
        _infoTile(
          'Fixed Deduction',
          '₹${data.fixedDeduction.toStringAsFixed(0)}',
        ),
        _infoTile(
          'Percentage Deduction',
          '${data.percentDeduction.toStringAsFixed(0)}%',
        ),
        _infoTile(
          'Percentage Deduction Amount',
          '₹${data.percentDeductionAmount.toStringAsFixed(0)}',
        ),
        _infoTile(
          'Total Deduction',
          '₹${data.deductionAmount.toStringAsFixed(0)}',
        ),
        _infoTile(
          'Refund To Wallet',
          '₹${data.refundAmount.toStringAsFixed(0)}',
          highlight: true,
        ),
        _infoTile('Rule Applied', data.ruleLabel),
        _infoTile('Travel Date', widget.trip.travelDate),
        _infoTile('Pickup Time', widget.trip.scheduledPickupTime),

        const SizedBox(height: 16),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xffF3EDFF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text(
            'Refund, if applicable, will be credited to your wallet after cancellation.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xff4C1D95),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        const SizedBox(height: 22),

        Row(
          children: [
            Expanded(
              child: _button(
                text: 'Back',
                color: Colors.grey.shade200,
                textColor: Colors.black87,
                onTap: isCancelling ? null : () => Navigator.pop(context),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _button(
                text: isCancelling ? 'Cancelling...' : 'Confirm Cancel',
                color: Colors.red.shade400,
                textColor: Colors.white,
                onTap: isCancelling ? null : confirmCancellation,
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        _button(
          text: 'Close',
          color: const Color(0xff6B46C1),
          textColor: Colors.white,
          onTap: isCancelling ? null : () => Navigator.pop(context),
        ),
      ],
    );
  }

  Widget _infoTile(
    String title,
    String value, {
    bool highlight = false,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: highlight ? const Color(0xffECFDF5) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: highlight ? Colors.green.shade300 : Colors.grey.shade300,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Text(
              '$title:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xff111827),
              ),
            ),
          ),
          Expanded(
            flex: 5,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
                color: highlight ? Colors.green.shade700 : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _button({
    required String text,
    required Color color,
    required Color textColor,
    required VoidCallback? onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: textColor,
          disabledBackgroundColor: color.withValues(alpha: 0.65),
          disabledForegroundColor: textColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}