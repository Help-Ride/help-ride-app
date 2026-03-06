import 'ride_request.dart';

class RideRequestOfferRide {
  final String id;
  final String fromCity;
  final String toCity;
  final DateTime startTime;
  final double pricePerSeat;
  final int seatsAvailable;

  RideRequestOfferRide({
    required this.id,
    required this.fromCity,
    required this.toCity,
    required this.startTime,
    required this.pricePerSeat,
    required this.seatsAvailable,
  });

  factory RideRequestOfferRide.fromJson(Map<String, dynamic> json) {
    double toDouble(dynamic v) =>
        v is num ? v.toDouble() : double.tryParse(v.toString()) ?? 0;

    int toInt(dynamic v) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString()) ?? 0;
    }

    DateTime toDate(dynamic v) {
      return DateTime.tryParse(v?.toString() ?? '')?.toLocal() ??
          DateTime.now();
    }

    return RideRequestOfferRide(
      id: (json['id'] ?? '').toString(),
      fromCity: (json['fromCity'] ?? json['from_city'] ?? '').toString(),
      toCity: (json['toCity'] ?? json['to_city'] ?? '').toString(),
      startTime: toDate(json['startTime'] ?? json['start_time']),
      pricePerSeat: toDouble(json['pricePerSeat'] ?? json['price_per_seat']),
      seatsAvailable: toInt(json['seatsAvailable'] ?? json['seats_available']),
    );
  }
}

class RideRequestOffer {
  final String id;
  final String rideRequestId;
  final String rideId;
  final int seatsOffered;
  final double pricePerSeat;
  final String status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final RideRequest? request;
  final RideRequestOfferRide? ride;
  final RideRequestOfferDriver? driver;

  RideRequestOffer({
    required this.id,
    required this.rideRequestId,
    required this.rideId,
    required this.seatsOffered,
    required this.pricePerSeat,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    this.request,
    this.ride,
    this.driver,
  });

  bool get isOpen {
    final normalized = status.trim().toLowerCase();
    return normalized.contains('pending') || normalized.contains('sent');
  }

  double get displayPricePerSeat {
    if (pricePerSeat > 0) return pricePerSeat;
    final ridePrice = ride?.pricePerSeat ?? 0;
    return ridePrice > 0 ? ridePrice : 0;
  }

  factory RideRequestOffer.fromJson(Map<String, dynamic> json) {
    double toDouble(dynamic v) {
      if (v is num) return v.toDouble();
      return double.tryParse(v?.toString() ?? '') ?? 0;
    }

    DateTime toDate(dynamic v) {
      return DateTime.tryParse(v?.toString() ?? '')?.toLocal() ??
          DateTime.now();
    }

    int toInt(dynamic v) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString()) ?? 0;
    }

    final requestMap = json['rideRequest'] is Map
        ? json['rideRequest']
        : json['request'] is Map
        ? json['request']
        : json['ride_request'] is Map
        ? json['ride_request']
        : null;

    final rideMap = json['ride'] is Map ? json['ride'] : null;

    final request = requestMap == null
        ? null
        : RideRequest.fromJson(requestMap.cast<String, dynamic>());

    final ride = rideMap == null
        ? null
        : RideRequestOfferRide.fromJson(rideMap.cast<String, dynamic>());

    final driverMap = json['driver'] is Map ? json['driver'] : null;
    final driver = driverMap == null
        ? null
        : RideRequestOfferDriver.fromJson(driverMap.cast<String, dynamic>());

    final requestId =
        (json['rideRequestId'] ?? request?.id ?? json['requestId'] ?? '')
            .toString();

    final rideId = (json['rideId'] ?? ride?.id ?? json['driverRideId'] ?? '')
        .toString();

    return RideRequestOffer(
      id: (json['id'] ?? json['offerId'] ?? '').toString(),
      rideRequestId: requestId,
      rideId: rideId,
      seatsOffered: toInt(json['seatsOffered'] ?? json['seats'] ?? 0),
      pricePerSeat: toDouble(
        json['pricePerSeat'] ?? json['price_per_seat'] ?? ride?.pricePerSeat,
      ),
      status: (json['status'] ?? 'pending').toString(),
      createdAt: toDate(json['createdAt'] ?? json['created_at']),
      updatedAt: json['updatedAt'] == null && json['updated_at'] == null
          ? null
          : toDate(json['updatedAt'] ?? json['updated_at']),
      request: request,
      ride: ride,
      driver: driver,
    );
  }
}

class RideRequestOfferDriver {
  final String id;
  final String name;
  final String? email;
  final String? avatarUrl;

  RideRequestOfferDriver({
    required this.id,
    required this.name,
    this.email,
    this.avatarUrl,
  });

  factory RideRequestOfferDriver.fromJson(Map<String, dynamic> json) {
    return RideRequestOfferDriver(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? 'Driver').toString(),
      email: json['email']?.toString(),
      avatarUrl: json['providerAvatarUrl']?.toString(),
    );
  }
}
