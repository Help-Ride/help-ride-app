import 'package:flutter_test/flutter_test.dart';
import 'package:help_ride/features/driver/models/driver_ride_management.dart';
import 'package:help_ride/features/driver/utils/driver_ride_grouping.dart';

void main() {
  group('buildDriverRideSeriesSummaries', () {
    test(
      'groups recurring occurrences into one series and leaves one-time rides out',
      () {
        final rides = <DriverRideItem>[
          DriverRideItem(
            id: 'one-time',
            from: 'A',
            to: 'B',
            startTime: DateTime(2099, 1, 1, 9),
            seatsTotal: 3,
            seatsAvailable: 2,
            pricePerSeat: 10,
            status: 'open',
          ),
          DriverRideItem(
            id: 'series-1-occ-1',
            from: 'A',
            to: 'B',
            startTime: DateTime(2099, 1, 3, 9),
            seatsTotal: 3,
            seatsAvailable: 1,
            pricePerSeat: 10,
            status: 'open',
            rideType: 'recurring',
            recurringSeriesId: 'series-1',
            recurrenceDays: const ['saturday', 'sunday'],
          ),
          DriverRideItem(
            id: 'series-1-occ-2',
            from: 'A',
            to: 'B',
            startTime: DateTime(2099, 1, 4, 9),
            seatsTotal: 3,
            seatsAvailable: 0,
            pricePerSeat: 10,
            status: 'open',
            rideType: 'recurring',
            recurringSeriesId: 'series-1',
            recurrenceDays: const ['saturday', 'sunday'],
          ),
        ];

        final summaries = buildDriverRideSeriesSummaries(rides);

        expect(summaries, hasLength(1));
        expect(summaries.first.id, 'series-1');
        expect(summaries.first.totalOccurrences, 2);
        expect(summaries.first.upcomingCount, 2);
      },
    );

    test('highlights cancelled and modified occurrences as exceptions', () {
      final rides = <DriverRideItem>[
        DriverRideItem(
          id: 'occ-1',
          from: 'Toronto',
          to: 'Markham',
          startTime: DateTime(2099, 3, 7, 8, 0),
          seatsTotal: 3,
          seatsAvailable: 2,
          pricePerSeat: 15,
          status: 'open',
          rideType: 'recurring',
          recurringSeriesId: 'series-2',
          recurrenceDays: const ['saturday'],
        ),
        DriverRideItem(
          id: 'occ-2',
          from: 'Toronto',
          to: 'Markham',
          startTime: DateTime(2099, 3, 14, 9, 30),
          seatsTotal: 3,
          seatsAvailable: 2,
          pricePerSeat: 15,
          status: 'open',
          rideType: 'recurring',
          recurringSeriesId: 'series-2',
          recurrenceDays: const ['saturday'],
        ),
        DriverRideItem(
          id: 'occ-3',
          from: 'Toronto',
          to: 'Markham',
          startTime: DateTime(2099, 3, 21, 8, 0),
          seatsTotal: 3,
          seatsAvailable: 3,
          pricePerSeat: 15,
          status: 'cancelled',
          rideType: 'recurring',
          recurringSeriesId: 'series-2',
          recurrenceDays: const ['saturday'],
        ),
      ];

      final summary = buildDriverRideSeriesSummaries(rides).single;

      expect(summary.cancelledCount, 1);
      expect(summary.modifiedCount, 1);
      expect(summary.isModifiedOccurrence(rides[1]), isTrue);
      expect(summary.lifecycleLabel, 'Active');
    });

    test(
      'moves past untouched occurrences into history instead of overview',
      () {
        final now = DateTime.now();
        final rides = <DriverRideItem>[
          DriverRideItem(
            id: 'past-occ',
            from: 'Toronto',
            to: 'Scarborough',
            startTime: now.subtract(const Duration(days: 2)),
            seatsTotal: 3,
            seatsAvailable: 3,
            pricePerSeat: 10,
            status: 'scheduled',
            rideType: 'recurring',
            recurringSeriesId: 'series-3',
            recurrenceDays: const ['monday'],
          ),
          DriverRideItem(
            id: 'future-occ',
            from: 'Toronto',
            to: 'Scarborough',
            startTime: now.add(const Duration(days: 2)),
            seatsTotal: 3,
            seatsAvailable: 3,
            pricePerSeat: 10,
            status: 'scheduled',
            rideType: 'recurring',
            recurringSeriesId: 'series-3',
            recurrenceDays: const ['monday'],
          ),
        ];

        final summary = buildDriverRideSeriesSummaries(rides).single;

        expect(summary.completedCount, 1);
        expect(summary.shouldSurfaceInOverview(rides.first), isFalse);
        expect(summary.shouldSurfaceInOverview(rides.last), isTrue);
      },
    );
  });
}
