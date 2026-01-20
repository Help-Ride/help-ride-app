class RideRequest {
  final String id;
  final String fromCity;
  final String toCity;
  final double? fromLat;
  final double? fromLng;
  final double? toLat;
  final double? toLng;
  final DateTime preferredDate;
  final String preferredTime;
  final String? arrivalTime;
  final int seatsNeeded;
  final String rideType;
  final String tripType;
  final String status;
  final DateTime createdAt;
  final DateTime? updatedAt;

  RideRequest({
    required this.id,
    required this.fromCity,
    required this.toCity,
    this.fromLat,
    this.fromLng,
    this.toLat,
    this.toLng,
    required this.preferredDate,
    required this.preferredTime,
    this.arrivalTime,
    required this.seatsNeeded,
    required this.rideType,
    required this.tripType,
    required this.status,
    required this.createdAt,
    this.updatedAt,
  });

  factory RideRequest.fromJson(Map<String, dynamic> json) {
    double? toDouble(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString());
    }

    DateTime toDate(dynamic v) {
      return DateTime.tryParse(v?.toString() ?? '')?.toLocal() ??
          DateTime.now();
    }

    return RideRequest(
      id: (json['id'] ?? '').toString(),
      fromCity: (json['fromCity'] ?? '').toString(),
      toCity: (json['toCity'] ?? '').toString(),
      fromLat: toDouble(json['fromLat']),
      fromLng: toDouble(json['fromLng']),
      toLat: toDouble(json['toLat']),
      toLng: toDouble(json['toLng']),
      preferredDate: toDate(json['preferredDate']),
      preferredTime: (json['preferredTime'] ?? '').toString(),
      arrivalTime: json['arrivalTime']?.toString(),
      seatsNeeded: (json['seatsNeeded'] as num?)?.toInt() ?? 0,
      rideType: (json['rideType'] ?? 'one-time').toString(),
      tripType: (json['tripType'] ?? 'one-way').toString(),
      status: (json['status'] ?? 'pending').toString(),
      createdAt: toDate(json['createdAt']),
      updatedAt: json['updatedAt'] == null ? null : toDate(json['updatedAt']),
    );
  }
}
