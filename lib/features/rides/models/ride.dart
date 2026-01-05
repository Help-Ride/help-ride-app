class RideDriver {
  final String id;
  final String name;
  final String? avatarUrl;

  RideDriver({required this.id, required this.name, this.avatarUrl});

  factory RideDriver.fromJson(Map<String, dynamic> json) {
    return RideDriver(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? 'Driver').toString(),
      avatarUrl: json['providerAvatarUrl']?.toString(),
    );
  }
}

class Ride {
  final String id;
  final String driverId;
  final String fromCity;
  final double fromLat;
  final double fromLng;
  final String toCity;
  final double toLat;
  final double toLng;
  final DateTime startTime;
  final DateTime? arrivalTime;
  final double pricePerSeat;
  final int seatsTotal;
  final int seatsAvailable;
  final String status;
  final RideDriver? driver;

  Ride({
    required this.id,
    required this.driverId,
    required this.fromCity,
    required this.fromLat,
    required this.fromLng,
    required this.toCity,
    required this.toLat,
    required this.toLng,
    required this.startTime,
    this.arrivalTime,
    required this.pricePerSeat,
    required this.seatsTotal,
    required this.seatsAvailable,
    required this.status,
    this.driver,
  });

  factory Ride.fromJson(Map<String, dynamic> json) {
    double _toDouble(dynamic v) {
      if (v == null) return 0;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0;
    }

    int _toInt(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString()) ?? 0;
    }

    DateTime _toDate(dynamic v) {
      return DateTime.tryParse(v?.toString() ?? '') ?? DateTime.now();
    }

    return Ride(
      id: (json['id'] ?? '').toString(),
      driverId: (json['driverId'] ?? '').toString(),
      fromCity: (json['fromCity'] ?? '').toString(),
      fromLat: _toDouble(json['fromLat']),
      fromLng: _toDouble(json['fromLng']),
      toCity: (json['toCity'] ?? '').toString(),
      toLat: _toDouble(json['toLat']),
      toLng: _toDouble(json['toLng']),
      startTime: _toDate(json['startTime']).toLocal(),
      arrivalTime: json['arrivalTime'] == null
          ? null
          : _toDate(json['arrivalTime']).toLocal(),
      pricePerSeat: _toDouble(json['pricePerSeat']),
      seatsTotal: _toInt(json['seatsTotal']),
      seatsAvailable: _toInt(json['seatsAvailable']),
      status: (json['status'] ?? 'open').toString(),
      driver: json['driver'] is Map<String, dynamic>
          ? RideDriver.fromJson(json['driver'] as Map<String, dynamic>)
          : null,
    );
  }
}
