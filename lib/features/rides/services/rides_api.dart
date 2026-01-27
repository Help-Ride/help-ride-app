import '../../../shared/services/api_client.dart';
import '../models/ride.dart';

class RidesApi {
  RidesApi(this._client);
  final ApiClient _client;

  Future<List<Ride>> searchRides({
    required int seats,
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
    double? radiusKm,
    String? dateYYYYMMDD, // optional
  }) async {
    final q = <String, dynamic>{
      'seats': seats,
      'fromLat': fromLat,
      'fromLng': fromLng,
      'toLat': toLat,
      'toLng': toLng,
      if (radiusKm != null) 'radiusKm': radiusKm,
      if (dateYYYYMMDD != null && dateYYYYMMDD.trim().isNotEmpty)
        'date': dateYYYYMMDD.trim(),
    };

    final res = await _client.get<dynamic>('/rides', query: q);
    final raw = res.data;

    if (raw is! List) return <Ride>[];

    return raw
        .whereType<Map>()
        .map((m) => Ride.fromJson(m.cast<String, dynamic>()))
        .toList();
  }

  Future<Ride> getRideById(String id) async {
    final rid = id.trim();
    if (rid.isEmpty) {
      throw ArgumentError('ride id can not be empty');
    }

    final res = await _client.get<dynamic>('/rides/$rid');
    final raw = res.data;

    if (raw is! Map) {
      throw Exception('Invalid ride response');
    }

    return Ride.fromJson(raw.cast<String, dynamic>());
  }
}
