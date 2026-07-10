// ===============================================================
// main_content_screen.dart
// ---------------------------------------------------------------
// Main Content Screen
//
// PURPOSE
// ---------------------------------------------------------------
// Displays the main app area after successful login.
// ===============================================================

import 'package:flutter/material.dart';

import '../../services/storage_service.dart';
import '../../services/wallet_service.dart';
import '../auth/auth_screen.dart';
import '../booking/booking_screen.dart';
import '../my_trips/my_trips_screen.dart';
import '../wallet/wallet_dialog.dart';
import '../travel_pass/travel_pass_screen.dart';
import '../live_tracking/live_tracking_screen.dart';

class MainContentScreen extends StatefulWidget {
  const MainContentScreen({super.key});

  @override
  State<MainContentScreen> createState() => _MainContentScreenState();
}

class _MainContentScreenState extends State<MainContentScreen> {
  final storageService = StorageService();
  final walletService = WalletService();

  int selectedTabIndex = 0;
  double walletBalance = 0;

  final List<String> tabs = [
    'Book Seat',
    'My Trips',
    'Travel Pass',
    'Live Tracking',
  ];

  @override
  void initState() {
    super.initState();
    loadUserWallet();
  }

  Future<void> loadUserWallet() async {
    final user = await storageService.getCurrentUser();

    if (user == null) return;

    final email = '${user['email'] ?? ''}';

    if (email.isEmpty) return;

    try {
      final balance = await walletService.getWalletBalance(
        email: email,
      );

      if (!mounted) return;

      setState(() {
        walletBalance = balance;
      });
    } catch (_) {
      setState(() {
        walletBalance =
            double.tryParse('${user['wallet_balance'] ?? 0}') ?? 0;
      });
    }
  }

  Future<void> logout() async {
    await storageService.clearCurrentUser();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => const AuthScreen(),
      ),
      (route) => false,
    );
  }

  Future<void> openWallet() async {
    await showDialog(
      context: context,
      builder: (context) {
        return WalletDialog(
          onWalletUpdated: loadUserWallet,
        );
      },
    );

    await loadUserWallet();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildTabs(),
            Expanded(
              child: _buildSelectedScreen(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedScreen() {
    switch (selectedTabIndex) {
      case 0:
        return const BookingScreen();

      case 1:
        return const MyTripsScreen();

      case 2:
        return TravelPassScreen(
          onWalletUpdated: loadUserWallet,
        );

      case 3:
        return const LiveTrackingScreen();

      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      color: const Color(0xff6B46C1),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xffC8B6FF),
                width: 4,
              ),
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/images/logo_header.jpeg',
                fit: BoxFit.cover,
              ),
            ),
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
              GestureDetector(
                onTap: openWallet,
                child: _chip(
                  '💰 ₹${walletBalance.toStringAsFixed(0)}',
                ),
              ),

              const SizedBox(width: 12),

              GestureDetector(
                onTap: logout,
                child: _chip('Logout'),
              ),
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
              setState(() => selectedTabIndex = index);
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