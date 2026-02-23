import 'package:geolocator/geolocator.dart';

class LocationSample {
  const LocationSample({
    required this.lat,
    required this.lng,
    this.accuracyMeters,
    required this.recordedAt,
  });

  factory LocationSample.fromPosition(Position position) {
    final accuracy = position.accuracy;
    final recordedAt = position.timestamp.toUtc();
    return LocationSample(
      lat: position.latitude,
      lng: position.longitude,
      accuracyMeters: accuracy.isFinite && accuracy >= 0 ? accuracy : null,
      recordedAt: recordedAt,
    );
  }

  final double lat;
  final double lng;
  final double? accuracyMeters;
  final DateTime recordedAt;

  Map<String, dynamic> toApiJson() {
    return {
      'lat': lat,
      'lng': lng,
      if (accuracyMeters != null && accuracyMeters! >= 0)
        'accuracyMeters': accuracyMeters,
      'recordedAt': recordedAt.toUtc().toIso8601String(),
    };
  }
}
