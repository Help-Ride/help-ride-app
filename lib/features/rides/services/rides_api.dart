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

    final res = await _client.get<List<dynamic>>('/rides', query: q);
    final raw = res.data ?? [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map((j) => Ride.fromJson(j))
        .toList();
  }
}
