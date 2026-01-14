import 'package:get/get.dart';
import 'package:help_ride/features/bookings/models/booking.dart';
import 'package:help_ride/features/bookings/services/bookings_api.dart';
import 'package:help_ride/features/rides/models/ride.dart';
import 'package:help_ride/features/rides/services/rides_api.dart';
import 'package:help_ride/shared/services/api_client.dart';

enum DriverRideRequestsTab { all, newRequests, offered }

class DriverRideDetailsController extends GetxController {
  final loading = false.obs;
  final error = RxnString();
  final ride = Rxn<Ride>();

  final requestsLoading = false.obs;
  final requestsError = RxnString();
  final requests = <Booking>[].obs;
  final requestsTab = DriverRideRequestsTab.all.obs;
  final actionIds = <String>{}.obs;

  late final RidesApi _ridesApi;
  late final BookingsApi _bookingsApi;

  String get rideId => Get.parameters['id'] ?? '';

  @override
  Future<void> onInit() async {
    super.onInit();
    final client = await ApiClient.create();
    _ridesApi = RidesApi(client);
    _bookingsApi = BookingsApi(client);

    if (rideId.trim().isEmpty) {
      error.value = 'Missing ride id.';
      return;
    }

    await fetch();
    await fetchRequests();
  }

  Future<void> fetch() async {
    loading.value = true;
    error.value = null;
    try {
      ride.value = await _ridesApi.getRideById(rideId);
    } catch (e) {
      error.value = e.toString();
    } finally {
      loading.value = false;
    }
  }

  void setRequestsTab(DriverRideRequestsTab t) => requestsTab.value = t;

  bool isActing(String id) => actionIds.contains(id);

  bool _isNew(Booking b) {
    final s = b.status.toLowerCase();
    return s.contains('pending') ||
        s.contains('new') ||
        s.contains('requested') ||
        s.contains('request');
  }

  bool _isOffered(Booking b) {
    final s = b.status.toLowerCase();
    return s.contains('confirm') ||
        s.contains('accepted') ||
        s.contains('offer');
  }

  List<Booking> get filteredRequests {
    if (requestsTab.value == DriverRideRequestsTab.all) return requests;
    if (requestsTab.value == DriverRideRequestsTab.newRequests) {
      return requests.where(_isNew).toList();
    }
    return requests.where(_isOffered).toList();
  }

  int get newCount => requests.where(_isNew).length;
  int get offeredCount => requests.where(_isOffered).length;

  Future<void> fetchRequests() async {
    requestsLoading.value = true;
    requestsError.value = null;
    try {
      final list = await _bookingsApi.bookingsForRide(rideId);
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      requests.assignAll(list);
    } catch (e) {
      requestsError.value = e.toString();
    } finally {
      requestsLoading.value = false;
    }
  }

  Booking _withStatus(Booking b, String status) {
    return Booking(
      id: b.id,
      rideId: b.rideId,
      passengerId: b.passengerId,
      seatsBooked: b.seatsBooked,
      status: status,
      paymentStatus: b.paymentStatus,
      createdAt: b.createdAt,
      updatedAt: DateTime.now(),
      ride: b.ride,
      passenger: b.passenger,
      note: b.note,
    );
  }

  void _updateStatus(String bookingId, String status) {
    final idx = requests.indexWhere((b) => b.id == bookingId);
    if (idx == -1) return;
    requests[idx] = _withStatus(requests[idx], status);
  }

  Future<void> confirmBooking(String bookingId) async {
    if (isActing(bookingId)) return;
    actionIds.add(bookingId);
    actionIds.refresh();
    try {
      await _bookingsApi.confirmBooking(bookingId);
      _updateStatus(bookingId, 'confirmed');
      Get.snackbar('Offer sent', 'Booking confirmed.');
    } catch (e) {
      Get.snackbar('Failed', e.toString());
    } finally {
      actionIds.remove(bookingId);
      actionIds.refresh();
    }
  }

  Future<void> rejectBooking(String bookingId) async {
    if (isActing(bookingId)) return;
    actionIds.add(bookingId);
    actionIds.refresh();
    try {
      await _bookingsApi.rejectBooking(bookingId);
      _updateStatus(bookingId, 'rejected');
      Get.snackbar('Declined', 'Booking rejected.');
    } catch (e) {
      Get.snackbar('Failed', e.toString());
    } finally {
      actionIds.remove(bookingId);
      actionIds.refresh();
    }
  }
}
