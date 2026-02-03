enum RideRequestMode { offer, jit }

RideRequestMode rideRequestModeFromRaw(dynamic value) {
  final normalized = value?.toString().trim().toUpperCase() ?? '';
  if (normalized == 'JIT') return RideRequestMode.jit;
  return RideRequestMode.offer;
}

String rideRequestModeToWire(RideRequestMode mode) {
  return mode == RideRequestMode.jit ? 'JIT' : 'OFFER';
}

class RideRequest {
  final String id;
  final String passengerId;
  final String? driverId;
  final RideRequestMode mode;
  final String status;
  final String fromCity;
  final double? fromLat;
  final double? fromLng;
  final String toCity;
  final double? toLat;
  final double? toLng;
  final DateTime preferredDate;
  final String? preferredTime;
  final String? arrivalTime;
  final int seatsNeeded;
  final String rideType;
  final String tripType;
  final DateTime? returnDate;
  final String? returnTime;
  final String? jitPaymentIntentId;
  final int? jitAmountCents;
  final String? jitCurrency;
  final double? quotedPricePerSeat;
  final DateTime createdAt;
  final DateTime? updatedAt;

  RideRequest({
    required this.id,
    required this.passengerId,
    this.driverId,
    required this.mode,
    required this.status,
    required this.fromCity,
    this.fromLat,
    this.fromLng,
    required this.toCity,
    this.toLat,
    this.toLng,
    required this.preferredDate,
    this.preferredTime,
    this.arrivalTime,
    required this.seatsNeeded,
    required this.rideType,
    required this.tripType,
    this.returnDate,
    this.returnTime,
    this.jitPaymentIntentId,
    this.jitAmountCents,
    this.jitCurrency,
    this.quotedPricePerSeat,
    required this.createdAt,
    this.updatedAt,
  });

  factory RideRequest.fromJson(Map<String, dynamic> json) {
    double? toDouble(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString());
    }

    int? toIntNullable(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString());
    }

    int toInt(dynamic v, {int fallback = 0}) {
      return toIntNullable(v) ?? fallback;
    }

    DateTime? toDateNullable(dynamic v) {
      if (v == null) return null;
      if (v is DateTime) return v.toLocal();
      if (v is String && v.trim().isEmpty) return null;
      return DateTime.tryParse(v.toString())?.toLocal();
    }

    DateTime toDate(dynamic v) {
      return toDateNullable(v) ?? DateTime.now();
    }

    return RideRequest(
      id: (json['id'] ?? '').toString(),
      passengerId: (json['passengerId'] ?? json['passenger_id'] ?? '')
          .toString(),
      driverId: (json['driverId'] ?? json['driver_id'])?.toString(),
      mode: rideRequestModeFromRaw(json['mode']),
      status: (json['status'] ?? 'pending').toString(),
      fromCity: (json['fromCity'] ?? json['from_city'] ?? '').toString(),
      toCity: (json['toCity'] ?? json['to_city'] ?? '').toString(),
      fromLat: toDouble(json['fromLat'] ?? json['from_lat']),
      fromLng: toDouble(json['fromLng'] ?? json['from_lng']),
      toLat: toDouble(json['toLat'] ?? json['to_lat']),
      toLng: toDouble(json['toLng'] ?? json['to_lng']),
      preferredDate: toDate(json['preferredDate'] ?? json['preferred_date']),
      preferredTime: (json['preferredTime'] ?? json['preferred_time'])
          ?.toString(),
      arrivalTime: (json['arrivalTime'] ?? json['arrival_time'])?.toString(),
      seatsNeeded: toInt(json['seatsNeeded'] ?? json['seats_needed']),
      rideType: (json['rideType'] ?? json['ride_type'] ?? 'one-time')
          .toString(),
      tripType: (json['tripType'] ?? json['trip_type'] ?? 'one-way').toString(),
      returnDate: toDateNullable(json['returnDate'] ?? json['return_date']),
      returnTime: (json['returnTime'] ?? json['return_time'])?.toString(),
      jitPaymentIntentId:
          (json['jitPaymentIntentId'] ?? json['jit_payment_intent_id'])
              ?.toString(),
      jitAmountCents: toIntNullable(
        json['jitAmountCents'] ?? json['jit_amount_cents'],
      ),
      jitCurrency: (json['jitCurrency'] ?? json['jit_currency'])?.toString(),
      quotedPricePerSeat: toDouble(
        json['quotedPricePerSeat'] ?? json['quoted_price_per_seat'],
      ),
      createdAt: toDate(json['createdAt'] ?? json['created_at']),
      updatedAt: json['updatedAt'] == null && json['updated_at'] == null
          ? null
          : toDate(json['updatedAt'] ?? json['updated_at']),
    );
  }
}
