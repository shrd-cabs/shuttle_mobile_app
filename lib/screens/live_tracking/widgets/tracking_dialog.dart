// ===============================================================
// tracking_dialog.dart
// ---------------------------------------------------------------
// Tracking Dialog
//
// PURPOSE
// ---------------------------------------------------------------
// Shows full live tracking route progress popup.
// Auto-refresh is handled by parent screen.
// ===============================================================

import 'package:flutter/material.dart';

import '../../../models/live_tracking_model.dart';
import 'tracking_progress_card.dart';
import 'tracking_stop_card.dart';

class TrackingDialog extends StatelessWidget {
  final LiveTrackingModel tracking;
  final bool isRefreshing;
  final VoidCallback onRefresh;
  final VoidCallback onClose;

  const TrackingDialog({
    super.key,
    required this.tracking,
    required this.isRefreshing,
    required this.onRefresh,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final booking = tracking.booking;
    final summary = tracking.summary;

    return Dialog(
      insetPadding: const EdgeInsets.all(14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _header(),
              const SizedBox(height: 18),
              _routeTitle(booking),
              const SizedBox(height: 14),
              _statusStrip(booking, summary),
              const SizedBox(height: 18),
              TrackingProgressCard(
                tracking: tracking,
              ),
              const SizedBox(height: 18),
              _bookingInfo(booking, summary),
              const SizedBox(height: 20),
              _timeline(summary),
              const SizedBox(height: 20),
              _actions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Live Tracking',
                style: TextStyle(
                  color: Color(0xff111827),
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Auto-refreshing every 30 seconds',
                style: TextStyle(
                  color: Color(0xff64748B),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: onClose,
          icon: const Icon(Icons.close),
        ),
      ],
    );
  }

  Widget _routeTitle(
    LiveBooking booking,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xffFAF7FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xffE5D8FF),
        ),
      ),
      child: Text(
        '${booking.fromStop.isEmpty ? '-' : booking.fromStop} → ${booking.toStop.isEmpty ? '-' : booking.toStop}',
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Color(0xff6B46C1),
          fontSize: 18,
          fontWeight: FontWeight.bold,
          height: 1.35,
        ),
      ),
    );
  }

  Widget _statusStrip(
    LiveBooking booking,
    LiveTrackingSummary summary,
  ) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      alignment: WrapAlignment.center,
      children: [
        _tripStatusBadge(summary.tripStatus),
        _stripBadge('Bus ${booking.busNumber.isEmpty ? '-' : booking.busNumber}'),
        _stripBadge(
          '${booking.scheduledPickupTime.isEmpty ? '-' : booking.scheduledPickupTime} - ${booking.scheduledDropTime.isEmpty ? '-' : booking.scheduledDropTime}',
        ),
      ],
    );
  }

  Widget _tripStatusBadge(
    String status,
  ) {
    final cleanStatus = status.toUpperCase();

    String label = 'Not Started';
    Color bg = const Color(0xffEEF2FF);
    Color text = const Color(0xff4F46E5);

    if (cleanStatus == 'IN_PROGRESS') {
      label = 'In Progress';
      bg = const Color(0xffDCFCE7);
      text = const Color(0xff15803D);
    }

    if (cleanStatus == 'COMPLETED') {
      label = 'Completed';
      bg = const Color(0xffE5E7EB);
      text = const Color(0xff374151);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: text,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _stripBadge(
    String text,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xffF1F5F9),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xffE2E8F0),
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xff334155),
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _bookingInfo(
    LiveBooking booking,
    LiveTrackingSummary summary,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = constraints.maxWidth > 700
            ? (constraints.maxWidth - 36) / 4
            : (constraints.maxWidth - 12) / 2;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: itemWidth,
              child: _infoBox(
                label: 'Booking ID',
                value: booking.bookingId.isEmpty ? '-' : booking.bookingId,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _infoBox(
                label: 'Driver',
                value: booking.driverName.isEmpty ? '-' : booking.driverName,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _infoBox(
                label: 'Driver Phone',
                value: booking.driverPhone.isEmpty ? '-' : booking.driverPhone,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _infoBox(
                label: 'Last Updated',
                value: summary.lastUpdatedAt.isEmpty
                    ? 'Waiting for first update'
                    : summary.lastUpdatedAt,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _infoBox({
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xffF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xffE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xff64748B),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xff111827),
              fontSize: 14,
              fontWeight: FontWeight.bold,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }

  Widget _timeline(
    LiveTrackingSummary summary,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Route Timeline',
          style: TextStyle(
            color: Color(0xff111827),
            fontSize: 19,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 14),
        ...tracking.stops.map(
          (stop) => TrackingStopCard(
            stop: stop,
            summary: summary,
          ),
        ),
      ],
    );
  }

  Widget _actions() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton(
            onPressed: isRefreshing ? null : onRefresh,
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xff6B46C1),
              side: const BorderSide(
                color: Color(0xff6B46C1),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(13),
              ),
            ),
            child: isRefreshing
                ? const SizedBox(
                    width: 21,
                    height: 21,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                    ),
                  )
                : const Text(
                    'Refresh Now',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: onClose,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xff6B46C1),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(13),
              ),
            ),
            child: const Text(
              'Close',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}