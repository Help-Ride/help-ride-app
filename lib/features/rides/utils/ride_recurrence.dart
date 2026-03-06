import 'package:flutter/material.dart';

const List<String> rideRecurrenceDayOrder = <String>[
  'monday',
  'tuesday',
  'wednesday',
  'thursday',
  'friday',
  'saturday',
  'sunday',
];

const Map<String, String> rideRecurrenceDayLabels = <String, String>{
  'monday': 'Mon',
  'tuesday': 'Tue',
  'wednesday': 'Wed',
  'thursday': 'Thu',
  'friday': 'Fri',
  'saturday': 'Sat',
  'sunday': 'Sun',
};

String rideRecurrenceWeekdayKey(DateTime date) {
  switch (date.weekday) {
    case DateTime.monday:
      return 'monday';
    case DateTime.tuesday:
      return 'tuesday';
    case DateTime.wednesday:
      return 'wednesday';
    case DateTime.thursday:
      return 'thursday';
    case DateTime.friday:
      return 'friday';
    case DateTime.saturday:
      return 'saturday';
    case DateTime.sunday:
      return 'sunday';
  }
  return 'monday';
}

List<String> normalizeRideRecurrenceDays(Iterable<String> values) {
  final unique = <String>{};
  for (final value in values) {
    final normalized = value.trim().toLowerCase();
    if (rideRecurrenceDayLabels.containsKey(normalized)) {
      unique.add(normalized);
    }
  }

  return rideRecurrenceDayOrder
      .where((day) => unique.contains(day))
      .toList(growable: false);
}

String formatRideRecurrenceDays(Iterable<String> values) {
  final days = normalizeRideRecurrenceDays(values);
  if (days.isEmpty) return 'Recurring';
  return days.map((day) => rideRecurrenceDayLabels[day] ?? day).join(', ');
}

List<DateTime> buildRecurringRideOccurrenceStarts({
  required DateTime startDate,
  required TimeOfDay time,
  required DateTime endDate,
  required Set<String> recurrenceDays,
}) {
  final normalizedDays = normalizeRideRecurrenceDays(recurrenceDays);
  if (normalizedDays.isEmpty) return const <DateTime>[];

  final firstDay = DateTime(startDate.year, startDate.month, startDate.day);
  final lastDay = DateTime(endDate.year, endDate.month, endDate.day);
  if (lastDay.isBefore(firstDay)) return const <DateTime>[];

  final occurrences = <DateTime>[];
  for (
    var day = firstDay;
    !day.isAfter(lastDay);
    day = day.add(const Duration(days: 1))
  ) {
    if (!recurrenceDays.contains(rideRecurrenceWeekdayKey(day))) continue;
    occurrences.add(
      DateTime(day.year, day.month, day.day, time.hour, time.minute),
    );
  }
  return occurrences;
}
