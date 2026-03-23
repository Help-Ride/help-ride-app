import '../models/driver_ride_management.dart';

DriverRideItem mapDriverRideItem(Map<String, dynamic> json) {
  double toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  DateTime parseDate(dynamic value) {
    final parsed = DateTime.tryParse((value ?? '').toString());
    return (parsed ?? DateTime.now()).toLocal();
  }

  DateTime? readDate(dynamic value) {
    if (value == null) return null;
    final parsed = DateTime.tryParse(value.toString());
    return parsed?.toLocal();
  }

  List<String> readStringList(dynamic value) {
    if (value is List) {
      return value
          .map((item) => item?.toString().trim() ?? '')
          .where((item) => item.isNotEmpty)
          .toList(growable: false);
    }
    return const <String>[];
  }

  String? readString(dynamic value) {
    if (value == null) return null;
    final normalized = value.toString().trim();
    return normalized.isEmpty ? null : normalized;
  }

  return DriverRideItem(
    id: (json['id'] ?? '').toString(),
    from: (json['fromCity'] ?? json['from_city'] ?? '').toString(),
    to: (json['toCity'] ?? json['to_city'] ?? '').toString(),
    startTime: parseDate(json['startTime'] ?? json['start_time']),
    arrivalTime: readDate(json['arrivalTime'] ?? json['arrival_time']),
    createdAt: readDate(json['createdAt'] ?? json['created_at']),
    updatedAt: readDate(json['updatedAt'] ?? json['updated_at']),
    seatsTotal: ((json['seatsTotal'] ?? json['seats_total']) as num?)?.toInt() ?? 0,
    seatsAvailable:
        ((json['seatsAvailable'] ?? json['seats_available']) as num?)?.toInt() ??
        0,
    pricePerSeat: toDouble(json['pricePerSeat'] ?? json['price_per_seat']),
    status: (json['status'] ?? 'open').toString(),
    rideType: (json['rideType'] ?? json['ride_type'] ?? 'one-time').toString(),
    recurringSeriesId:
        (json['recurringSeriesId'] ?? json['recurring_series_id'])?.toString(),
    recurrenceDays: readStringList(
      json['recurrenceDays'] ?? json['recurrence_days'],
    ),
    recurrenceEndDate: readDate(
      json['recurrenceEndDate'] ?? json['recurrence_end_date'],
    ),
    stops: readStringList(json['stops'] ?? json['stop_list']),
    amenities: readStringList(json['amenities'] ?? json['ride_amenities']),
    notes: readString(
      json['additionalNotes'] ?? json['additional_notes'] ?? json['notes'],
    ),
  );
}

List<DriverRideSeriesSummary> buildDriverRideSeriesSummaries(
  Iterable<DriverRideItem> rides,
) {
  final grouped = <String, List<DriverRideItem>>{};
  for (final ride in rides) {
    final seriesId = ride.recurringSeriesId?.trim();
    if (!ride.isRecurring || seriesId == null || seriesId.isEmpty) {
      continue;
    }
    grouped.putIfAbsent(seriesId, () => <DriverRideItem>[]).add(ride);
  }

  final summaries = grouped.entries
      .map(
        (entry) => DriverRideSeriesSummary(
          id: entry.key,
          occurrences: entry.value,
        ),
      )
      .toList(growable: false);

  summaries.sort((left, right) {
    final leftAnchor = left.nextUpcomingOccurrence?.startTime ?? left.endDate;
    final rightAnchor = right.nextUpcomingOccurrence?.startTime ?? right.endDate;

    final leftHasUpcoming = left.nextUpcomingOccurrence != null;
    final rightHasUpcoming = right.nextUpcomingOccurrence != null;

    if (leftHasUpcoming && rightHasUpcoming) {
      return leftAnchor.compareTo(rightAnchor);
    }
    if (leftHasUpcoming != rightHasUpcoming) {
      return leftHasUpcoming ? -1 : 1;
    }
    return rightAnchor.compareTo(leftAnchor);
  });

  return summaries;
}
