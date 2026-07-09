// ===============================================================
// live_tracking_model.dart
// ---------------------------------------------------------------
// Live Tracking Model
//
// PURPOSE
// ---------------------------------------------------------------
// Holds booking, route progress and stop timeline data
// returned by getLiveTrackingDetails API.
// ===============================================================

class LiveTrackingModel {
  final bool success;
  final LiveBooking booking;
  final String tripStatus;
  final int reachedCount;
  final int totalStops;
  final List<LiveStop> stops;

  const LiveTrackingModel({
    required this.success,
    required this.booking,
    required this.tripStatus,
    required this.reachedCount,
    required this.totalStops,
    required this.stops,
  });

  factory LiveTrackingModel.fromJson(Map<String, dynamic> json) {
    return LiveTrackingModel(
      success: json['success'] == true,
      booking: LiveBooking.fromJson(
        Map<String, dynamic>.from(json['booking'] ?? {}),
      ),
      tripStatus: '${json['trip_status'] ?? 'NOT_STARTED'}',
      reachedCount: int.tryParse('${json['reached_count'] ?? 0}') ?? 0,
      totalStops: int.tryParse('${json['total_stops'] ?? 0}') ?? 0,
      stops: ((json['stops'] ?? []) as List)
          .map(
            (e) => LiveStop.fromJson(
              Map<String, dynamic>.from(e),
            ),
          )
          .toList(),
    );
  }

  LiveTrackingSummary get summary {
    final reachedStops = stops.where((stop) {
      return stop.stopStatus.toUpperCase() == 'REACHED';
    }).toList();

    final reached = reachedStops.length;
    final total = stops.length;

    String status = 'NOT_STARTED';

    if (reached == 0) {
      status = 'NOT_STARTED';
    } else if (reached < total) {
      status = 'IN_PROGRESS';
    } else if (reached == total && total > 0) {
      status = 'COMPLETED';
    }

    final LiveStop? currentStop = reachedStops.isNotEmpty
        ? reachedStops[reachedStops.length - 1]
        : null;

    LiveStop? nextStop;

    if (reached == 0 && stops.isNotEmpty) {
      nextStop = stops.first;
    } else {
      for (final stop in stops) {
        if (stop.stopStatus.toUpperCase() != 'REACHED') {
          nextStop = stop;
          break;
        }
      }
    }

    final progressPercent = total > 0 ? ((reached / total) * 100).round() : 0;

    String lastUpdatedAt = '';

    for (final stop in reachedStops) {
      if (stop.updatedAt.isNotEmpty) {
        lastUpdatedAt = formatDateTime(stop.updatedAt);
      } else if (stop.actualReachedTime.isNotEmpty) {
        lastUpdatedAt = formatDateTime(stop.actualReachedTime);
      }
    }

    return LiveTrackingSummary(
      totalStops: total,
      reachedCount: reached,
      currentStop: currentStop,
      nextStop: nextStop,
      progressPercent: progressPercent,
      tripStatus: status,
      lastUpdatedAt: lastUpdatedAt,
    );
  }

  String etaText() {
    final trackingSummary = summary;

    if (trackingSummary.tripStatus == 'COMPLETED') {
      return 'Trip completed';
    }

    if (trackingSummary.nextStop == null) {
      return 'Waiting for next update';
    }

    if (booking.travelDate.isEmpty ||
        trackingSummary.nextStop!.scheduledArrivalTime.isEmpty) {
      return 'ETA unavailable';
    }

    final scheduledTime =
        formatTimeOnly(trackingSummary.nextStop!.scheduledArrivalTime);

    final targetTime = DateTime.tryParse(
      '${booking.travelDate}T$scheduledTime:00',
    );

    if (targetTime == null) {
      return 'Expected at $scheduledTime';
    }

    final now = DateTime.now();
    final diffMinutes = targetTime.difference(now).inMinutes.round();

    if (trackingSummary.tripStatus == 'NOT_STARTED') {
      if (diffMinutes > 0) {
        return 'Trip starts in ${formatMinutes(diffMinutes)}';
      }

      return 'Scheduled at $scheduledTime';
    }

    if (diffMinutes > 0) {
      return 'Next stop in ${formatMinutes(diffMinutes)}';
    }

    if (diffMinutes >= -5) {
      return 'Arriving shortly';
    }

    return 'Scheduled ${diffMinutes.abs()} min ago';
  }

  static String formatMinutes(int minutes) {
    if (minutes < 60) {
      return '$minutes min';
    }

    final hours = minutes ~/ 60;
    final mins = minutes % 60;

    if (mins == 0) {
      return '$hours hr';
    }

    return '$hours hr $mins min';
  }

  static String formatDateTime(dynamic value) {
    if (value == null) return '';

    final str = '$value'.trim();

    if (str.isEmpty) return '';

    if (str.contains(' ') && str.contains(':')) {
      final parts = str.split(' ');
      if (parts.length >= 2) {
        return '${parts[0]} ${formatTimeOnly(parts[1])}';
      }
    }

    if (str.contains('T')) {
      final parsed = DateTime.tryParse(str);

      if (parsed != null) {
        final year = parsed.year.toString().padLeft(4, '0');
        final month = parsed.month.toString().padLeft(2, '0');
        final day = parsed.day.toString().padLeft(2, '0');
        final hour = parsed.hour.toString().padLeft(2, '0');
        final minute = parsed.minute.toString().padLeft(2, '0');

        return '$year-$month-$day $hour:$minute';
      }
    }

    return str;
  }

  static String formatTimeOnly(dynamic value) {
    if (value == null) return '';

    final str = '$value'.trim();

    if (str.isEmpty) return '';

    if (str.contains('T')) {
      final parsed = DateTime.tryParse(str);

      if (parsed != null) {
        final hour = parsed.hour.toString().padLeft(2, '0');
        final minute = parsed.minute.toString().padLeft(2, '0');

        return '$hour:$minute';
      }
    }

    if (str.contains(' ')) {
      final parts = str.split(' ');
      if (parts.length >= 2) {
        return formatTimeOnly(parts[1]);
      }
    }

    final parts = str.split(':');

    if (parts.length >= 2) {
      return '${parts[0]}:${parts[1]}';
    }

    return str;
  }
}

class LiveBooking {
  final String bookingId;
  final String travelDate;
  final String routeId;
  final String busId;
  final String busNumber;
  final String driverName;
  final String driverPhone;
  final String fromStop;
  final String toStop;
  final String scheduledPickupTime;
  final String scheduledDropTime;
  final String passengerName;
  final String passengerEmail;
  final String passengerPhone;
  final String seatsBooked;
  final String bookingStatus;
  final String paymentStatus;

  const LiveBooking({
    required this.bookingId,
    required this.travelDate,
    required this.routeId,
    required this.busId,
    required this.busNumber,
    required this.driverName,
    required this.driverPhone,
    required this.fromStop,
    required this.toStop,
    required this.scheduledPickupTime,
    required this.scheduledDropTime,
    required this.passengerName,
    required this.passengerEmail,
    required this.passengerPhone,
    required this.seatsBooked,
    required this.bookingStatus,
    required this.paymentStatus,
  });

  factory LiveBooking.fromJson(Map<String, dynamic> json) {
    return LiveBooking(
      bookingId: '${json['booking_id'] ?? ''}',
      travelDate: '${json['travel_date'] ?? ''}',
      routeId: '${json['route_id'] ?? ''}',
      busId: '${json['bus_id'] ?? ''}',
      busNumber: '${json['bus_number'] ?? ''}',
      driverName: '${json['driver_name'] ?? ''}',
      driverPhone: '${json['driver_phone'] ?? ''}',
      fromStop: '${json['from_stop'] ?? ''}',
      toStop: '${json['to_stop'] ?? ''}',
      scheduledPickupTime:
          LiveTrackingModel.formatTimeOnly(json['scheduled_pickup_time']),
      scheduledDropTime:
          LiveTrackingModel.formatTimeOnly(json['scheduled_drop_time']),
      passengerName: '${json['passenger_name'] ?? ''}',
      passengerEmail: '${json['passenger_email'] ?? ''}',
      passengerPhone: '${json['passenger_phone'] ?? ''}',
      seatsBooked: '${json['seats_booked'] ?? ''}',
      bookingStatus: '${json['booking_status'] ?? ''}',
      paymentStatus: '${json['payment_status'] ?? ''}',
    );
  }
}

class LiveStop {
  final String stopId;
  final String stopName;
  final int stopOrder;
  final String city;
  final String scheduledArrivalTime;
  final String actualReachedTime;
  final String stopStatus;
  final String entryMode;
  final String updatedAt;

  const LiveStop({
    required this.stopId,
    required this.stopName,
    required this.stopOrder,
    required this.city,
    required this.scheduledArrivalTime,
    required this.actualReachedTime,
    required this.stopStatus,
    required this.entryMode,
    required this.updatedAt,
  });

  factory LiveStop.fromJson(Map<String, dynamic> json) {
    return LiveStop(
      stopId: '${json['stop_id'] ?? ''}',
      stopName: '${json['stop_name'] ?? ''}',
      stopOrder: int.tryParse('${json['stop_order'] ?? 0}') ?? 0,
      city: '${json['city'] ?? ''}',
      scheduledArrivalTime:
          LiveTrackingModel.formatTimeOnly(json['scheduled_arrival_time']),
      actualReachedTime:
          LiveTrackingModel.formatDateTime(json['actual_reached_time']),
      stopStatus: '${json['stop_status'] ?? 'PENDING'}',
      entryMode: '${json['entry_mode'] ?? ''}',
      updatedAt: LiveTrackingModel.formatDateTime(json['updated_at']),
    );
  }
}

class LiveTrackingSummary {
  final int totalStops;
  final int reachedCount;
  final LiveStop? currentStop;
  final LiveStop? nextStop;
  final int progressPercent;
  final String tripStatus;
  final String lastUpdatedAt;

  const LiveTrackingSummary({
    required this.totalStops,
    required this.reachedCount,
    required this.currentStop,
    required this.nextStop,
    required this.progressPercent,
    required this.tripStatus,
    required this.lastUpdatedAt,
  });
}