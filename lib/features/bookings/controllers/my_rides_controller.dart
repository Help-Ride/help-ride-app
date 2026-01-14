import 'package:get/get.dart';
import '../../../shared/services/api_client.dart';
import '../models/booking.dart';
import '../services/bookings_api.dart';

enum MyRidesTab { upcoming, past }

class MyRidesController extends GetxController {
  late final BookingsApi _api;

  final tab = MyRidesTab.upcoming.obs;
  final loading = false.obs;
  final error = RxnString();

  final bookings = <Booking>[].obs;

  @override
  Future<void> onInit() async {
    super.onInit();
    final client = await ApiClient.create();
    _api = BookingsApi(client);
    await fetch();
  }

  Future<void> fetch() async {
    loading.value = true;
    error.value = null;
    try {
      final list = await _api.myBookings();
      bookings.assignAll(list);
    } catch (e) {
      error.value = e.toString();
    } finally {
      loading.value = false;
    }
  }

  void setTab(MyRidesTab t) => tab.value = t;

  List<Booking> get filtered {
    final now = DateTime.now();
    final upcoming =
        bookings.where((b) => b.ride.startTime.isAfter(now)).toList()
          ..sort((a, b) => a.ride.startTime.compareTo(b.ride.startTime));

    final past = bookings.where((b) => !b.ride.startTime.isAfter(now)).toList()
      ..sort((a, b) => b.ride.startTime.compareTo(a.ride.startTime));

    return tab.value == MyRidesTab.upcoming ? upcoming : past;
  }
}
