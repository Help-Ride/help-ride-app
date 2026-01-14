import 'package:get/get.dart';
import 'package:help_ride/features/bookings/models/booking.dart';
import 'package:help_ride/features/bookings/services/bookings_api.dart';
import 'package:help_ride/shared/services/api_client.dart';

enum DriverRequestsTab { all, newRequests, offered }

class DriverRequestsController extends GetxController {
  late final BookingsApi _api;

  final tab = DriverRequestsTab.all.obs;
  final loading = false.obs;
  final error = RxnString();
  final bookings = <Booking>[].obs;
  final actionIds = <String>{}.obs;

  @override
  Future<void> onInit() async {
    super.onInit();
    final client = await ApiClient.create();
    _api = BookingsApi(client);
    await fetch();
  }

  void setTab(DriverRequestsTab t) => tab.value = t;

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

  List<Booking> get filtered {
    if (tab.value == DriverRequestsTab.all) return bookings;
    if (tab.value == DriverRequestsTab.newRequests) {
      return bookings.where(_isNew).toList();
    }
    return bookings.where(_isOffered).toList();
  }

  int get newCount => bookings.where(_isNew).length;
  int get offeredCount => bookings.where(_isOffered).length;

  Future<void> fetch() async {
    loading.value = true;
    error.value = null;
    try {
      final list = await _api.driverBookings();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      bookings.assignAll(list);
    } catch (e) {
      error.value = e.toString();
    } finally {
      loading.value = false;
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
    final idx = bookings.indexWhere((b) => b.id == bookingId);
    if (idx == -1) return;
    bookings[idx] = _withStatus(bookings[idx], status);
  }

  Future<void> confirm(String bookingId) async {
    if (isActing(bookingId)) return;
    actionIds.add(bookingId);
    actionIds.refresh();
    try {
      await _api.confirmBooking(bookingId);
      _updateStatus(bookingId, 'confirmed');
      Get.snackbar('Offer sent', 'Booking confirmed.');
    } catch (e) {
      Get.snackbar('Failed', e.toString());
    } finally {
      actionIds.remove(bookingId);
      actionIds.refresh();
    }
  }

  Future<void> reject(String bookingId) async {
    if (isActing(bookingId)) return;
    actionIds.add(bookingId);
    actionIds.refresh();
    try {
      await _api.rejectBooking(bookingId);
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
