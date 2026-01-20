import 'package:get/get.dart';
import '../../../shared/services/api_client.dart';
import '../models/booking.dart';
import '../services/bookings_api.dart';
import '../../ride_requests/models/ride_request.dart';
import '../../ride_requests/services/ride_requests_api.dart';

enum MyRidesTab { upcoming, past, requests }

class MyRidesController extends GetxController {
  late final BookingsApi _api;
  late final RideRequestsApi _requestsApi;

  final tab = MyRidesTab.upcoming.obs;
  final loading = false.obs;
  final error = RxnString();

  final bookings = <Booking>[].obs;
  final rideRequests = <RideRequest>[].obs;
  final cancelingRequestIds = <String>{}.obs;

  @override
  Future<void> onInit() async {
    super.onInit();
    final client = await ApiClient.create();
    _api = BookingsApi(client);
    _requestsApi = RideRequestsApi(client);
    await fetch();
  }

  Future<void> fetch() async {
    loading.value = true;
    error.value = null;
    try {
      final list = await _api.myBookings();
      final requests = await _requestsApi.myRideRequests();
      bookings.assignAll(list);
      rideRequests.assignAll(requests);
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

    if (tab.value == MyRidesTab.upcoming) return upcoming;
    if (tab.value == MyRidesTab.past) return past;
    return const [];
  }

  List<RideRequest> get filteredRequests {
    final list = rideRequests.toList()
      ..sort((a, b) => a.preferredDate.compareTo(b.preferredDate));
    return list;
  }

  Future<void> cancelRequest(String id) async {
    if (cancelingRequestIds.contains(id)) return;
    cancelingRequestIds.add(id);
    cancelingRequestIds.refresh();
    try {
      await _requestsApi.deleteRideRequest(id);
      rideRequests.removeWhere((r) => r.id == id);
      Get.snackbar('Cancelled', 'Ride request cancelled.');
    } catch (e) {
      Get.snackbar('Failed', e.toString());
    } finally {
      cancelingRequestIds.remove(id);
      cancelingRequestIds.refresh();
    }
  }
}
