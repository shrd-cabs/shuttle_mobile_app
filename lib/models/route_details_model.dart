// ===============================================================
// route_details_model.dart
// ---------------------------------------------------------------
// Typed models for the getRouteDetails backend response.
//
// PURPOSE:
// ---------------------------------------------------------------
// Keeps raw JSON parsing outside the Flutter UI.
//
// API RESPONSE STRUCTURE:
// ---------------------------------------------------------------
// {
//   "success": true,
//   "route": {...},
//   "journey": {...},
//   "stops": [...]
// }
// ===============================================================


// ===============================================================
// MAIN RESPONSE MODEL
// ===============================================================
class RouteDetailsModel {
  final bool success;
  final String error;
  final RouteDetailsRoute route;
  final RouteDetailsJourney journey;
  final List<RouteDetailsStop> stops;

  const RouteDetailsModel({
    required this.success,
    required this.error,
    required this.route,
    required this.journey,
    required this.stops,
  });

  factory RouteDetailsModel.fromJson(
    Map<String, dynamic> json,
  ) {
    final rawStops = json['stops'];

    return RouteDetailsModel(
      success: json['success'] == true,
      error: '${json['error'] ?? ''}',
      route: RouteDetailsRoute.fromJson(
        _asMap(json['route']),
      ),
      journey: RouteDetailsJourney.fromJson(
        _asMap(json['journey']),
      ),
      stops: rawStops is List
          ? rawStops
              .whereType<Map>()
              .map(
                (item) => RouteDetailsStop.fromJson(
                  Map<String, dynamic>.from(item),
                ),
              )
              .toList()
          : const [],
    );
  }

  // Stops belonging to the selected passenger journey.
  List<RouteDetailsStop> get journeyStops {
    return stops
        .where((stop) => stop.isJourneyStop)
        .toList();
  }

  // Whether pickup and drop were successfully matched.
  bool get hasMatchedJourney {
    return journey.found && journeyStops.isNotEmpty;
  }

  // Stops to display in the main timeline.
  // Falls back to complete route if journey matching fails.
  List<RouteDetailsStop> get displayedStops {
    return hasMatchedJourney ? journeyStops : stops;
  }

  bool get hasAdditionalFullRouteStops {
    return hasMatchedJourney &&
        stops.length > journeyStops.length;
  }
}


// ===============================================================
// ROUTE SUMMARY
// ===============================================================
class RouteDetailsRoute {
  final String routeId;
  final String routeName;
  final String busId;
  final String busNumber;

  final String firstStopId;
  final String firstStop;

  final String lastStopId;
  final String lastStop;

  final String routeStartTime;
  final String routeEndTime;

  final int totalStops;
  final int? durationMinutes;

  const RouteDetailsRoute({
    required this.routeId,
    required this.routeName,
    required this.busId,
    required this.busNumber,
    required this.firstStopId,
    required this.firstStop,
    required this.lastStopId,
    required this.lastStop,
    required this.routeStartTime,
    required this.routeEndTime,
    required this.totalStops,
    required this.durationMinutes,
  });

  factory RouteDetailsRoute.fromJson(
    Map<String, dynamic> json,
  ) {
    return RouteDetailsRoute(
      routeId: _asString(json['route_id']),
      routeName: _asString(
        json['route_name'],
        fallback: 'Route Details',
      ),
      busId: _asString(json['bus_id']),
      busNumber: _asString(
        json['bus_number'],
        fallback: '-',
      ),
      firstStopId: _asString(
        json['first_stop_id'],
      ),
      firstStop: _asString(
        json['first_stop'],
        fallback: 'First stop',
      ),
      lastStopId: _asString(
        json['last_stop_id'],
      ),
      lastStop: _asString(
        json['last_stop'],
        fallback: 'Last stop',
      ),
      routeStartTime: _asString(
        json['route_start_time'],
      ),
      routeEndTime: _asString(
        json['route_end_time'],
      ),
      totalStops: _asInt(
        json['total_stops'],
      ),
      durationMinutes: _asNullableInt(
        json['duration_minutes'],
      ),
    );
  }
}


// ===============================================================
// SELECTED JOURNEY SUMMARY
// ===============================================================
class RouteDetailsJourney {
  final bool found;
  final String warning;

  final String fromStopId;
  final String fromStopName;

  final String toStopId;
  final String toStopName;

  final String pickupTime;
  final String dropTime;

  final int totalStops;
  final int? durationMinutes;

  const RouteDetailsJourney({
    required this.found,
    required this.warning,
    required this.fromStopId,
    required this.fromStopName,
    required this.toStopId,
    required this.toStopName,
    required this.pickupTime,
    required this.dropTime,
    required this.totalStops,
    required this.durationMinutes,
  });

  factory RouteDetailsJourney.fromJson(
    Map<String, dynamic> json,
  ) {
    return RouteDetailsJourney(
      found: json['found'] == true,
      warning: _asString(json['warning']),
      fromStopId: _asString(
        json['from_stop_id'],
      ),
      fromStopName: _asString(
        json['from_stop_name'],
      ),
      toStopId: _asString(
        json['to_stop_id'],
      ),
      toStopName: _asString(
        json['to_stop_name'],
      ),
      pickupTime: _asString(
        json['pickup_time'],
      ),
      dropTime: _asString(
        json['drop_time'],
      ),
      totalStops: _asInt(
        json['total_stops'],
      ),
      durationMinutes: _asNullableInt(
        json['duration_minutes'],
      ),
    );
  }
}


// ===============================================================
// ONE ROUTE STOP
// ===============================================================
class RouteDetailsStop {
  final String tripId;
  final String stopId;
  final String stopName;
  final String arrivalTime;
  final int stopOrder;
  final String tripName;
  final String busId;
  final String city;

  final bool isJourneyStop;
  final bool isPickup;
  final bool isDrop;

  const RouteDetailsStop({
    required this.tripId,
    required this.stopId,
    required this.stopName,
    required this.arrivalTime,
    required this.stopOrder,
    required this.tripName,
    required this.busId,
    required this.city,
    required this.isJourneyStop,
    required this.isPickup,
    required this.isDrop,
  });

  factory RouteDetailsStop.fromJson(
    Map<String, dynamic> json,
  ) {
    return RouteDetailsStop(
      tripId: _asString(json['trip_id']),
      stopId: _asString(json['stop_id']),
      stopName: _asString(
        json['stop_name'],
        fallback: 'Unnamed stop',
      ),
      arrivalTime: _asString(
        json['arrival_time'],
      ),
      stopOrder: _asInt(
        json['stop_order'],
      ),
      tripName: _asString(
        json['trip_name'],
      ),
      busId: _asString(
        json['bus_id'],
      ),
      city: _asString(json['city']),
      isJourneyStop:
          json['is_journey_stop'] == true,
      isPickup:
          json['is_pickup'] == true,
      isDrop:
          json['is_drop'] == true,
    );
  }
}


// ===============================================================
// SAFE JSON HELPERS
// ===============================================================

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }

  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }

  return <String, dynamic>{};
}

String _asString(
  dynamic value, {
  String fallback = '',
}) {
  if (value == null) {
    return fallback;
  }

  final text = '$value'.trim();

  return text.isEmpty ? fallback : text;
}

int _asInt(dynamic value) {
  if (value is int) {
    return value;
  }

  if (value is double) {
    return value.toInt();
  }

  return int.tryParse('$value') ?? 0;
}

int? _asNullableInt(dynamic value) {
  if (value == null || '$value'.trim().isEmpty) {
    return null;
  }

  if (value is int) {
    return value;
  }

  if (value is double) {
    return value.toInt();
  }

  return int.tryParse('$value');
}