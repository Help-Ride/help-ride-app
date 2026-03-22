import 'package:get/get.dart';

import '../../../shared/services/api_client.dart';
import '../models/driver_ride_management.dart';
import '../utils/driver_ride_grouping.dart';

class DriverRideSeriesController extends GetxController {
  final loading = false.obs;
  final error = RxnString();
  final series = Rxn<DriverRideSeriesSummary>();
  final occurrenceFilter = DriverRideOccurrenceFilter.all.obs;

  late final ApiClient _client;

  String get seriesId {
    final fromParams = (Get.parameters['seriesId'] ?? '').toString().trim();
    if (fromParams.isNotEmpty) return fromParams;
    final args = Get.arguments;
    if (args is Map) {
      final fromArgs = (args['seriesId'] ?? '').toString().trim();
      if (fromArgs.isNotEmpty) return fromArgs;
    }
    return '';
  }

  @override
  Future<void> onInit() async {
    super.onInit();
    _client = await ApiClient.create();
    await fetch();
  }

  void setOccurrenceFilter(DriverRideOccurrenceFilter value) {
    occurrenceFilter.value = value;
  }

  Future<void> fetch() async {
    if (seriesId.isEmpty) {
      error.value = 'Missing recurring series id.';
      return;
    }

    loading.value = true;
    error.value = null;
    try {
      final res = await _client.get<dynamic>('/rides/me/list');
      final raw = res.data;
      if (raw is! List) {
        error.value = 'Recurring series not found.';
        return;
      }

      final items = raw
          .whereType<Map>()
          .map((item) => mapDriverRideItem(item.cast<String, dynamic>()))
          .toList(growable: false);
      final summaries = buildDriverRideSeriesSummaries(items);
      DriverRideSeriesSummary? match;
      for (final item in summaries) {
        if (item.id == seriesId) {
          match = item;
          break;
        }
      }

      if (match == null) {
        error.value = 'Recurring series not found.';
        return;
      }

      series.value = match;
    } catch (e) {
      error.value = e.toString();
    } finally {
      loading.value = false;
    }
  }

  List<DriverRideItem> get filteredOccurrences {
    final currentSeries = series.value;
    if (currentSeries == null) return const <DriverRideItem>[];

    final now = DateTime.now();
    final filtered = currentSeries.occurrences.where((ride) {
      switch (occurrenceFilter.value) {
        case DriverRideOccurrenceFilter.all:
          return true;
        case DriverRideOccurrenceFilter.upcoming:
          return ride.startTime.isAfter(now);
        case DriverRideOccurrenceFilter.modified:
          return currentSeries.isModifiedOccurrence(ride);
        case DriverRideOccurrenceFilter.cancelled:
          return ride.isCancelled;
        case DriverRideOccurrenceFilter.completed:
          return ride.isCompleted;
      }
    }).toList(growable: false);

    filtered.sort((left, right) => left.startTime.compareTo(right.startTime));
    return filtered;
  }
}
