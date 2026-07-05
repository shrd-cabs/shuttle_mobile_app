// ===============================================================
// my_trips_screen.dart
// ---------------------------------------------------------------
// My Trips Screen
//
// PURPOSE
// ---------------------------------------------------------------
// Displays user's Current, Upcoming and Past bookings.
// ===============================================================

import 'package:flutter/material.dart';

import '../../models/trip_model.dart';
import '../../services/my_trip_service.dart';
import '../../services/storage_service.dart';

import 'widgets/empty_trip_widget.dart';
import 'widgets/trip_card.dart';
import 'widgets/trip_tabs.dart';

class MyTripsScreen extends StatefulWidget {
  const MyTripsScreen({super.key});

  @override
  State<MyTripsScreen> createState() => _MyTripsScreenState();
}

class _MyTripsScreenState extends State<MyTripsScreen> {
  final myTripService = MyTripService();
  final storageService = StorageService();

  bool isLoading = true;
  int selectedTab = 0;

  List<TripModel> currentTrips = [];
  List<TripModel> upcomingTrips = [];
  List<TripModel> pastTrips = [];

  @override
  void initState() {
    super.initState();
    loadTrips();
  }

  Future<void> loadTrips() async {
    try {
      final user = await storageService.getCurrentUser();

      if (user == null) {
        setState(() => isLoading = false);
        showMessage('Please login again');
        return;
      }

      final result = await myTripService.getMyTrips(
        email: user['email'],
      );

      if (!mounted) return;

      setState(() {
        currentTrips = result.currentTrips;
        upcomingTrips = result.upcomingTrips;
        pastTrips = result.pastTrips;
        isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() => isLoading = false);
      showMessage(error.toString());
    }
  }

  List<TripModel> get selectedTrips {
    if (selectedTab == 0) return currentTrips;
    if (selectedTab == 1) return upcomingTrips;
    return pastTrips;
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return Column(
      children: [
        TripTabs(
          selectedIndex: selectedTab,
          onChanged: (index) {
            setState(() => selectedTab = index);
          },
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: loadTrips,
            child: selectedTrips.isEmpty
                ? const EmptyTripWidget()
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: selectedTrips.length,
                    itemBuilder: (context, index) {
                      return TripCard(
                        trip: selectedTrips[index],
                        onRefresh: loadTrips,
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }
}