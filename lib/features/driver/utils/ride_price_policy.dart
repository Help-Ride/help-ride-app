import 'dart:math';

enum RideTypeClassification { prebooked, ontime, standard }

class RidePriceResolution {
  const RidePriceResolution({
    required this.basePricePerSeat,
    required this.finalPricePerSeat,
    required this.distanceKm,
    required this.classification,
    required this.appliedOntimeMarkup,
    required this.appliedMinimumProtection,
    required this.appliedSameDropCeiling,
    required this.appliedUpperSafetyCap,
  });

  final double basePricePerSeat;
  final double finalPricePerSeat;
  final double distanceKm;
  final RideTypeClassification classification;
  final bool appliedOntimeMarkup;
  final bool appliedMinimumProtection;
  final bool appliedSameDropCeiling;
  final bool appliedUpperSafetyCap;

  bool get adjusted => (finalPricePerSeat - basePricePerSeat).abs() >= 0.01;
}

class RidePricePolicy {
  static const double ontimeMarkupMultiplier = 1.30;
  static const double minProtectionDistanceKm = 55;
  static const double minProtectionPrice = 20;
  static const int minProtectionMaxSeats = 2;
  static const double sameDropDistanceKm = 50;
  static const double sameDropMaxPrice = 15;
  static const double upperPricePerKm = 0.30;
  static const Duration ontimeThreshold = Duration(hours: 2);
  static const Duration prebookedThreshold = Duration(hours: 10);

  static RideTypeClassification classifyRideType({
    required DateTime bookingTimeLocal,
    required DateTime departureTimeLocal,
  }) {
    final lead = departureTimeLocal.difference(bookingTimeLocal);
    if (!lead.isNegative && lead <= ontimeThreshold) {
      return RideTypeClassification.ontime;
    }
    if (lead >= prebookedThreshold) {
      return RideTypeClassification.prebooked;
    }
    return RideTypeClassification.standard;
  }

  static RidePriceResolution resolvePerSeatPrice({
    required double basePricePerSeat,
    required int seats,
    required double distanceKm,
    required DateTime bookingTimeLocal,
    required DateTime departureTimeLocal,
    required bool sameDestination,
  }) {
    final classification = classifyRideType(
      bookingTimeLocal: bookingTimeLocal,
      departureTimeLocal: departureTimeLocal,
    );

    var price = basePricePerSeat < 0 ? 0.0 : basePricePerSeat;
    var appliedOntimeMarkup = false;
    var appliedMinimumProtection = false;
    var appliedSameDropCeiling = false;
    var appliedUpperSafetyCap = false;

    // 2) ONTIME +30% if applicable
    if (classification == RideTypeClassification.ontime) {
      price *= ontimeMarkupMultiplier;
      appliedOntimeMarkup = true;
    }

    // 3) Minimum price protection
    if (distanceKm >= minProtectionDistanceKm &&
        seats <= minProtectionMaxSeats &&
        price < minProtectionPrice) {
      price = minProtectionPrice;
      appliedMinimumProtection = true;
    }

    // 4) Same-drop ceiling
    if (sameDestination &&
        distanceKm >= sameDropDistanceKm &&
        price > sameDropMaxPrice) {
      price = sameDropMaxPrice;
      appliedSameDropCeiling = true;
    }

    // 5) Upper safety cap
    final upperCap = max(0.0, distanceKm) * upperPricePerKm;
    if (price > upperCap) {
      price = upperCap;
      appliedUpperSafetyCap = true;
    }

    price = ((price * 100).roundToDouble()) / 100;

    return RidePriceResolution(
      basePricePerSeat: ((basePricePerSeat * 100).roundToDouble()) / 100,
      finalPricePerSeat: price,
      distanceKm: distanceKm,
      classification: classification,
      appliedOntimeMarkup: appliedOntimeMarkup,
      appliedMinimumProtection: appliedMinimumProtection,
      appliedSameDropCeiling: appliedSameDropCeiling,
      appliedUpperSafetyCap: appliedUpperSafetyCap,
    );
  }

  static double distanceKm({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
  }) {
    const earthRadiusKm = 6371.0;
    final dLat = _degToRad(toLat - fromLat);
    final dLng = _degToRad(toLng - fromLng);
    final a =
        pow(sin(dLat / 2), 2) +
        cos(_degToRad(fromLat)) * cos(_degToRad(toLat)) * pow(sin(dLng / 2), 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusKm * c;
  }

  static bool isSameDestination({required String from, required String to}) {
    final fromToken = _cityToken(from);
    final toToken = _cityToken(to);
    if (fromToken.isNotEmpty && toToken.isNotEmpty) {
      return fromToken == toToken;
    }
    return _normalizeLabel(from) == _normalizeLabel(to);
  }

  static String _cityToken(String value) {
    final normalized = _normalizeLabel(value);
    if (normalized.isEmpty) return '';
    final firstChunk = normalized.split(',').first.trim();
    return firstChunk.replaceAll(RegExp(r'\d'), '').trim();
  }

  static String _normalizeLabel(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9,\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static double _degToRad(double deg) => deg * (pi / 180.0);
}
