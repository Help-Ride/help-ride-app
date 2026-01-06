import '../../../shared/services/api_client.dart';

class BookingsApi {
  BookingsApi(this._client);
  final ApiClient _client;

  /// POST /bookings/{rideId}
  /// body: { "seats": 1 }
  Future<Map<String, dynamic>> createBooking({
    required String rideId,
    required int seats,
  }) async {
    final id = rideId.trim();
    if (id.isEmpty) throw Exception('Missing rideId');

    final s = seats <= 0 ? 1 : seats;

    final res = await _client.post<Map<String, dynamic>>(
      '/bookings/$id',
      data: {'seats': s},
    );

    return res.data ?? <String, dynamic>{};
  }
}
