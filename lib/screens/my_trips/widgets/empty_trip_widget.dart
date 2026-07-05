// ===============================================================
// empty_trip_widget.dart
// ---------------------------------------------------------------
// Empty Trip Widget
//
// PURPOSE
// ---------------------------------------------------------------
// Displayed when no trips are available.
// ===============================================================

import 'package:flutter/material.dart';

class EmptyTripWidget extends StatelessWidget {
  const EmptyTripWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: const [
        SizedBox(height: 120),
        Icon(
          Icons.luggage_outlined,
          size: 80,
          color: Colors.grey,
        ),
        SizedBox(height: 18),
        Center(
          child: Text(
            'No Trips Found',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xff555555),
            ),
          ),
        ),
        SizedBox(height: 8),
        Center(
          child: Text(
            'Your bookings will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey,
              fontSize: 15,
            ),
          ),
        ),
      ],
    );
  }
}