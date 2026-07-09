// ===============================================================
// tracking_progress_card.dart
// ---------------------------------------------------------------
// Tracking Progress Card
//
// PURPOSE
// ---------------------------------------------------------------
// Shows live route progress, current stop, next stop and ETA/status.
// ===============================================================

import 'package:flutter/material.dart';

import '../../../models/live_tracking_model.dart';

class TrackingProgressCard extends StatelessWidget {
  final LiveTrackingModel tracking;

  const TrackingProgressCard({
    super.key,
    required this.tracking,
  });

  @override
  Widget build(BuildContext context) {
    final summary = tracking.summary;
    final etaText = tracking.etaText();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xffF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xffE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _top(summary),
          const SizedBox(height: 14),
          _progressBar(summary.progressPercent),
          const SizedBox(height: 18),
          _currentGrid(context, summary, etaText),
        ],
      ),
    );
  }

  Widget _top(
    LiveTrackingSummary summary,
  ) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${summary.progressPercent}% Completed',
                style: const TextStyle(
                  color: Color(0xff111827),
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${summary.reachedCount} of ${summary.totalStops} stops reached',
                style: const TextStyle(
                  color: Color(0xff64748B),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const _LivePulseDot(),
      ],
    );
  }

  Widget _progressBar(
    int progressPercent,
  ) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(99),
      child: Container(
        width: double.infinity,
        height: 12,
        color: const Color(0xffE5E7EB),
        child: FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: progressPercent.clamp(0, 100) / 100,
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xff6B46C1),
            ),
          ),
        ),
      ),
    );
  }

  Widget _currentGrid(
    BuildContext context,
    LiveTrackingSummary summary,
    String etaText,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = constraints.maxWidth > 700
            ? (constraints.maxWidth - 24) / 3
            : constraints.maxWidth;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: itemWidth,
              child: _currentBox(
                label: 'Current Stop',
                value: summary.tripStatus == 'NOT_STARTED'
                    ? 'Trip not started'
                    : summary.currentStop?.stopName ?? '-',
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _currentBox(
                label: 'Next Stop',
                value: summary.nextStop?.stopName ?? 'Trip completed',
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _currentBox(
                label: 'ETA / Status',
                value: etaText,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _currentBox({
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
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
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xff111827),
              fontSize: 15,
              fontWeight: FontWeight.bold,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }
}

class _LivePulseDot extends StatefulWidget {
  const _LivePulseDot();

  @override
  State<_LivePulseDot> createState() => _LivePulseDotState();
}

class _LivePulseDotState extends State<_LivePulseDot>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;
  late Animation<double> scale;
  late Animation<double> opacity;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      duration: const Duration(milliseconds: 1100),
      vsync: this,
    )..repeat(reverse: true);

    scale = Tween<double>(begin: 0.75, end: 1.15).animate(controller);
    opacity = Tween<double>(begin: 0.45, end: 1).animate(controller);
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
      child: ScaleTransition(
        scale: scale,
        child: Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: const Color(0xff22C55E),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xff22C55E).withValues(alpha: 0.45),
                blurRadius: 12,
                spreadRadius: 4,
              ),
            ],
          ),
        ),
      ),
    );
  }
}