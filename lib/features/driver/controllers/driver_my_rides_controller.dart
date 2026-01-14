import 'package:get/get.dart';
import '../../../shared/services/api_client.dart';

enum DriverRidesTab { upcoming, past }

class DriverRideItem {
  final String id;
  final String from;
  final String to;
  final DateTime startTime;
  final int seatsTotal;
  final int seatsAvailable;
  final double pricePerSeat;
  final String status; // open/ongoing/completed/cancelled

  DriverRideItem({
    required this.id,
    required this.from,
    required this.to,
    required this.startTime,
    required this.seatsTotal,
    required this.seatsAvailable,
    required this.pricePerSeat,
    required this.status,
  });

  int get booked => (seatsTotal - seatsAvailable).clamp(0, seatsTotal);
}

class DriverMyRidesController extends GetxController {
  final tab = DriverRidesTab.upcoming.obs;
  final loading = false.obs;
  final error = RxnString();

  final rides = <DriverRideItem>[].obs;

  late final ApiClient _client;

  @override
  Future<void> onInit() async {
    super.onInit();
    _client = await ApiClient.create();
    await refreshAll();
  }

  void setTab(DriverRidesTab t) => tab.value = t;

  List<DriverRideItem> get filtered {
    final now = DateTime.now();

    final upcoming = rides.where((r) => r.startTime.isAfter(now)).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    final past = rides.where((r) => !r.startTime.isAfter(now)).toList()
      ..sort((a, b) => b.startTime.compareTo(a.startTime));

    return tab.value == DriverRidesTab.upcoming ? upcoming : past;
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
          .map((m) => _mapRide(m.cast<String, dynamic>()))
          .toList();

      rides.assignAll(parsed);
    } catch (e) {
      error.value = e.toString();
    } finally {
      loading.value = false;
    }
  }

  DriverRideItem _mapRide(Map<String, dynamic> j) {
    double toDouble(dynamic v) {
      if (v is num) return v.toDouble();
      return double.tryParse(v?.toString() ?? '') ?? 0;
    }

    DateTime parseDate(dynamic v) {
      final s = (v ?? '').toString();
      final dt = DateTime.tryParse(s);
      return (dt ?? DateTime.now()).toLocal();
    }

    return DriverRideItem(
      id: (j['id'] ?? '').toString(),
      from: (j['fromCity'] ?? '').toString(),
      to: (j['toCity'] ?? '').toString(),
      startTime: parseDate(j['startTime']),
      seatsTotal: (j['seatsTotal'] as num?)?.toInt() ?? 0,
      seatsAvailable: (j['seatsAvailable'] as num?)?.toInt() ?? 0,
      pricePerSeat: toDouble(j['pricePerSeat']),
      status: (j['status'] ?? 'open').toString(),
    );
  }
}
