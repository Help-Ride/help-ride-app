import 'package:help_ride/features/bookings/models/booking.dart';
import 'package:help_ride/shared/services/api_client.dart';

class BookingsApi {
  BookingsApi(this._client);
  final ApiClient _client;

  /// POST /bookings/{rideId}
  /// body: {
  ///   "seats": 1,
  ///   "passengerPickupName": "...",
  ///   "passengerDropoffName": "..."
  /// }
  Future<Booking> createBooking({
    required String rideId,
    required int seats,
    required String passengerPickupName,
    required String passengerDropoffName,
    double? passengerPickupLat,
    double? passengerPickupLng,
    double? passengerDropoffLat,
    double? passengerDropoffLng,
  }) async {
    final id = rideId.trim();
    if (id.isEmpty) throw Exception('Missing rideId');

    final s = seats <= 0 ? 1 : seats;
    final pickup = passengerPickupName.trim();
    final dropoff = passengerDropoffName.trim();
    if (pickup.isEmpty) throw Exception('Missing passengerPickupName');
    if (dropoff.isEmpty) throw Exception('Missing passengerDropoffName');

    final res = await _client.post<Map<String, dynamic>>(
      '/bookings/$id',
      data: {
        'seats': s,
        'passengerPickupName': pickup,
        'passengerDropoffName': dropoff,
        if (passengerPickupLat != null)
          'passengerPickupLat': passengerPickupLat,
        if (passengerPickupLng != null)
          'passengerPickupLng': passengerPickupLng,
        if (passengerDropoffLat != null)
          'passengerDropoffLat': passengerDropoffLat,
        if (passengerDropoffLng != null)
          'passengerDropoffLng': passengerDropoffLng,
      },
    );

    return _parseBooking(res.data);
  }

  Future<List<Booking>> myBookings() async {
    final res = await _client.get<dynamic>('/bookings/me/list');
    return _parseBookingList(res.data);
  }

  Future<List<Booking>> driverBookings({int pageSize = 50}) async {
    final all = <Booking>[];
    final seenCursors = <String>{};
    String? cursor;

    while (true) {
      final query = <String, dynamic>{
        if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
        if (pageSize > 0) 'limit': pageSize,
      };
      final res = await _client.get<dynamic>(
        '/bookings/driver/me',
        query: query.isEmpty ? null : query,
      );

      final root = _asMap(res.data);
      final data = _asMap(root['data']);
      final payload = data.isNotEmpty ? data : root;
      final batch = _parseBookingList(
        payload['bookings'] ?? payload['items'] ?? payload['data'] ?? res.data,
      );
      all.addAll(batch);

      final nextCursor = _readCursor(payload) ?? _readCursor(root);
      if (nextCursor == null ||
          nextCursor.isEmpty ||
          seenCursors.contains(nextCursor)) {
        break;
      }
      seenCursors.add(nextCursor);
      cursor = nextCursor;
    }

    return all;
  }

  Future<List<Booking>> bookingsForRide(String rideId) async {
    final id = rideId.trim();
    if (id.isEmpty) throw Exception('Missing rideId');

    final res = await _client.get<dynamic>('/bookings/ride/$id');
    return _parseBookingList(res.data);
  }

  Future<Booking> confirmBooking(String bookingId) async {
    final id = bookingId.trim();
    if (id.isEmpty) throw Exception('Missing bookingId');
    final res = await _client.put<dynamic>('/bookings/$id/confirm');
    return _parseBooking(res.data);
  }

  Future<Booking> rejectBooking(String bookingId) async {
    final id = bookingId.trim();
    if (id.isEmpty) throw Exception('Missing bookingId');
    final res = await _client.put<dynamic>('/bookings/$id/reject');
    return _parseBooking(res.data);
  }

  Future<Booking> cancelBooking(String bookingId) async {
    final id = bookingId.trim();
    if (id.isEmpty) throw Exception('Missing bookingId');
    final res = await _client.post<dynamic>('/bookings/$id/cancel');
    return _parseBooking(res.data);
  }

  Future<Booking> driverCancelBooking(String bookingId) async {
    final id = bookingId.trim();
    if (id.isEmpty) throw Exception('Missing bookingId');
    final res = await _client.post<dynamic>('/bookings/$id/driver-cancel');
    return _parseBooking(res.data);
  }

  Booking _parseBooking(dynamic raw) {
    final map = _extractBookingMap(raw);
    if (map.isEmpty) throw Exception('Invalid booking response payload.');
    return Booking.fromJson(map);
  }

  List<Booking> _parseBookingList(dynamic raw) {
    final list = _extractBookingList(raw);
    if (list.isEmpty) return const <Booking>[];

    return list
        .whereType<Map>()
        .map((m) => Booking.fromJson(_asMap(m)))
        .toList();
  }

  List<dynamic> _extractBookingList(dynamic raw) {
    if (raw is List) return raw;

    final root = _asMap(raw);
    if (root.isEmpty) return const <dynamic>[];

    for (final key in const ['bookings', 'items', 'results']) {
      final value = root[key];
      if (value is List) return value;
    }

    final data = root['data'];
    if (data is List) return data;
    if (data is Map) {
      final nested = _extractBookingList(data);
      if (nested.isNotEmpty) return nested;
    }

    if (_looksLikeBooking(root) || _asMap(root['booking']).isNotEmpty) {
      return <dynamic>[root];
    }

    return const <dynamic>[];
  }

  Map<String, dynamic> _extractBookingMap(dynamic raw) {
    final root = _asMap(raw);
    if (root.isEmpty) return const <String, dynamic>{};

    if (_looksLikeBooking(root)) return root;

    final booking = _asMap(root['booking']);
    if (booking.isNotEmpty) {
      return <String, dynamic>{...root, ...booking};
    }

    final data = root['data'];
    if (data is Map) return _extractBookingMap(data);
    if (data is List && data.isNotEmpty) {
      final first = data.first;
      if (first is Map) return _extractBookingMap(first);
    }

    return const <String, dynamic>{};
  }

  bool _looksLikeBooking(Map<String, dynamic> map) {
    return map.containsKey('id') &&
        (map.containsKey('rideId') ||
            map.containsKey('seatsBooked') ||
            map.containsKey('status'));
  }

  String? _readCursor(Map<String, dynamic> map) {
    final raw = map['nextCursor'] ?? map['next_cursor'] ?? map['cursor'];
    final value = raw?.toString().trim();
    if (value == null || value.isEmpty) return null;
    return value;
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map) {
      return value.cast<String, dynamic>();
    }
    return const <String, dynamic>{};
  }
}
