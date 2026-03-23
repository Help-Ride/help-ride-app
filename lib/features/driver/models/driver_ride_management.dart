import '../../rides/utils/ride_recurrence.dart';

enum DriverRidesTab { upcoming, past }

enum DriverRideListFilter { all, oneTime, recurring, cancelled, occurrences }

enum DriverRideOccurrenceFilter { all, upcoming, modified, cancelled, completed }

enum DriverRideSeriesLifecycle { active, paused, ended }

class DriverRideItem {
  final String id;
  final String from;
  final String to;
  final DateTime startTime;
  final DateTime? arrivalTime;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int seatsTotal;
  final int seatsAvailable;
  final double pricePerSeat;
  final String status;
  final String rideType;
  final String? recurringSeriesId;
  final List<String> recurrenceDays;
  final DateTime? recurrenceEndDate;
  final List<String> stops;
  final List<String> amenities;
  final String? notes;

  DriverRideItem({
    required this.id,
    required this.from,
    required this.to,
    required this.startTime,
    this.arrivalTime,
    this.createdAt,
    this.updatedAt,
    required this.seatsTotal,
    required this.seatsAvailable,
    required this.pricePerSeat,
    required this.status,
    this.rideType = 'one-time',
    this.recurringSeriesId,
    this.recurrenceDays = const [],
    this.recurrenceEndDate,
    this.stops = const [],
    this.amenities = const [],
    this.notes,
  });

  int get booked => (seatsTotal - seatsAvailable).clamp(0, seatsTotal);
  bool get isRecurring => rideType.trim().toLowerCase() == 'recurring';
  String get normalizedStatus => status.trim().toLowerCase();
  bool get isCancelled => normalizedStatus.contains('cancel');
  bool get isCompleted => normalizedStatus.contains('complete');
  bool get isUpcoming => startTime.isAfter(DateTime.now());
  String get routeLabel => '$from → $to';
}

class DriverRideSeriesSummary {
  DriverRideSeriesSummary({
    required this.id,
    required List<DriverRideItem> occurrences,
  }) : occurrences = List<DriverRideItem>.unmodifiable(
         [...occurrences]..sort((a, b) => a.startTime.compareTo(b.startTime)),
       );

  final String id;
  final List<DriverRideItem> occurrences;

  DriverRideItem get _baselineRide {
    for (final ride in occurrences) {
      if (!ride.isCancelled) return ride;
    }
    return occurrences.first;
  }

  DriverRideItem get anchorRide => nextUpcomingOccurrence ?? occurrences.first;

  String get from => anchorRide.from;
  String get to => anchorRide.to;
  double get pricePerSeat => anchorRide.pricePerSeat;
  int get seatCapacity => anchorRide.seatsTotal;
  List<String> get recurrenceDays => _baselineRide.recurrenceDays;
  DateTime? get recurrenceEndDate => _baselineRide.recurrenceEndDate;
  DateTime get startDate => occurrences.first.startTime;
  DateTime get endDate => occurrences.last.startTime;

  List<DriverRideItem> get upcomingOccurrences => occurrences
      .where((ride) => ride.startTime.isAfter(DateTime.now()))
      .toList(growable: false);

  DriverRideItem? get nextUpcomingOccurrence {
    for (final ride in occurrences) {
      if (ride.startTime.isAfter(DateTime.now()) && !ride.isCancelled) {
        return ride;
      }
    }
    for (final ride in occurrences) {
      if (ride.startTime.isAfter(DateTime.now())) return ride;
    }
    return null;
  }

  int get totalOccurrences => occurrences.length;
  int get upcomingCount => upcomingOccurrences.length;
  int get cancelledCount => occurrences.where((ride) => ride.isCancelled).length;
  int get completedCount => occurrences.where((ride) => ride.isCompleted).length;
  int get modifiedCount => occurrences.where(isModifiedOccurrence).length;

  DriverRideSeriesLifecycle get lifecycleStatus {
    final futureOccurrences = upcomingOccurrences;
    if (futureOccurrences.isEmpty) {
      return DriverRideSeriesLifecycle.ended;
    }
    final hasActiveFuture = futureOccurrences.any((ride) => !ride.isCancelled);
    if (!hasActiveFuture) {
      return DriverRideSeriesLifecycle.paused;
    }
    return DriverRideSeriesLifecycle.active;
  }

  String get lifecycleLabel {
    switch (lifecycleStatus) {
      case DriverRideSeriesLifecycle.active:
        return 'Active';
      case DriverRideSeriesLifecycle.paused:
        return 'Paused';
      case DriverRideSeriesLifecycle.ended:
        return 'Ended';
    }
  }

  bool isModifiedOccurrence(DriverRideItem ride) {
    if (ride.isCancelled) return false;
    final baseline = _baselineRide;
    final sameWeekday = recurrenceDays.contains(
      rideRecurrenceWeekdayKey(ride.startTime),
    );
    final sameTimeOfDay =
        ride.startTime.hour == baseline.startTime.hour &&
        ride.startTime.minute == baseline.startTime.minute;
    final sameRoute = ride.from == baseline.from && ride.to == baseline.to;
    final sameSeats = ride.seatsTotal == baseline.seatsTotal;
    final samePrice =
        (ride.pricePerSeat - baseline.pricePerSeat).abs() < 0.01;
    final sameArrivalTime =
        ride.arrivalTime?.hour == baseline.arrivalTime?.hour &&
        ride.arrivalTime?.minute == baseline.arrivalTime?.minute;
    final sameStops = _sameList(ride.stops, baseline.stops);
    final sameAmenities = _sameList(ride.amenities, baseline.amenities);
    final sameNotes = (ride.notes ?? '').trim() == (baseline.notes ?? '').trim();

    return !sameWeekday ||
        !sameTimeOfDay ||
        !sameRoute ||
        !sameSeats ||
        !samePrice ||
        !sameArrivalTime ||
        !sameStops ||
        !sameAmenities ||
        !sameNotes;
  }

  static bool _sameList(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var index = 0; index < a.length; index++) {
      if (a[index] != b[index]) return false;
    }
    return true;
  }
}

class DriverRideListEntry {
  const DriverRideListEntry._({
    this.ride,
    this.series,
  });

  const DriverRideListEntry.occurrence(DriverRideItem ride) : this._(ride: ride);

  const DriverRideListEntry.series(DriverRideSeriesSummary series)
    : this._(series: series);

  final DriverRideItem? ride;
  final DriverRideSeriesSummary? series;

  bool get isSeries => series != null;
}
