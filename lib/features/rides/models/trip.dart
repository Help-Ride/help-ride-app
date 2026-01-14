class Trip {
  Trip({
    required this.id,
    required this.driverId,
    required this.fromCity,
    required this.fromLat,
    required this.fromLng,
    required this.toCity,
    required this.toLat,
    required this.toLng,
    required this.startTime,
    required this.arrivalTime,
    required this.pricePerSeat,
    required this.seatsTotal,
    required this.seatsAvailable,
    required this.status,
  });

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

  final int pricePerSeat; // convert from "22" to 22
  final int seatsTotal;
  final int seatsAvailable;

  final String status; // "open"

  factory Trip.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      return int.tryParse(v.toString()) ?? 0;
    }

    double parseDouble(dynamic v) {
      if (v == null) return 0.0;
      if (v is double) return v;
      if (v is int) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0.0;
    }

    DateTime parseDate(dynamic v) {
      // API has ISO string with Z
      return DateTime.parse(v.toString()).toLocal();
    }

    return Trip(
      id: (json['id'] ?? '').toString(),
      driverId: (json['driverId'] ?? '').toString(),
      fromCity: (json['fromCity'] ?? '').toString(),
      fromLat: parseDouble(json['fromLat']),
      fromLng: parseDouble(json['fromLng']),
      toCity: (json['toCity'] ?? '').toString(),
      toLat: parseDouble(json['toLat']),
      toLng: parseDouble(json['toLng']),
      startTime: parseDate(json['startTime']),
      arrivalTime: json['arrivalTime'] == null
          ? null
          : DateTime.parse(json['arrivalTime'].toString()).toLocal(),
      pricePerSeat: parseInt(json['pricePerSeat']),
      seatsTotal: parseInt(json['seatsTotal']),
      seatsAvailable: parseInt(json['seatsAvailable']),
      status: (json['status'] ?? '').toString(),
    );
  }
}
