class RecentSearch {
  final String from;
  final String to;
  final DateTime when;
  final double? fromLat;
  final double? fromLng;
  final double? toLat;
  final double? toLng;
  final double? radiusKm;
  final int? seats;

  const RecentSearch({
    required this.from,
    required this.to,
    required this.when,
    this.fromLat,
    this.fromLng,
    this.toLat,
    this.toLng,
    this.radiusKm,
    this.seats,
  });

  factory RecentSearch.fromJson(Map<String, dynamic> json) {
    return RecentSearch(
      from: (json['from'] ?? '').toString().trim(),
      to: (json['to'] ?? '').toString().trim(),
      when: _parseWhen(json['when']),
      fromLat: _readDouble(json['fromLat']),
      fromLng: _readDouble(json['fromLng']),
      toLat: _readDouble(json['toLat']),
      toLng: _readDouble(json['toLng']),
      radiusKm: _readDouble(json['radiusKm']),
      seats: _readInt(json['seats']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'from': from,
      'to': to,
      'when': when.toIso8601String(),
      if (fromLat != null) 'fromLat': fromLat,
      if (fromLng != null) 'fromLng': fromLng,
      if (toLat != null) 'toLat': toLat,
      if (toLng != null) 'toLng': toLng,
      if (radiusKm != null) 'radiusKm': radiusKm,
      if (seats != null) 'seats': seats,
    };
  }

  static DateTime _parseWhen(dynamic value) {
    if (value is DateTime) return value;
    if (value is String && value.trim().isNotEmpty) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) return parsed;
    }
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    return DateTime.now();
  }

  static double? _readDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  static int? _readInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }
}
