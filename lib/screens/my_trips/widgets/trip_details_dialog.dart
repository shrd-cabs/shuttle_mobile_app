// ===============================================================
// trip_details_dialog.dart
// ---------------------------------------------------------------
// Trip Details Dialog
//
// PURPOSE
// ---------------------------------------------------------------
// Displays complete booking information with action buttons.
// ===============================================================

import 'package:flutter/material.dart';

import '../../../models/trip_model.dart';
import 'cancellation_policy_dialog.dart';
import 'cancellation_preview_dialog.dart';

class TripDetailsDialog extends StatelessWidget {
  final TripModel trip;
  final Future<void> Function() onRefresh;

  const TripDetailsDialog({
    super.key,
    required this.trip,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final status = trip.bookingStatus.toUpperCase();

    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 650),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Column(
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Trip Details',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xff111827),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              _infoTile('Booking ID', trip.bookingId),
              _infoTile('Travel Date', trip.travelDate),
              _infoTile('Bus Number', trip.busNumber),
              _infoTile('Driver', trip.driverName),
              _infoTile('Driver Phone', trip.driverPhone),
              _infoTile('Time', trip.journeyTime),
              _infoTile('From', trip.fromStop),
              _infoTile('To', trip.toStop),
              _infoTile('Passenger', trip.passengerName),
              _infoTile('Email', trip.passengerEmail),
              _infoTile('Phone', trip.passengerPhone),
              _infoTile('Seats', trip.seatsBooked.toString()),
              _infoTile(
                'Fare / Seat',
                '₹${trip.farePerSeat.toStringAsFixed(0)}',
              ),
              _infoTile(
                'Total',
                '₹${trip.totalAmount.toStringAsFixed(0)}',
              ),
              _infoTile('Payment', trip.paymentStatus),
              _statusTile(status),
              _infoTile('Payment Method', trip.paymentType),
              _infoTile('Created At', trip.createdAt),

              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: _actionButton(
                      text: _cancelButtonText(),
                      color: Colors.red.shade300,
                      textColor: Colors.white,
                      onTap: _canCancel()
                        ? () {
                            showDialog(
                            context: context,
                            builder: (_) => CancellationPreviewDialog(
                                trip: trip,
                                onRefresh: onRefresh,
                            ),
                            );
                        }
                        : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _actionButton(
                      text: 'Send Email',
                      color: Colors.grey.shade200,
                      textColor: Colors.grey,
                      onTap: null,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: _actionButton(
                      text: 'Policy',
                      color: Colors.grey.shade200,
                      textColor: Colors.black87,
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (_) => const CancellationPolicyDialog(),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _actionButton(
                      text: 'Close',
                      color: const Color(0xff6B46C1),
                      textColor: Colors.white,
                      onTap: () => Navigator.pop(context),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoTile(String title, String value) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(
              '$title:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: Color(0xff111827),
              ),
            ),
          ),
          Expanded(
            flex: 6,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusTile(String status) {
    Color color = Colors.green;

    if (status == 'CANCELLED') color = Colors.red;
    if (status == 'HOLD') color = Colors.orange;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          const Expanded(
            flex: 4,
            child: Text(
              'Status:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: Color(0xff111827),
              ),
            ),
          ),
          Expanded(
            flex: 6,
            child: Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required String text,
    required Color color,
    required Color textColor,
    required VoidCallback? onTap,
  }) {
    return SizedBox(
      height: 54,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: textColor,
          disabledBackgroundColor: color,
          disabledForegroundColor: textColor,
          elevation: onTap == null ? 0 : 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  bool _canCancel() {
    return trip.bookingStatus.toUpperCase() == 'CONFIRMED' &&
        (trip.paymentStatus.toUpperCase() == 'SUCCESS' ||
            trip.paymentStatus.toUpperCase() == 'PAID');
  }

  String _cancelButtonText() {
    if (trip.bookingStatus.toUpperCase() == 'CANCELLED') {
      return 'Already Cancelled';
    }

    return 'Cancel Trip';
  }
}