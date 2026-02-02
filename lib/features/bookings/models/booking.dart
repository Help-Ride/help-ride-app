class BookingRideDriver {
  const BookingRideDriver({
    required this.id,
    required this.name,
    this.email,
    this.avatarUrl,
  });

  final String id;
  final String name;
  final String? email;
  final String? avatarUrl;

  factory BookingRideDriver.fromJson(Map<String, dynamic> json) {
    return BookingRideDriver(
      id: _asString(json['id']),
      name:
          _nonEmpty(
            _asString(json['name'] ?? json['fullName'] ?? json['displayName']),
          ) ??
          'Driver',
      email: _nonEmpty(_asString(json['email'])),
      avatarUrl: _nonEmpty(
        _asString(
          json['providerAvatarUrl'] ??
              json['avatarUrl'] ??
              json['photoUrl'] ??
              json['profileImage'],
        ),
      ),
    );
  }
}

class BookingRide {
  const BookingRide({
    required this.id,
    required this.fromCity,
    required this.toCity,
    required this.startTime,
    required this.pricePerSeat,
    required this.driverId,
    required this.status,
    this.driver,
  });

  final String id;
  final String fromCity;
  final String toCity;
  final DateTime startTime;
  final double pricePerSeat;
  final String driverId;
  final String status;
  final BookingRideDriver? driver;

  factory BookingRide.fromJson(Map<String, dynamic> json) {
    final driverMap = _asMap(json['driver']);
    final fallbackDriverId = _asString(
      json['driverId'] ?? json['driver_id'] ?? driverMap['id'],
    );

    return BookingRide(
      id: _asString(json['id']),
      fromCity: _asString(json['fromCity'] ?? json['from_city']),
      toCity: _asString(json['toCity'] ?? json['to_city']),
      startTime:
          _asDate(json['startTime'] ?? json['start_time']) ?? DateTime.now(),
      pricePerSeat: _asDouble(json['pricePerSeat'] ?? json['price_per_seat']),
      driverId: fallbackDriverId,
      status:
          _nonEmpty(
            _asString(
              json['status'] ?? json['rideStatus'] ?? json['ride_status'],
            ),
          ) ??
          'open',
      driver: driverMap.isEmpty ? null : BookingRideDriver.fromJson(driverMap),
    );
  }
}

class BookingPassenger {
  const BookingPassenger({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    this.avatarUrl,
    this.rating,
    this.trips,
  });

  final String id;
  final String name;
  final String? email;
  final String? phone;
  final String? avatarUrl;
  final double? rating;
  final int? trips;

  factory BookingPassenger.fromJson(Map<String, dynamic> json) {
    final first = _nonEmpty(_asString(json['firstName'] ?? json['first_name']));
    final last = _nonEmpty(_asString(json['lastName'] ?? json['last_name']));
    final fullName =
        _nonEmpty(_asString(json['name'] ?? json['fullName'])) ??
        [first, last].where((v) => v != null).join(' ');

    return BookingPassenger(
      id: _asString(json['id'] ?? json['userId'] ?? json['user_id']),
      name: _nonEmpty(fullName) ?? 'Passenger',
      email: _nonEmpty(_asString(json['email'])),
      phone: _nonEmpty(_asString(json['phone'] ?? json['phoneNumber'])),
      avatarUrl: _nonEmpty(
        _asString(
          json['providerAvatarUrl'] ??
              json['avatarUrl'] ??
              json['photoUrl'] ??
              json['profileImage'],
        ),
      ),
      rating: _asNullableDouble(json['rating'] ?? json['avgRating']),
      trips: _asNullableInt(
        json['trips'] ?? json['rides'] ?? json['ridesCount'],
      ),
    );
  }
}

class Booking {
  const Booking({
    required this.id,
    required this.rideId,
    this.rideRequestId,
    required this.passengerId,
    required this.seatsBooked,
    required this.status,
    required this.paymentStatus,
    this.paymentIntentId,
    required this.createdAt,
    this.updatedAt,
    required this.ride,
    this.passenger,
    this.note,
    this.passengerPickupName,
    this.passengerPickupLat,
    this.passengerPickupLng,
    this.passengerDropoffName,
    this.passengerDropoffLat,
    this.passengerDropoffLng,
  });

  final String id;
  final String rideId;
  final String? rideRequestId;
  final String passengerId;
  final int seatsBooked;
  final String status;
  final String paymentStatus;
  final String? paymentIntentId;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final BookingRide ride;
  final BookingPassenger? passenger;
  final String? note;
  final String? passengerPickupName;
  final double? passengerPickupLat;
  final double? passengerPickupLng;
  final String? passengerDropoffName;
  final double? passengerDropoffLat;
  final double? passengerDropoffLng;

  factory Booking.fromJson(Map<String, dynamic> json) {
    final normalized = _normalizedBookingPayload(json);

    final passengerMap = _firstMap([
      normalized['passenger'],
      normalized['user'],
      normalized['passengerProfile'],
      json['passenger'],
      json['user'],
      json['passengerProfile'],
    ]);

    final rideMapFromPayload = _firstMap([normalized['ride'], json['ride']]);
    final mergedRideMap = <String, dynamic>{
      'id': normalized['rideId'] ?? json['rideId'],
      'fromCity': normalized['fromCity'] ?? json['fromCity'],
      'toCity': normalized['toCity'] ?? json['toCity'],
      'startTime': normalized['startTime'] ?? json['startTime'],
      'pricePerSeat': normalized['pricePerSeat'] ?? json['pricePerSeat'],
      'driverId': normalized['driverId'] ?? json['driverId'],
      'status': normalized['rideStatus'] ?? json['rideStatus'],
      'driver': _firstMap([normalized['driver'], json['driver']]),
      ...rideMapFromPayload,
    };

    final paymentIntentId = _nonEmpty(
      _asString(
        normalized['stripePaymentIntentId'] ??
            normalized['paymentIntentId'] ??
            normalized['payment_intent_id'] ??
            _asMap(normalized['paymentIntent'])['id'],
      ),
    );

    return Booking(
      id: _asString(normalized['id']),
      rideId: _asString(normalized['rideId'] ?? mergedRideMap['id']),
      rideRequestId: _nonEmpty(
        _asString(
          normalized['rideRequestId'] ??
              normalized['requestId'] ??
              _asMap(normalized['rideRequest'])['id'],
        ),
      ),
      passengerId: _asString(
        normalized['passengerId'] ??
            _asMap(normalized['passenger'])['id'] ??
            passengerMap['id'],
      ),
      seatsBooked: _asInt(normalized['seatsBooked']),
      status: _nonEmpty(_asString(normalized['status'])) ?? 'pending',
      paymentStatus:
          _nonEmpty(
            _asString(
              normalized['bookingPaymentStatus'] ??
                  normalized['paymentStatus'] ??
                  normalized['payment_status'] ??
                  _asMap(normalized['booking'])['paymentStatus'],
            ),
          ) ??
          'unpaid',
      paymentIntentId: paymentIntentId,
      createdAt: _asDate(normalized['createdAt']) ?? DateTime.now(),
      updatedAt: _asNullableDate(normalized['updatedAt']),
      ride: BookingRide.fromJson(mergedRideMap),
      passenger: passengerMap.isEmpty
          ? null
          : BookingPassenger.fromJson(passengerMap),
      note: _nonEmpty(
        _asString(
          normalized['note'] ??
              normalized['message'] ??
              normalized['notes'] ??
              normalized['pickupNotes'],
        ),
      ),
      passengerPickupName: _nonEmpty(
        _asString(
          normalized['passengerPickupName'] ??
              normalized['passenger_pickup_name'],
        ),
      ),
      passengerPickupLat: _asNullableDouble(
        normalized['passengerPickupLat'] ?? normalized['passenger_pickup_lat'],
      ),
      passengerPickupLng: _asNullableDouble(
        normalized['passengerPickupLng'] ?? normalized['passenger_pickup_lng'],
      ),
      passengerDropoffName: _nonEmpty(
        _asString(
          normalized['passengerDropoffName'] ??
              normalized['passenger_dropoff_name'],
        ),
      ),
      passengerDropoffLat: _asNullableDouble(
        normalized['passengerDropoffLat'] ??
            normalized['passenger_dropoff_lat'],
      ),
      passengerDropoffLng: _asNullableDouble(
        normalized['passengerDropoffLng'] ??
            normalized['passenger_dropoff_lng'],
      ),
    );
  }

  Booking copyWith({
    String? id,
    String? rideId,
    String? rideRequestId,
    String? passengerId,
    int? seatsBooked,
    String? status,
    String? paymentStatus,
    String? paymentIntentId,
    DateTime? createdAt,
    DateTime? updatedAt,
    BookingRide? ride,
    BookingPassenger? passenger,
    String? note,
    String? passengerPickupName,
    double? passengerPickupLat,
    double? passengerPickupLng,
    String? passengerDropoffName,
    double? passengerDropoffLat,
    double? passengerDropoffLng,
  }) {
    return Booking(
      id: id ?? this.id,
      rideId: rideId ?? this.rideId,
      rideRequestId: rideRequestId ?? this.rideRequestId,
      passengerId: passengerId ?? this.passengerId,
      seatsBooked: seatsBooked ?? this.seatsBooked,
      status: status ?? this.status,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentIntentId: paymentIntentId ?? this.paymentIntentId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      ride: ride ?? this.ride,
      passenger: passenger ?? this.passenger,
      note: note ?? this.note,
      passengerPickupName: passengerPickupName ?? this.passengerPickupName,
      passengerPickupLat: passengerPickupLat ?? this.passengerPickupLat,
      passengerPickupLng: passengerPickupLng ?? this.passengerPickupLng,
      passengerDropoffName: passengerDropoffName ?? this.passengerDropoffName,
      passengerDropoffLat: passengerDropoffLat ?? this.passengerDropoffLat,
      passengerDropoffLng: passengerDropoffLng ?? this.passengerDropoffLng,
    );
  }

  String get pickupLabel =>
      _nonEmpty(passengerPickupName) ?? _nonEmpty(ride.fromCity) ?? '-';

  String get dropoffLabel =>
      _nonEmpty(passengerDropoffName) ?? _nonEmpty(ride.toCity) ?? '-';

  bool get hasPassengerRoute =>
      _nonEmpty(passengerPickupName) != null ||
      _nonEmpty(passengerDropoffName) != null;

  double get totalPrice => ride.pricePerSeat * seatsBooked;
}

Map<String, dynamic> _normalizedBookingPayload(Map<String, dynamic> input) {
  final booking = _asMap(input['booking']);
  if (booking.isEmpty) return input;

  final out = <String, dynamic>{...booking};
  if (!_hasMap(out['ride'])) {
    final ride = _asMap(input['ride']);
    if (ride.isNotEmpty) out['ride'] = ride;
  }
  if (!_hasMap(out['passenger'])) {
    final passenger = _asMap(input['passenger']);
    if (passenger.isNotEmpty) out['passenger'] = passenger;
  }
  if (!_hasMap(out['driver'])) {
    final driver = _asMap(input['driver']);
    if (driver.isNotEmpty) out['driver'] = driver;
  }
  return out;
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map) {
    return value.cast<String, dynamic>();
  }
  return const <String, dynamic>{};
}

Map<String, dynamic> _firstMap(List<dynamic> values) {
  for (final value in values) {
    final map = _asMap(value);
    if (map.isNotEmpty) return map;
  }
  return const <String, dynamic>{};
}

bool _hasMap(dynamic value) => value is Map && value.isNotEmpty;

String _asString(dynamic value) => value?.toString() ?? '';

String? _nonEmpty(String? value) {
  if (value == null) return null;
  final v = value.trim();
  return v.isEmpty ? null : v;
}

double _asDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(_asString(value)) ?? 0;
}

double? _asNullableDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(_asString(value));
}

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(_asString(value)) ?? 0;
}

int? _asNullableInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(_asString(value));
}

DateTime? _asDate(dynamic value) {
  final parsed = DateTime.tryParse(_asString(value));
  return parsed?.toLocal();
}

DateTime? _asNullableDate(dynamic value) {
  if (value == null) return null;
  return _asDate(value);
}
