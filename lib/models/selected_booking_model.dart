// ===============================================================
// selected_booking_model.dart
// ---------------------------------------------------------------
// Selected Booking Model
//
// PURPOSE
// ---------------------------------------------------------------
// Holds selected one-way or round-trip booking data before payment.
// ===============================================================

import 'route_model.dart';

class SelectedBookingModel {
  final String tripType;
  final String travelDate;
  final int pax;
  final String fromStop;
  final String toStop;
  final RouteModel? oneWayRoute;
  final RouteModel? onwardRoute;
  final RouteModel? returnRoute;

  const SelectedBookingModel({
    required this.tripType,
    required this.travelDate,
    required this.pax,
    required this.fromStop,
    required this.toStop,
    this.oneWayRoute,
    this.onwardRoute,
    this.returnRoute,
  });

  double get originalAmount {
    if (tripType == 'ROUNDTRIP') {
      return (onwardRoute?.totalAmount ?? 0) + (returnRoute?.totalAmount ?? 0);
    }

    return oneWayRoute?.totalAmount ?? 0;
  }

  String get routeIdForPass {
    if (tripType == 'ROUNDTRIP') {
      return onwardRoute?.routeId ?? '';
    }

    return oneWayRoute?.routeId ?? '';
  }

  String get journeyLabel {
    if (tripType == 'ROUNDTRIP') {
      return '$fromStop → $toStop | $toStop → $fromStop';
    }

    return '$fromStop → $toStop';
  }

  bool get isValid {
    if (tripType == 'ROUNDTRIP') {
      return onwardRoute != null && returnRoute != null;
    }

    return oneWayRoute != null;
  }
}