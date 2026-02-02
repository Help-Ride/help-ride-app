import 'package:flutter_test/flutter_test.dart';
import 'package:help_ride/features/driver/utils/ride_price_policy.dart';

void main() {
  group('RidePricePolicy.classifyRideType', () {
    test('classifies ONTIME at or below 2 hours lead', () {
      final booking = DateTime(2026, 2, 2, 10, 0);
      final departure = DateTime(2026, 2, 2, 12, 0);
      final result = RidePricePolicy.classifyRideType(
        bookingTimeLocal: booking,
        departureTimeLocal: departure,
      );
      expect(result, RideTypeClassification.ontime);
    });

    test('classifies PREBOOKED at or above 10 hours lead', () {
      final booking = DateTime(2026, 2, 2, 10, 0);
      final departure = DateTime(2026, 2, 2, 20, 0);
      final result = RidePricePolicy.classifyRideType(
        bookingTimeLocal: booking,
        departureTimeLocal: departure,
      );
      expect(result, RideTypeClassification.prebooked);
    });

    test('classifies STANDARD between 2 and 10 hours lead', () {
      final booking = DateTime(2026, 2, 2, 10, 0);
      final departure = DateTime(2026, 2, 2, 15, 0);
      final result = RidePricePolicy.classifyRideType(
        bookingTimeLocal: booking,
        departureTimeLocal: departure,
      );
      expect(result, RideTypeClassification.standard);
    });
  });

  group('RidePricePolicy.resolvePerSeatPrice', () {
    test('applies ONTIME markup, then min, then upper cap in order', () {
      final booking = DateTime(2026, 2, 2, 10, 0);
      final departure = DateTime(2026, 2, 2, 11, 0); // ontime

      final result = RidePricePolicy.resolvePerSeatPrice(
        basePricePerSeat: 10,
        seats: 1,
        distanceKm: 60,
        bookingTimeLocal: booking,
        departureTimeLocal: departure,
        sameDestination: false,
      );

      // 10 -> 13 (ONTIME) -> 20 (min protection) -> 18 (upper cap)
      expect(result.finalPricePerSeat, 18);
      expect(result.appliedOntimeMarkup, isTrue);
      expect(result.appliedMinimumProtection, isTrue);
      expect(result.appliedUpperSafetyCap, isTrue);
    });

    test('applies same-drop ceiling before upper cap', () {
      final booking = DateTime(2026, 2, 2, 8, 0);
      final departure = DateTime(2026, 2, 2, 20, 0); // prebooked

      final result = RidePricePolicy.resolvePerSeatPrice(
        basePricePerSeat: 30,
        seats: 1,
        distanceKm: 60,
        bookingTimeLocal: booking,
        departureTimeLocal: departure,
        sameDestination: true,
      );

      // 30 -> 15 (same-drop ceiling), upper cap is 18 so stays 15
      expect(result.finalPricePerSeat, 15);
      expect(result.appliedSameDropCeiling, isTrue);
      expect(result.appliedUpperSafetyCap, isFalse);
    });

    test('does not apply minimum protection when seats exceed 2', () {
      final booking = DateTime(2026, 2, 2, 8, 0);
      final departure = DateTime(2026, 2, 2, 20, 0);

      final result = RidePricePolicy.resolvePerSeatPrice(
        basePricePerSeat: 10,
        seats: 3,
        distanceKm: 60,
        bookingTimeLocal: booking,
        departureTimeLocal: departure,
        sameDestination: false,
      );

      expect(result.finalPricePerSeat, 10);
      expect(result.appliedMinimumProtection, isFalse);
    });
  });
}
