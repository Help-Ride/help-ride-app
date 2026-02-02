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
      fromCity: (json['fromCity'] ?? json['from_city'] ?? '').toString(),
      toCity: (json['toCity'] ?? json['to_city'] ?? '').toString(),
      fromLat: toDouble(json['fromLat'] ?? json['from_lat']),
      fromLng: toDouble(json['fromLng'] ?? json['from_lng']),
      toLat: toDouble(json['toLat'] ?? json['to_lat']),
      toLng: toDouble(json['toLng'] ?? json['to_lng']),
      preferredDate: toDate(json['preferredDate'] ?? json['preferred_date']),
      preferredTime: (json['preferredTime'] ?? json['preferred_time'] ?? '')
          .toString(),
      arrivalTime: (json['arrivalTime'] ?? json['arrival_time'])?.toString(),
      seatsNeeded:
          ((json['seatsNeeded'] ?? json['seats_needed']) as num?)?.toInt() ?? 0,
      rideType: (json['rideType'] ?? json['ride_type'] ?? 'one-time')
          .toString(),
      tripType: (json['tripType'] ?? json['trip_type'] ?? 'one-way').toString(),
      status: (json['status'] ?? 'pending').toString(),
      createdAt: toDate(json['createdAt'] ?? json['created_at']),
      updatedAt: json['updatedAt'] == null && json['updated_at'] == null
          ? null
          : toDate(json['updatedAt'] ?? json['updated_at']),
    );
  }
}
