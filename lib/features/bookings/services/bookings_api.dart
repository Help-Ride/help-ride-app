import 'package:help_ride/features/bookings/models/booking.dart';
import 'package:help_ride/shared/services/api_client.dart';

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

  Future<List<Booking>> myBookings() async {
    final res = await _client.get<dynamic>('/bookings/me/list');
    final raw = res.data;
    if (raw is! List) return [];

    return raw
        .whereType<Map>()
        .map((m) => Booking.fromJson(m.cast<String, dynamic>()))
        .toList();
  }

  Future<List<Booking>> driverBookings() async {
    final res = await _client.get<dynamic>('/bookings/me/list');
    final raw = res.data;
    if (raw is! List) return [];

    return raw
        .whereType<Map>()
        .map((m) => Booking.fromJson(m.cast<String, dynamic>()))
        .toList();
  }

  Future<List<Booking>> bookingsForRide(String rideId) async {
    final id = rideId.trim();
    if (id.isEmpty) throw Exception('Missing rideId');

    final res = await _client.get<dynamic>('/bookings/ride/$id');
    final raw = res.data;
    if (raw is! List) return [];

    return raw
        .whereType<Map>()
        .map((m) => Booking.fromJson(m.cast<String, dynamic>()))
        .toList();
  }

  Future<void> confirmBooking(String bookingId) async {
    final id = bookingId.trim();
    if (id.isEmpty) throw Exception('Missing bookingId');
    await _client.put<void>('/bookings/$id/confirm');
  }

  Future<void> rejectBooking(String bookingId) async {
    final id = bookingId.trim();
    if (id.isEmpty) throw Exception('Missing bookingId');
    await _client.put<void>('/bookings/$id/reject');
  }
}
