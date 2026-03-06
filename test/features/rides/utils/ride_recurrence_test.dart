import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:help_ride/features/rides/utils/ride_recurrence.dart';

void main() {
  group('buildRecurringRideOccurrenceStarts', () {
    test('creates occurrences on selected weekdays through the end date', () {
      final occurrences = buildRecurringRideOccurrenceStarts(
        startDate: DateTime(2026, 3, 9), // Monday
        time: const TimeOfDay(hour: 8, minute: 15),
        endDate: DateTime(2026, 3, 20),
        recurrenceDays: const {'monday', 'wednesday', 'friday'},
      );

      expect(
        occurrences,
        <DateTime>[
          DateTime(2026, 3, 9, 8, 15),
          DateTime(2026, 3, 11, 8, 15),
          DateTime(2026, 3, 13, 8, 15),
          DateTime(2026, 3, 16, 8, 15),
          DateTime(2026, 3, 18, 8, 15),
          DateTime(2026, 3, 20, 8, 15),
        ],
      );
    });

    test('returns empty when no days are selected', () {
      final occurrences = buildRecurringRideOccurrenceStarts(
        startDate: DateTime(2026, 3, 9),
        time: const TimeOfDay(hour: 8, minute: 15),
        endDate: DateTime(2026, 3, 20),
        recurrenceDays: const <String>{},
      );

      expect(occurrences, isEmpty);
    });
  });

  test('formatRideRecurrenceDays sorts and labels weekdays', () {
    expect(
      formatRideRecurrenceDays(const ['friday', 'monday', 'wednesday']),
      'Mon, Wed, Fri',
    );
  });
}
