import '../../../shared/services/api_client.dart';

class DriverRidesApi {
  DriverRidesApi(this._client);
  final ApiClient _client;

  Future<Map<String, dynamic>> createRide({
    required String fromCity,
    required double fromLat,
    required double fromLng,
    required String toCity,
    required double toLat,
    required double toLng,
    required DateTime startTimeUtc,
    required int seatsTotal,
    required double pricePerSeat,
    DateTime? arrivalTimeUtc,
  }) async {
    final res = await _client.post<Map<String, dynamic>>(
      '/rides',
      data: {
        'fromCity': fromCity,
        'fromLat': fromLat,
        'fromLng': fromLng,
        'toCity': toCity,
        'toLat': toLat,
        'toLng': toLng,
        'startTime': startTimeUtc.toIso8601String(),
        'arrivalTime': arrivalTimeUtc?.toIso8601String(),
        'seatsTotal': seatsTotal,
        'pricePerSeat': pricePerSeat,
        // keep backend happy (your API expects these currently)
        'rideType': 'one-time',
        'tripType': 'one-way',
      },
    );
    return res.data ?? {};
  }

  Future<Map<String, dynamic>> updateRide({
    required String rideId,
    required String fromCity,
    required double fromLat,
    required double fromLng,
    required String toCity,
    required double toLat,
    required double toLng,
    required DateTime startTimeUtc,
    required int seatsTotal,
    required double pricePerSeat,
  }) async {
    final id = rideId.trim();
    if (id.isEmpty) {
      throw ArgumentError('ride id can not be empty');
    }

    final res = await _client.put<Map<String, dynamic>>(
      '/rides/$id',
      data: {
        'fromCity': fromCity,
        'fromLat': fromLat,
        'fromLng': fromLng,
        'toCity': toCity,
        'toLat': toLat,
        'toLng': toLng,
        'startTime': startTimeUtc.toIso8601String(),
        'pricePerSeat': pricePerSeat,
        'seatsTotal': seatsTotal,
      },
    );
    return res.data ?? {};
  }

  Future<void> deleteRide(String rideId) async {
    final id = rideId.trim();
    if (id.isEmpty) {
      throw ArgumentError('ride id can not be empty');
    }
    await _client.delete<void>('/rides/$id');
  }

  Future<Map<String, dynamic>> startRide(String rideId) async {
    final id = rideId.trim();
    if (id.isEmpty) {
      throw ArgumentError('ride id can not be empty');
    }
    final res = await _client.put<Map<String, dynamic>>('/rides/$id/start');
    return res.data ?? <String, dynamic>{};
  }

  Future<Map<String, dynamic>> completeRide(String rideId) async {
    final id = rideId.trim();
    if (id.isEmpty) {
      throw ArgumentError('ride id can not be empty');
    }
    final res = await _client.put<Map<String, dynamic>>('/rides/$id/complete');
    return res.data ?? <String, dynamic>{};
  }
}
