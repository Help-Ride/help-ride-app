import 'package:get/get.dart';
import 'package:help_ride/features/driver/services/driver_earnings_api.dart';
import 'package:help_ride/shared/services/api_client.dart';

class DriverHomeController extends GetxController {
  static const int pageLimit = 20;

  final summary = const DriverSummary.empty().obs;
  final summaryLoading = false.obs;
  final summaryError = RxnString();

  final earnings = <DriverEarningPayment>[].obs;
  final earningsLoading = false.obs;
  final earningsError = RxnString();
  final loadingMore = false.obs;
  final nextCursor = RxnString();

  late final DriverEarningsApi _earningsApi;

  @override
  Future<void> onInit() async {
    super.onInit();
    final client = await ApiClient.create();
    _earningsApi = DriverEarningsApi(client);
    await refreshAll();
  }

  Future<void> refreshAll() async {
    await Future.wait([fetchSummary(), fetchEarnings(reset: true)]);
  }

  Future<void> fetchSummary() async {
    summaryLoading.value = true;
    summaryError.value = null;
    try {
      summary.value = await _earningsApi.fetchDriverSummary();
    } catch (e) {
      summaryError.value = e.toString();
    } finally {
      summaryLoading.value = false;
    }
  }

  Future<void> fetchEarnings({bool reset = false}) async {
    final cursor = nextCursor.value;

    if (reset) {
      if (earningsLoading.value) return;
      earningsLoading.value = true;
      earningsError.value = null;
    } else {
      if (loadingMore.value || earningsLoading.value) return;
      if (cursor == null || cursor.trim().isEmpty) return;
      loadingMore.value = true;
      earningsError.value = null;
    }

    try {
      final page = await _earningsApi.fetchDriverEarnings(
        status: 'succeeded',
        limit: pageLimit,
        cursor: reset ? null : cursor,
      );

      if (reset) {
        earnings.assignAll(page.payments);
      } else {
        _appendUnique(page.payments);
      }
      nextCursor.value = page.nextCursor;
    } catch (e) {
      earningsError.value = e.toString();
    } finally {
      if (reset) {
        earningsLoading.value = false;
      } else {
        loadingMore.value = false;
      }
    }
  }

  Future<void> loadMoreEarnings() async {
    await fetchEarnings();
  }

  bool get hasMoreEarnings {
    final cursor = nextCursor.value;
    return cursor != null && cursor.trim().isNotEmpty;
  }

  void _appendUnique(List<DriverEarningPayment> incoming) {
    if (incoming.isEmpty) return;
    final seenIds = earnings
        .map((payment) => payment.id)
        .where((id) => id.trim().isNotEmpty)
        .toSet();

    final unique = incoming.where((payment) {
      final id = payment.id.trim();
      if (id.isEmpty) return true;
      if (seenIds.contains(id)) return false;
      seenIds.add(id);
      return true;
    });

    earnings.addAll(unique);
  }
}
