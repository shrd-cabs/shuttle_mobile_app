// ===============================================================
// live_tracking_screen.dart
// ---------------------------------------------------------------
// Live Tracking Screen
// ===============================================================

import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/live_tracking_model.dart';
import '../../services/live_tracking_service.dart';
import '../../services/storage_service.dart';
import 'widgets/live_trip_card.dart';
import 'widgets/tracking_dialog.dart';

class LiveTrackingScreen extends StatefulWidget {
  const LiveTrackingScreen({super.key});

  @override
  State<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends State<LiveTrackingScreen> {
  final liveTrackingService = LiveTrackingService();
  final storageService = StorageService();

  static const Duration refreshDuration = Duration(seconds: 25);

  final ValueNotifier<LiveTrackingModel?> trackingNotifier =
      ValueNotifier<LiveTrackingModel?>(null);

  final ValueNotifier<bool> refreshingNotifier = ValueNotifier<bool>(false);

  bool isLoading = true;
  bool isTrackingLoading = false;

  String userEmail = '';
  String selectedTrackingBookingId = '';

  Timer? liveTrackingRefreshTimer;

  List<Map<String, dynamic>> liveTrips = [];

  @override
  void initState() {
    super.initState();
    loadLiveTracking();
  }

  @override
  void dispose() {
    stopLiveTrackingAutoRefresh();
    trackingNotifier.dispose();
    refreshingNotifier.dispose();
    super.dispose();
  }

  Future<void> loadLiveTracking() async {
    try {
      final user = await storageService.getCurrentUser();

      if (user == null) {
        throw Exception('User not logged in');
      }

      userEmail = '${user['email'] ?? ''}';

      if (userEmail.isEmpty) {
        throw Exception('User not logged in');
      }

      setState(() => isLoading = true);

      final data = await liveTrackingService.getMyTripsForLiveTracking(
        email: userEmail,
      );

      final trips = liveTrackingService.parseCurrentTrips(data);
      final activeTrips = liveTrackingService.getTrackableTrips(trips);

      if (!mounted) return;

      setState(() {
        liveTrips = activeTrips;
        isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => isLoading = false);
      showMessage(error.toString());
    }
  }

  Future<void> loadLiveTrackingDetails(String bookingId) async {
    if (bookingId.isEmpty) {
      showMessage('Booking ID missing');
      return;
    }

    if (userEmail.isEmpty) {
      showMessage('User not logged in');
      return;
    }

    try {
      selectedTrackingBookingId = bookingId;

      setState(() => isTrackingLoading = true);

      showTrackingLoadingDialog();

      final tracking = await liveTrackingService.getLiveTrackingDetails(
        bookingId: bookingId,
        email: userEmail,
      );

      if (!mounted) return;

      trackingNotifier.value = tracking;

      Navigator.pop(context);

      setState(() => isTrackingLoading = false);

      openTrackingDialog();
      startLiveTrackingAutoRefresh();
    } catch (error) {
      stopLiveTrackingAutoRefresh();

      if (!mounted) return;

      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      setState(() => isTrackingLoading = false);
      showMessage(error.toString());
    }
  }

  Future<void> refreshSelectedTracking({
    bool manual = false,
  }) async {
    if (selectedTrackingBookingId.isEmpty || userEmail.isEmpty) {
      if (manual) {
        showMessage('Please select a trip first');
      }
      return;
    }

    try {
      refreshingNotifier.value = true;

      final tracking = await liveTrackingService.getLiveTrackingDetails(
        bookingId: selectedTrackingBookingId,
        email: userEmail,
      );

      trackingNotifier.value = tracking;
      refreshingNotifier.value = false;
    } catch (error) {
      refreshingNotifier.value = false;

      if (manual && mounted) {
        showMessage(error.toString());
      }
    }
  }

  void startLiveTrackingAutoRefresh() {
    stopLiveTrackingAutoRefresh();

    liveTrackingRefreshTimer = Timer.periodic(
      refreshDuration,
      (_) async {
        await refreshSelectedTracking();
      },
    );
  }

  void stopLiveTrackingAutoRefresh() {
    liveTrackingRefreshTimer?.cancel();
    liveTrackingRefreshTimer = null;
  }

  void showTrackingLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );
  }

  void openTrackingDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) {
        return ValueListenableBuilder<LiveTrackingModel?>(
          valueListenable: trackingNotifier,
          builder: (context, tracking, _) {
            if (tracking == null) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            return ValueListenableBuilder<bool>(
              valueListenable: refreshingNotifier,
              builder: (context, isRefreshing, _) {
                return TrackingDialog(
                  tracking: tracking,
                  isRefreshing: isRefreshing,
                  onRefresh: () async {
                    await refreshSelectedTracking(manual: true);
                  },
                  onClose: () {
                    stopLiveTrackingAutoRefresh();
                    Navigator.pop(context);
                  },
                );
              },
            );
          },
        );
      },
    ).then((_) {
      stopLiveTrackingAutoRefresh();
    });
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message.replaceFirst('Exception: ', '')),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xffF8FAFC),
      child: RefreshIndicator(
        onRefresh: loadLiveTracking,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 22, 16, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _title(),
              const SizedBox(height: 20),
              if (isLoading)
                _loadingCard()
              else if (liveTrips.isEmpty)
                _emptyState()
              else ...[
                _liveTripsHeader(),
                const SizedBox(height: 16),
                ...liveTrips.map(
                  (trip) {
                    final liveState = liveTrackingService.getTripLiveState(trip);
                    final timeRange =
                        liveTrackingService.formatLiveTripTimeRange(trip);

                    return LiveTripCard(
                      trip: trip,
                      liveState: liveState,
                      timeRange: timeRange,
                      onTrackNow: isTrackingLoading
                          ? () {}
                          : () => loadLiveTrackingDetails(
                                '${trip['booking_id'] ?? ''}',
                              ),
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _title() {
    return const Center(
      child: Column(
        children: [
          Text(
            'Live Tracking',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xff111827),
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Track your active shuttle trips in real time',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xff64748B),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _loadingCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 42, horizontal: 18),
      decoration: _cardDecoration(),
      child: const Column(
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            'Loading today\'s live trips...',
            style: TextStyle(
              color: Color(0xff64748B),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 42, horizontal: 22),
      decoration: _cardDecoration(),
      child: const Column(
        children: [
          Text('🚌', style: TextStyle(fontSize: 54)),
          SizedBox(height: 14),
          Text(
            'No active trip for live tracking',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xff111827),
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Your live tracking will appear here on your travel date before your trip ends.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xff64748B),
              fontSize: 14,
              height: 1.4,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _liveTripsHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Today\'s Trackable Trips',
                  style: TextStyle(
                    color: Color(0xff111827),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Select a trip to view live route progress.',
                  style: TextStyle(
                    color: Color(0xff64748B),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xff6B46C1),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Text(
              '${liveTrips.length} Trip${liveTrips.length > 1 ? 's' : ''}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xffE5E7EB)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }
}