class BookingRide {
  final String id;
  final String fromCity;
  final String toCity;
  final DateTime startTime;
  final double pricePerSeat;
  final String driverId;

  BookingRide({
    required this.id,
    required this.fromCity,
    required this.toCity,
    required this.startTime,
    required this.pricePerSeat,
    required this.driverId,
  });

  factory BookingRide.fromJson(Map<String, dynamic> json) {
    double toDouble(dynamic v) =>
        v is num ? v.toDouble() : double.tryParse(v.toString()) ?? 0;

    return BookingRide(
      id: (json['id'] ?? '').toString(),
      fromCity: (json['fromCity'] ?? '').toString(),
      toCity: (json['toCity'] ?? '').toString(),
      startTime:
          DateTime.tryParse((json['startTime'] ?? '').toString())?.toLocal() ??
          DateTime.now(),
      pricePerSeat: toDouble(json['pricePerSeat']),
      driverId: (json['driverId'] ?? '').toString(),
    );
  }
}

class BookingPassenger {
  final String id;
  final String name;
  final String? avatarUrl;
  final double? rating;
  final int? trips;

  BookingPassenger({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.rating,
    this.trips,
  });

  factory BookingPassenger.fromJson(Map<String, dynamic> json) {
    double? toDouble(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString());
    }

    int? toInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString());
    }

    String? first = json['firstName']?.toString();
    String? last = json['lastName']?.toString();
    final nameSource =
        json['name'] ??
        json['fullName'] ??
        [first, last].where((s) => (s ?? '').isNotEmpty).join(' ');
    final fullName = (nameSource is String ? nameSource : '${nameSource ?? ''}')
        .trim();

    return BookingPassenger(
      id: (json['id'] ?? json['userId'] ?? '').toString(),
      name: fullName.isEmpty ? 'Passenger' : fullName,
      avatarUrl:
          json['avatarUrl']?.toString() ??
          json['photoUrl']?.toString() ??
          json['profileImage']?.toString(),
      rating: toDouble(json['rating'] ?? json['avgRating']),
      trips: toInt(json['trips'] ?? json['rides'] ?? json['ridesCount']),
    );
  }
}

class Booking {
  final String id;
  final String rideId;
  final String? rideRequestId;
  final String passengerId;
  final int seatsBooked;
  final String status; // pending/confirmed/cancelled_by_driver/...
  final String paymentStatus;
  final String? paymentIntentId;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final BookingRide ride;
  final BookingPassenger? passenger;
  final String? note;

  Booking({
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
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    final passengerMap = json['passenger'] is Map
        ? json['passenger'] as Map
        : json['user'] is Map
        ? json['user'] as Map
        : json['passengerProfile'] is Map
        ? json['passengerProfile'] as Map
        : null;

    final rideMap = json['ride'] is Map
        ? json['ride'] as Map
        : {
            'id': json['rideId'],
            'fromCity': json['fromCity'],
            'toCity': json['toCity'],
            'startTime': json['startTime'],
            'pricePerSeat': json['pricePerSeat'],
            'driverId': json['driverId'],
          };

    return Booking(
      id: (json['id'] ?? '').toString(),
      rideId: (json['rideId'] ?? '').toString(),
      rideRequestId:
          (json['rideRequestId'] ??
                  json['requestId'] ??
                  (json['rideRequest'] is Map
                      ? (json['rideRequest'] as Map)['id']
                      : null))
              ?.toString(),
      passengerId: (json['passengerId'] ?? '').toString(),
      seatsBooked: (json['seatsBooked'] as num?)?.toInt() ?? 0,
      status: (json['status'] ?? 'pending').toString(),
      paymentStatus:
          (json['bookingPaymentStatus'] ??
                  json['paymentStatus'] ??
                  json['payment_status'] ??
                  (json['booking'] is Map
                      ? (json['booking'] as Map)['paymentStatus']
                      : null) ??
                  'unpaid')
              .toString(),
      paymentIntentId:
          (json['paymentIntentId'] ??
                  json['payment_intent_id'] ??
                  (json['paymentIntent'] is Map
                      ? (json['paymentIntent'] as Map)['id']
                      : null))
              ?.toString(),
      createdAt:
          DateTime.tryParse((json['createdAt'] ?? '').toString())?.toLocal() ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(
        (json['updatedAt'] ?? '').toString(),
      )?.toLocal(),
      ride: BookingRide.fromJson(rideMap.cast<String, dynamic>()),
      passenger: passengerMap == null
          ? null
          : BookingPassenger.fromJson(passengerMap.cast<String, dynamic>()),
      note:
          (json['note'] ??
                  json['message'] ??
                  json['notes'] ??
                  json['pickupNotes'])
              ?.toString(),
    );
  }

  double get totalPrice => ride.pricePerSeat * seatsBooked;
}
