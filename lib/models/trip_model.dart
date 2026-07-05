// ===============================================================
// trip_model.dart
// ---------------------------------------------------------------
// Trip Model
//
// PURPOSE
// ---------------------------------------------------------------
// Represents a single booking returned by getMyTrips API.
//
// USED BY
// ---------------------------------------------------------------
// • My Trips Screen
// • Trip Details Dialog
// • Cancellation
// • Live Tracking
// ===============================================================

class TripModel {
  final String bookingId;

  final String bookingDate;
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

  final String actualPickupTime;
  final String actualDropTime;

  final String passengerName;
  final String passengerEmail;
  final String passengerPhone;

  final int seatsBooked;

  final double farePerSeat;
  final double totalAmount;

  final String paymentStatus;
  final String paymentType;

  final String bookingStatus;

  final String createdAt;

  const TripModel({
    required this.bookingId,
    required this.bookingDate,
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
    required this.actualPickupTime,
    required this.actualDropTime,
    required this.passengerName,
    required this.passengerEmail,
    required this.passengerPhone,
    required this.seatsBooked,
    required this.farePerSeat,
    required this.totalAmount,
    required this.paymentStatus,
    required this.paymentType,
    required this.bookingStatus,
    required this.createdAt,
  });

  // =============================================================
  // JSON PARSER
  // =============================================================

  factory TripModel.fromJson(Map<String, dynamic> json) {
    return TripModel(
      bookingId: '${json['booking_id'] ?? ''}',
      bookingDate: '${json['booking_date'] ?? ''}',
      travelDate: '${json['travel_date'] ?? ''}',

      routeId: '${json['route_id'] ?? ''}',

      busId: '${json['bus_id'] ?? ''}',
      busNumber: '${json['bus_number'] ?? ''}',

      driverName: '${json['driver_name'] ?? ''}',
      driverPhone: '${json['driver_phone'] ?? ''}',

      fromStop: '${json['from_stop'] ?? ''}',
      toStop: '${json['to_stop'] ?? ''}',

      scheduledPickupTime: '${json['scheduled_pickup_time'] ?? ''}',
      scheduledDropTime: '${json['scheduled_drop_time'] ?? ''}',

      actualPickupTime: '${json['actual_pickup_time'] ?? ''}',
      actualDropTime: '${json['actual_drop_time'] ?? ''}',

      passengerName: '${json['passenger_name'] ?? ''}',
      passengerEmail: '${json['passenger_email'] ?? ''}',
      passengerPhone: '${json['passenger_phone'] ?? ''}',

      seatsBooked: int.tryParse('${json['seats_booked'] ?? 0}') ?? 0,

      farePerSeat:
          double.tryParse('${json['fare_per_seat'] ?? 0}') ?? 0,

      totalAmount:
          double.tryParse('${json['total_amount'] ?? 0}') ?? 0,

      paymentStatus: '${json['payment_status'] ?? ''}',
      paymentType: '${json['payment_type'] ?? ''}',

      bookingStatus: '${json['booking_status'] ?? ''}',

      createdAt: '${json['created_at'] ?? ''}',
    );
  }

  // =============================================================
  // HELPERS
  // =============================================================

  bool get isConfirmed =>
      bookingStatus.toUpperCase() == 'CONFIRMED';

  bool get isCancelled =>
      bookingStatus.toUpperCase() == 'CANCELLED';

  bool get isPaid =>
      paymentStatus.toUpperCase() == 'SUCCESS' ||
      paymentStatus.toUpperCase() == 'PAID';

  String get routeLabel =>
      '$fromStop → $toStop';

  String get journeyTime =>
      '$scheduledPickupTime → $scheduledDropTime';

    // =============================================================
    // DISPLAY HELPERS
    // =============================================================

    String get pickupTime {
    return actualPickupTime.isNotEmpty
        ? actualPickupTime
        : scheduledPickupTime;
    }

    String get dropTime {
    return actualDropTime.isNotEmpty
        ? actualDropTime
        : scheduledDropTime;
    }

    String get statusLabel => bookingStatus.toUpperCase();

    bool get canCancel => isConfirmed;

    bool get isPastTrip =>
        actualDropTime.isNotEmpty;

    String get formattedFare =>
        '₹${farePerSeat.toStringAsFixed(0)}';

    String get formattedTotal =>
        '₹${totalAmount.toStringAsFixed(0)}';
}