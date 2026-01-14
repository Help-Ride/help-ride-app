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
}
