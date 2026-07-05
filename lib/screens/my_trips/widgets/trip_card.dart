// ===============================================================
// trip_card.dart
// ---------------------------------------------------------------
// Trip Card Widget
//
// PURPOSE
// ---------------------------------------------------------------
// Displays a single booking card in My Trips.
// Opens Trip Details dialog on tap.
// ===============================================================

import 'package:flutter/material.dart';

import '../../../models/trip_model.dart';
import 'trip_details_dialog.dart';

class TripCard extends StatelessWidget {
  final TripModel trip;
  final Future<void> Function() onRefresh;

  const TripCard({
    super.key,
    required this.trip,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final status = trip.bookingStatus.toUpperCase();

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        showDialog(
          context: context,
          barrierDismissible: true,
          builder: (context) {
            return TripDetailsDialog(
              trip: trip,
              onRefresh: onRefresh,
            );
          },
        );
      },
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              trip.routeLabel,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xff111827),
              ),
            ),
            const SizedBox(height: 14),
            _row('Status:', _statusBadge(status)),
            _rowText('Date:', trip.travelDate),
            _rowText('Seats:', '${trip.seatsBooked}'),
            _rowText('Time:', trip.journeyTime),
            _rowText('Total:', '₹${trip.totalAmount.toStringAsFixed(0)}'),
          ],
        ),
      ),
    );
  }

  Widget _rowText(String title, String value) {
    return _row(
      title,
      Text(
        value,
        textAlign: TextAlign.right,
        style: const TextStyle(
          fontSize: 14,
          color: Color(0xff333333),
        ),
      ),
    );
  }

  Widget _row(String title, Widget child) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xff6B46C1),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: child,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String status) {
    Color color = Colors.grey;

    if (status == 'CONFIRMED') color = Colors.green;
    if (status == 'CANCELLED') color = Colors.red;
    if (status == 'HOLD') color = Colors.orange;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}