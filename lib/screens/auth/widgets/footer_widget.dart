// ===============================================================
// footer_widget.dart
// ---------------------------------------------------------------
// Authentication Footer
//
// PURPOSE
// ---------------------------------------------------------------
// Displays application copyright
// and company information.
//
// NOTES
// ---------------------------------------------------------------
// - Matches website design
// - Responsive for all devices
// ===============================================================

import 'package:flutter/material.dart';

class FooterWidget extends StatelessWidget {
  const FooterWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 10, 24, 30),
      child: Column(
        children: [
          Divider(
            color: Colors.grey.shade300,
            thickness: 1,
          ),

          const SizedBox(height: 18),

          Text(
            '© SHRD Shuttle Booking',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            'Shri Radhey Travel Services',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}