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
      startTime: DateTime.parse((json['startTime'] ?? '').toString()).toLocal(),
      pricePerSeat: toDouble(json['pricePerSeat']),
      driverId: (json['driverId'] ?? '').toString(),
    );
  }
}

class Booking {
  final String id;
  final String rideId;
  final String passengerId;
  final int seatsBooked;
  final String status; // pending/confirmed/cancelled_by_driver/...
  final String paymentStatus;
  final DateTime createdAt;
  final BookingRide ride;

  Booking({
    required this.id,
    required this.rideId,
    required this.passengerId,
    required this.seatsBooked,
    required this.status,
    required this.paymentStatus,
    required this.createdAt,
    required this.ride,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: (json['id'] ?? '').toString(),
      rideId: (json['rideId'] ?? '').toString(),
      passengerId: (json['passengerId'] ?? '').toString(),
      seatsBooked: (json['seatsBooked'] as num?)?.toInt() ?? 0,
      status: (json['status'] ?? 'pending').toString(),
      paymentStatus: (json['paymentStatus'] ?? 'unpaid').toString(),
      createdAt: DateTime.parse((json['createdAt'] ?? '').toString()).toLocal(),
      ride: BookingRide.fromJson((json['ride'] as Map).cast<String, dynamic>()),
    );
  }

  double get totalPrice => ride.pricePerSeat * seatsBooked;
}
