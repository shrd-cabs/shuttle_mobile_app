// ===============================================================
// stop_model.dart
// ---------------------------------------------------------------
// Stop Model
//
// PURPOSE
// ---------------------------------------------------------------
// Represents one pickup/drop stop from backend.
// ===============================================================

class StopModel {
  final String stopId;
  final String stopName;
  final int stopIndex;

  const StopModel({
    required this.stopId,
    required this.stopName,
    required this.stopIndex,
  });

  factory StopModel.fromDynamic(dynamic stop, int index) {
    if (stop is String) {
      final name = stop.trim();
      return StopModel(
        stopId: name,
        stopName: name,
        stopIndex: index,
      );
    }

    if (stop is Map<String, dynamic>) {
      final name = (stop['stop_name'] ??
              stop['stopName'] ??
              stop['name'] ??
              stop['stop'] ??
              '')
          .toString()
          .trim();

      final id = (stop['stop_id'] ??
              stop['stopId'] ??
              stop['id'] ??
              name)
          .toString()
          .trim();

      return StopModel(
        stopId: id.isEmpty ? name : id,
        stopName: name,
        stopIndex: index,
      );
    }

    return StopModel(
      stopId: '',
      stopName: '',
      stopIndex: index,
    );
  }
}