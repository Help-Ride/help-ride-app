import 'package:get/get.dart';

import '../../../shared/services/api_client.dart';
import '../models/driver_ride_management.dart';
import '../services/driver_rides_api.dart';
import '../utils/driver_ride_grouping.dart';

class DriverMyRidesController extends GetxController {
  final tab = DriverRidesTab.upcoming.obs;
  final listFilter = DriverRideListFilter.all.obs;
  final loading = false.obs;
  final error = RxnString();

  final rides = <DriverRideItem>[].obs;

  late final ApiClient _client;
  late final DriverRidesApi _driverApi;

  @override
  Future<void> onInit() async {
    super.onInit();
    _client = await ApiClient.create();
    _driverApi = DriverRidesApi(_client);
    await refreshAll();
  }

  void setTab(DriverRidesTab value) => tab.value = value;
  void setListFilter(DriverRideListFilter value) => listFilter.value = value;

  List<DriverRideSeriesSummary> get recurringSeries =>
      buildDriverRideSeriesSummaries(rides);

  List<DriverRideListEntry> get filteredEntries {
    final seriesEntries = recurringSeries
        .where(_matchesSeriesTab)
        .where(_matchesSeriesFilter)
        .map(DriverRideListEntry.series)
        .toList(growable: false);

    final occurrenceEntries = rides
        .where(_matchesOccurrenceTab)
        .where(_matchesOccurrenceFilter)
        .map(DriverRideListEntry.occurrence)
        .toList(growable: false);

    final entries = switch (listFilter.value) {
      DriverRideListFilter.all => <DriverRideListEntry>[
        ...occurrenceEntries.where((entry) => !(entry.ride?.isRecurring ?? false)),
        ...seriesEntries,
      ],
      DriverRideListFilter.oneTime => occurrenceEntries
          .where((entry) => !(entry.ride?.isRecurring ?? false))
          .toList(growable: false),
      DriverRideListFilter.recurring => seriesEntries,
      DriverRideListFilter.cancelled => <DriverRideListEntry>[
        ...occurrenceEntries.where((entry) => entry.ride?.isCancelled ?? false),
        ...seriesEntries,
      ],
      DriverRideListFilter.occurrences => occurrenceEntries,
    };

    entries.sort((left, right) {
      final leftTime = _entrySortTime(left);
      final rightTime = _entrySortTime(right);
      if (tab.value == DriverRidesTab.upcoming) {
        return leftTime.compareTo(rightTime);
      }
      return rightTime.compareTo(leftTime);
    });

    return entries;
  }

  bool _matchesOccurrenceTab(DriverRideItem ride) {
    final now = DateTime.now();
    return tab.value == DriverRidesTab.upcoming
        ? ride.startTime.isAfter(now)
        : !ride.startTime.isAfter(now);
  }

  bool _matchesSeriesTab(DriverRideSeriesSummary series) {
    if (tab.value == DriverRidesTab.upcoming) {
      return series.upcomingCount > 0;
    }
    return series.upcomingCount == 0;
  }

  bool _matchesOccurrenceFilter(DriverRideItem ride) {
    switch (listFilter.value) {
      case DriverRideListFilter.all:
        return true;
      case DriverRideListFilter.oneTime:
        return !ride.isRecurring;
      case DriverRideListFilter.recurring:
        return false;
      case DriverRideListFilter.cancelled:
        return ride.isCancelled;
      case DriverRideListFilter.occurrences:
        return true;
    }
  }

  bool _matchesSeriesFilter(DriverRideSeriesSummary series) {
    switch (listFilter.value) {
      case DriverRideListFilter.all:
      case DriverRideListFilter.recurring:
        return true;
      case DriverRideListFilter.cancelled:
        return series.cancelledCount > 0;
      case DriverRideListFilter.oneTime:
      case DriverRideListFilter.occurrences:
        return false;
    }
  }

  DateTime _entrySortTime(DriverRideListEntry entry) {
    if (entry.isSeries) {
      final series = entry.series!;
      return tab.value == DriverRidesTab.upcoming
          ? (series.nextUpcomingOccurrence?.startTime ?? series.endDate)
          : series.endDate;
    }
    return entry.ride!.startTime;
  }

  Future<void> refreshAll() async {
    loading.value = true;
    error.value = null;

    try {
      final res = await _client.get<dynamic>('/rides/me/list');
      final raw = res.data;

      if (raw is! List) {
        rides.clear();
        return;
      }

      final parsed = raw
          .whereType<Map>()
          .map((item) => mapDriverRideItem(item.cast<String, dynamic>()))
          .toList(growable: false);

      rides.assignAll(parsed);
    } catch (e) {
      error.value = e.toString();
    } finally {
      loading.value = false;
    }
  }

  Future<void> cancelRide(
    String rideId, {
    String scope = 'occurrence',
  }) async {
    loading.value = true;
    error.value = null;

    try {
      await _driverApi.cancelRide(rideId, scope: scope);
      await refreshAll();
      Get.snackbar(
        'Cancelled',
        scope == 'occurrence'
            ? 'Ride occurrence cancelled successfully.'
            : 'Recurring ride schedule updated successfully.',
      );
    } catch (e) {
      error.value = e.toString();
      Get.snackbar('Cancel failed', error.value ?? 'Failed');
    } finally {
      loading.value = false;
    }
  }
}
