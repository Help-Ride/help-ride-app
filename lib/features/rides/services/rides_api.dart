import '../../../shared/services/api_client.dart';
import '../models/ride.dart';

class RidesApi {
  RidesApi(this._client);
  final ApiClient _client;

  Future<List<Ride>> searchRides({
    required String fromCity,
    required String toCity,
    required int seats,
    String? dateYYYYMMDD, // optional
  }) async {
    final q = <String, dynamic>{
      'fromCity': fromCity,
      'toCity': toCity,
      'seats': seats,
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
