// ===============================================================
// route_model.dart
// ---------------------------------------------------------------
// Route Model
//
// PURPOSE
// ---------------------------------------------------------------
// Represents one available route returned by searchRoutes API.
// ===============================================================

class RouteModel {
  final String routeId;
  final String routeName;
  final String arrivalTime;
  final String reachingTime;
  final int availableSeats;
  final double farePerSeat;
  final double totalAmount;
  final String busId;
  final String busNumber;
  final String driverName;
  final String driverPhone;

  const RouteModel({
    required this.routeId,
    required this.routeName,
    required this.arrivalTime,
    required this.reachingTime,
    required this.availableSeats,
    required this.farePerSeat,
    required this.totalAmount,
    required this.busId,
    required this.busNumber,
    required this.driverName,
    required this.driverPhone,
  });

  factory RouteModel.fromJson(Map<String, dynamic> json) {
    return RouteModel(
      routeId: '${json['route_id'] ?? ''}',
      routeName: '${json['route_name'] ?? '-'}',
      arrivalTime: '${json['arrivalTime_at_pickup'] ?? '-'}',
      reachingTime: '${json['reachingTime_at_drop'] ?? '-'}',
      availableSeats: int.tryParse('${json['available_seats'] ?? 0}') ?? 0,
      farePerSeat: double.tryParse('${json['fare_per_seat'] ?? 0}') ?? 0,
      totalAmount: double.tryParse('${json['total_amount'] ?? 0}') ?? 0,
      busId: '${json['bus_id'] ?? ''}',
      busNumber: '${json['bus_number'] ?? '-'}',
      driverName: '${json['driver_name'] ?? '-'}',
      driverPhone: '${json['driver_phone'] ?? '-'}',
    );
  }
}