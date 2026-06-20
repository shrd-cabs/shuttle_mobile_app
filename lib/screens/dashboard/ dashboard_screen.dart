// ===============================================================
// dashboard_screen.dart
// ---------------------------------------------------------------
// Dashboard Screen
//
// PURPOSE
// ---------------------------------------------------------------
// Temporary screen after successful login.
//
// NOTES
// ---------------------------------------------------------------
// Booking screen will replace this later.
// ===============================================================

import 'package:flutter/material.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SHRD'),
        backgroundColor: const Color(0xff6B46C1),
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text(
          'Dashboard Coming Soon',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}