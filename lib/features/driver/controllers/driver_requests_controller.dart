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
      list.sort((a, b) => _bookingSortTime(b).compareTo(_bookingSortTime(a)));
      bookings.assignAll(list);
    } catch (e) {
      error.value = e.toString();
    } finally {
      loading.value = false;
    }
  }

  DateTime _bookingSortTime(Booking b) => b.updatedAt ?? b.createdAt;

  void _upsertBooking(Booking booking) {
    final idx = bookings.indexWhere((b) => b.id == booking.id);
    if (idx == -1) {
      bookings.insert(0, booking);
      return;
    }
    bookings[idx] = booking;
  }

  Future<void> confirm(String bookingId) async {
    if (isActing(bookingId)) return;
    actionIds.add(bookingId);
    actionIds.refresh();
    try {
      final updated = await _api.confirmBooking(bookingId);
      _upsertBooking(updated);
      final status = updated.status.toLowerCase();
      if (status.contains('confirm')) {
        Get.snackbar('Confirmed', 'Booking confirmed.');
      } else {
        Get.snackbar(
          'Accepted',
          'Booking accepted. Waiting for passenger payment to confirm.',
        );
      }
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
      final updated = await _api.rejectBooking(bookingId);
      _upsertBooking(updated);
      Get.snackbar('Declined', 'Booking rejected.');
    } catch (e) {
      Get.snackbar('Failed', e.toString());
    } finally {
      actionIds.remove(bookingId);
      actionIds.refresh();
    }
  }
}
