class RideDriver {
  final String id;
  final String name;
  final String? avatarUrl;
  final double? rating;
  final int? ridesCount;
  final int? sinceYear;
  final bool? isVerified;

  RideDriver({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.rating,
    this.ridesCount,
    this.sinceYear,
    this.isVerified,
  });

  factory RideDriver.fromJson(Map<String, dynamic> json) {
    double? _readDouble(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString());
    }

    int? _readInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString());
    }

    bool? _readBool(dynamic v) {
      if (v == null) return null;
      if (v is bool) return v;
      if (v is num) return v != 0;
      if (v is String) {
        final val = v.toLowerCase();
        if (val == 'true' || val == '1') return true;
        if (val == 'false' || val == '0') return false;
      }
      return null;
    }

    return RideDriver(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? 'Driver').toString(),
      avatarUrl: json['providerAvatarUrl']?.toString(),
      rating: _readDouble(json['rating'] ?? json['avgRating']),
      ridesCount: _readInt(json['ridesCount'] ?? json['trips'] ?? json['rides']),
      sinceYear: _readInt(json['sinceYear'] ?? json['memberSinceYear']),
      isVerified: _readBool(json['isVerified'] ?? json['verified']),
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
  final List<String> amenities;
  final String? pickupInstructions;
  final String? notes;
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
    this.amenities = const [],
    this.pickupInstructions,
    this.notes,
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

    String? _readString(dynamic v) {
      if (v == null) return null;
      final s = v.toString().trim();
      return s.isEmpty ? null : s;
    }

    List<String> _readStringList(dynamic v) {
      if (v is List) {
        return v
            .map((e) => e?.toString().trim() ?? '')
            .where((e) => e.isNotEmpty)
            .toList();
      }
      if (v is Map) {
        final list = <String>[];
        v.forEach((key, value) {
          final isOn = value == true ||
              value == 1 ||
              value == '1' ||
              value == 'true';
          if (isOn) list.add(key.toString());
        });
        return list;
      }
      if (v is String) {
        return v
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
      }
      return [];
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
      amenities: _readStringList(
        json['amenities'] ?? json['rideAmenities'] ?? json['amenityList'],
      ),
      pickupInstructions: _readString(
        json['pickupInstructions'] ??
            json['pickupNotes'] ??
            json['instructions'],
      ),
      notes: _readString(json['notes'] ?? json['rideNotes']),
      driver: json['driver'] is Map<String, dynamic>
          ? RideDriver.fromJson(json['driver'] as Map<String, dynamic>)
          : null,
    );
  }
}
