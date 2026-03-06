enum RidePricingStrategy { fixedRoute, marketMinimum, driverInput }

enum RideTimingClass { prebooked, ontime, standard }

class RidePricingPreview {
  const RidePricingPreview({
    required this.inputPricePerSeat,
    required this.finalPricePerSeat,
    required this.marketFloorPricePerSeat,
    required this.distanceKm,
    required this.estimatedDurationMinutes,
    required this.rideTiming,
    required this.strategy,
    required this.appliedOntimeMarkup,
    required this.sharedSeatDivisor,
    required this.estimatedTripTotal,
    this.fixedRoutePricePerSeat,
  });

  final double inputPricePerSeat;
  final double finalPricePerSeat;
  final double marketFloorPricePerSeat;
  final double distanceKm;
  final int estimatedDurationMinutes;
  final RideTimingClass rideTiming;
  final RidePricingStrategy strategy;
  final bool appliedOntimeMarkup;
  final double sharedSeatDivisor;
  final double estimatedTripTotal;
  final double? fixedRoutePricePerSeat;

  bool get adjusted => (finalPricePerSeat - inputPricePerSeat).abs() >= 0.01;

  factory RidePricingPreview.fromJson(Map<String, dynamic> json) {
    double toDouble(dynamic value, {double fallback = 0}) {
      if (value is num) return value.toDouble();
      return double.tryParse(value?.toString() ?? '') ?? fallback;
    }

    int toInt(dynamic value, {int fallback = 0}) {
      if (value is int) return value;
      if (value is num) return value.round();
      return int.tryParse(value?.toString() ?? '') ?? fallback;
    }

    RideTimingClass readTiming(dynamic value) {
      final normalized = value?.toString().trim().toLowerCase() ?? '';
      switch (normalized) {
        case 'prebooked':
          return RideTimingClass.prebooked;
        case 'ontime':
          return RideTimingClass.ontime;
        default:
          return RideTimingClass.standard;
      }
    }

    RidePricingStrategy readStrategy(dynamic value) {
      final normalized = value?.toString().trim().toLowerCase() ?? '';
      switch (normalized) {
        case 'fixed_route':
          return RidePricingStrategy.fixedRoute;
        case 'market_minimum':
          return RidePricingStrategy.marketMinimum;
        default:
          return RidePricingStrategy.driverInput;
      }
    }

    double? readNullableDouble(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString());
    }

    return RidePricingPreview(
      inputPricePerSeat: toDouble(json['inputPricePerSeat']),
      finalPricePerSeat: toDouble(
        json['finalPricePerSeat'] ?? json['pricePerSeat'],
      ),
      marketFloorPricePerSeat: toDouble(json['marketFloorPricePerSeat']),
      distanceKm: toDouble(json['distanceKm']),
      estimatedDurationMinutes: toInt(json['estimatedDurationMinutes']),
      rideTiming: readTiming(json['rideTiming']),
      strategy: readStrategy(json['strategy']),
      appliedOntimeMarkup: json['appliedOntimeMarkup'] == true,
      sharedSeatDivisor: toDouble(json['sharedSeatDivisor'], fallback: 1),
      estimatedTripTotal: toDouble(json['estimatedTripTotal']),
      fixedRoutePricePerSeat: readNullableDouble(
        json['fixedRoutePricePerSeat'],
      ),
    );
  }
}
