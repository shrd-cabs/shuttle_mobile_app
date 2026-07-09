// ===============================================================
// tracking_stop_card.dart
// ---------------------------------------------------------------
// Tracking Stop Card
//
// PURPOSE
// ---------------------------------------------------------------
// Shows each stop in the live tracking timeline.
// Handles REACHED / NEXT / PENDING / CURRENT states.
// ===============================================================

import 'package:flutter/material.dart';

import '../../../models/live_tracking_model.dart';

class TrackingStopCard extends StatelessWidget {
  final LiveStop stop;
  final LiveTrackingSummary summary;

  const TrackingStopCard({
    super.key,
    required this.stop,
    required this.summary,
  });

  @override
  Widget build(BuildContext context) {
    final stopStatus = stop.stopStatus.toUpperCase();

    final isReached = stopStatus == 'REACHED';

    final isNext = summary.nextStop != null &&
        summary.nextStop!.stopId == stop.stopId;

    final isCurrent = summary.currentStop != null &&
        summary.currentStop!.stopId == stop.stopId;

    String label = 'Upcoming';
    String marker = '○';

    Color markerBg = const Color(0xffE5E7EB);
    Color markerText = const Color(0xff64748B);
    Color borderColor = const Color(0xffE5E7EB);
    Color cardBg = Colors.white;
    Color statusBg = const Color(0xffF1F5F9);
    Color statusText = const Color(0xff64748B);

    if (isReached) {
      label = 'Reached';
      marker = '✓';

      markerBg = const Color(0xffDCFCE7);
      markerText = const Color(0xff15803D);
      borderColor = const Color(0xffBBF7D0);
      cardBg = const Color(0xffF0FDF4);
      statusBg = const Color(0xffDCFCE7);
      statusText = const Color(0xff15803D);
    }

    if (!isReached && isNext) {
      label = summary.tripStatus == 'NOT_STARTED'
          ? 'First Stop'
          : 'Next Stop';

      marker = '➜';

      markerBg = const Color(0xffEDE9FE);
      markerText = const Color(0xff6B46C1);
      borderColor = const Color(0xffC4B5FD);
      cardBg = const Color(0xffFAF7FF);
      statusBg = const Color(0xffEDE9FE);
      statusText = const Color(0xff6B46C1);
    }

    if (isCurrent) {
      borderColor = const Color(0xff22C55E);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _marker(
            marker: marker,
            backgroundColor: markerBg,
            textColor: markerText,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: borderColor,
                  width: isCurrent ? 1.6 : 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _mainRow(
                    label: label,
                    statusBg: statusBg,
                    statusText: statusText,
                  ),
                  const SizedBox(height: 12),
                  _metaRow(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _marker({
    required String marker,
    required Color backgroundColor,
    required Color textColor,
  }) {
    return Container(
      width: 34,
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        border: Border.all(
          color: textColor.withValues(alpha: 0.28),
        ),
      ),
      child: Text(
        marker,
        style: TextStyle(
          color: textColor,
          fontSize: 17,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _mainRow({
    required String label,
    required Color statusBg,
    required Color statusText,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                stop.stopName.isEmpty ? '-' : stop.stopName,
                style: const TextStyle(
                  color: Color(0xff111827),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  height: 1.25,
                ),
              ),
              if (stop.city.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  stop.city,
                  style: const TextStyle(
                    color: Color(0xff64748B),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: statusBg,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: statusText,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _metaRow() {
    return Wrap(
      spacing: 14,
      runSpacing: 8,
      children: [
        _metaItem(
          label: 'Scheduled',
          value: stop.scheduledArrivalTime.isEmpty
              ? '-'
              : stop.scheduledArrivalTime,
        ),
        _metaItem(
          label: 'Actual',
          value: stop.actualReachedTime.isEmpty
              ? '-'
              : stop.actualReachedTime,
        ),
      ],
    );
  }

  Widget _metaItem({
    required String label,
    required String value,
  }) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: '$label: ',
            style: const TextStyle(
              color: Color(0xff64748B),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          TextSpan(
            text: value,
            style: const TextStyle(
              color: Color(0xff111827),
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}