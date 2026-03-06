import 'package:flutter_test/flutter_test.dart';
import 'package:help_ride/features/ride_requests/models/ride_request_offer.dart';

void main() {
  group('RideRequestOffer.fromJson', () {
    test('keeps SENT offers actionable and uses top-level pricePerSeat', () {
      final offer = RideRequestOffer.fromJson({
        'id': 'offer-1',
        'rideRequestId': 'request-1',
        'rideId': 'ride-1',
        'status': 'SENT',
        'seatsOffered': 2,
        'pricePerSeat': 27.5,
        'createdAt': '2026-03-01T15:00:00.000Z',
        'ride': {
          'id': 'ride-1',
          'fromCity': 'Toronto',
          'toCity': 'Montreal',
          'startTime': '2026-03-01T18:00:00.000Z',
        },
      });

      expect(offer.isOpen, isTrue);
      expect(offer.pricePerSeat, 27.5);
      expect(offer.displayPricePerSeat, 27.5);
    });

    test('falls back to nested ride price when offer price is absent', () {
      final offer = RideRequestOffer.fromJson({
        'id': 'offer-2',
        'rideRequestId': 'request-2',
        'rideId': 'ride-2',
        'status': 'pending',
        'seatsOffered': 1,
        'createdAt': '2026-03-01T15:00:00.000Z',
        'ride': {
          'id': 'ride-2',
          'fromCity': 'Ottawa',
          'toCity': 'Kingston',
          'startTime': '2026-03-01T18:00:00.000Z',
          'pricePerSeat': 18,
        },
      });

      expect(offer.isOpen, isTrue);
      expect(offer.pricePerSeat, 18);
      expect(offer.displayPricePerSeat, 18);
    });
  });
}
