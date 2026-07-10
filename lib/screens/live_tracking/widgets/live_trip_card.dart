// ===============================================================
// live_trip_card.dart
// ---------------------------------------------------------------
// Live Trip Card
//
// PURPOSE
// ---------------------------------------------------------------
// Shows today's trackable trip card with route, timing,
// booking info and Track Now action.
// ===============================================================

import 'package:flutter/material.dart';

class LiveTripCard extends StatelessWidget {
  final Map<String, dynamic> trip;
  final String liveState;
  final String timeRange;
  final VoidCallback onTrackNow;

  const LiveTripCard({
    super.key,
    required this.trip,
    required this.liveState,
    required this.timeRange,
    required this.onTrackNow,
  });

  @override
  Widget build(BuildContext context) {
    final status = '${trip['booking_status'] ?? 'CONFIRMED'}'.toUpperCase();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xffE5E7EB),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _topSection(status),
          const SizedBox(height: 16),
          _infoGrid(context),
          const SizedBox(height: 18),
          Center(
            child: SizedBox(
              width: 230,
              height: 52,
              child: ElevatedButton(
                onPressed: onTrackNow,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff6B46C1),
                  foregroundColor: Colors.white,
                  elevation: 8,
                  shadowColor: const Color(0xff6B46C1)
                      .withValues(alpha: 0.35),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Track Now',
                  style: TextStyle(
                    fontSize: 17,
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

  Widget _topSection(String status) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${trip['from_stop'] ?? '-'} → ${trip['to_stop'] ?? '-'}',
          style: const TextStyle(
            color: Color(0xff111827),
            fontSize: 20,
            fontWeight: FontWeight.bold,
            height: 1.25,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          '${trip['travel_date'] ?? '-'} • $timeRange',
          style: const TextStyle(
            color: Color(0xff64748B),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 9,
          runSpacing: 9,
          children: [
            _liveBadge(),
            _statusBadge(status),
          ],
        ),
      ],
    );
  }

  Widget _liveBadge() {
    if (liveState == 'LIVE') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xffDCFCE7),
          borderRadius: BorderRadius.circular(22),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _BlinkingDot(),
            SizedBox(width: 7),
            Text(
              'LIVE',
              style: TextStyle(
                color: Color(0xff15803D),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    if (liveState == 'UPCOMING') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xffEEF2FF),
          borderRadius: BorderRadius.circular(22),
        ),
        child: const Text(
          'Upcoming',
          style: TextStyle(
            color: Color(0xff4F46E5),
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _statusBadge(String status) {
    Color bgColor = const Color(0xffDCFCE7);
    Color textColor = const Color(0xff166534);

    if (status == 'CANCELLED') {
      bgColor = const Color(0xffFEE2E2);
      textColor = const Color(0xffB91C1C);
    }

    if (status == 'HOLD') {
      bgColor = const Color(0xffFEF3C7);
      textColor = const Color(0xff92400E);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Text(
        status.isEmpty ? 'CONFIRMED' : status,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _infoGrid(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = constraints.maxWidth > 650
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
                value: '${trip['booking_id'] ?? '-'}',
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _infoBox(
                label: 'Bus',
                value: '${trip['bus_number'] ?? '-'}',
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _infoBox(
                label: 'Driver',
                value: '${trip['driver_name'] ?? '-'}',
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _infoBox(
                label: 'Seats',
                value: '${trip['seats_booked'] ?? '-'}',
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
          color: const Color(0xffE5E7EB),
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
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xff111827),
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _BlinkingDot extends StatefulWidget {
  const _BlinkingDot();

  @override
  State<_BlinkingDot> createState() => _BlinkingDotState();
}

class _BlinkingDotState extends State<_BlinkingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;
  late Animation<double> opacity;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true);

    opacity = Tween<double>(begin: 0.25, end: 1).animate(controller);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: opacity,
      child: Container(
        width: 9,
        height: 9,
        decoration: const BoxDecoration(
          color: Color(0xff22C55E),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}