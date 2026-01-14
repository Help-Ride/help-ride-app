import '../../../shared/services/api_client.dart';
import '../models/ride.dart';

class RidesApi {
  RidesApi(this._client);
  final ApiClient _client;

  Future<List<Ride>> searchRides({
    required String fromCity,
    required String toCity,
    required int seats,
    double? fromLat,
    double? fromLng,
    double? toLat,
    double? toLng,
    double? radiusKm,
    String? dateYYYYMMDD, // optional
  }) async {
    final q = <String, dynamic>{
      'fromCity': fromCity,
      'toCity': toCity,
      'seats': seats,
      if (fromLat != null) 'fromLat': fromLat,
      if (fromLng != null) 'fromLng': fromLng,
      if (toLat != null) 'toLat': toLat,
      if (toLng != null) 'toLng': toLng,
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
