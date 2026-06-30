// ===============================================================
// main_content_screen.dart
// ---------------------------------------------------------------
// Main Content Screen
//
// PURPOSE
// ---------------------------------------------------------------
// Displays the main app area after successful login:
// 1. Header
// 2. Navigation tabs
// 3. Book Seat
// 4. My Trips
// 5. Travel Pass
// 6. Live Tracking
// ===============================================================

import 'package:flutter/material.dart';
import '../booking/booking_screen.dart';

class MainContentScreen extends StatefulWidget {
  const MainContentScreen({super.key});

  @override
  State<MainContentScreen> createState() => _MainContentScreenState();
}

class _MainContentScreenState extends State<MainContentScreen> {
  int selectedTabIndex = 0;

  final List<String> tabs = [
    'Book Seat',
    'My Trips',
    'Travel Pass',
    'Live Tracking',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildTabs(),
            Expanded(
                child: selectedTabIndex == 0
                    ? const BookingScreen()
                    : Center(
                        child: Text(
                            '${tabs[selectedTabIndex]} Screen',
                            style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            ),
                        ),
                        ),
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      color: const Color(0xff6B46C1),
      child: Column(
        children: [
          Image.asset(
            'assets/images/logo.jpeg',
            width: 70,
            height: 70,
          ),
          const SizedBox(height: 10),
          const Text(
            'SHRD Shuttle Booking',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Text(
            'Shri Radhey Travel Services',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _chip('💰 ₹0'),
              const SizedBox(width: 12),
              _chip('Logout'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .18),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: Colors.white.withValues(alpha: .35),
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildTabs() {
    return Row(
      children: List.generate(tabs.length, (index) {
        final isActive = selectedTabIndex == index;

        return Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                selectedTabIndex = index;
              });
            },
            child: Container(
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(
                    color: isActive
                        ? const Color(0xff6B46C1)
                        : Colors.grey.shade300,
                    width: isActive ? 3 : 1,
                  ),
                ),
              ),
              child: Text(
                tabs[index],
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isActive
                      ? const Color(0xff6B46C1)
                      : Colors.grey.shade700,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}