import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:get/get.dart';
import '../../../shared/services/api_client.dart';
import '../models/booking.dart';
import '../services/bookings_api.dart';
import '../services/payments_api.dart';
import '../../ride_requests/models/ride_request.dart';
import '../../ride_requests/services/ride_requests_api.dart';

enum MyRidesTab { upcoming, past, requests }

class MyRidesController extends GetxController {
  late final BookingsApi _api;
  late final RideRequestsApi _requestsApi;
  late final PaymentsApi _paymentsApi;

  final tab = MyRidesTab.upcoming.obs;
  final loading = false.obs;
  final error = RxnString();

  final bookings = <Booking>[].obs;
  final rideRequests = <RideRequest>[].obs;
  final cancelingRequestIds = <String>{}.obs;
  final payingBookingIds = <String>{}.obs;

  @override
  Future<void> onInit() async {
    super.onInit();
    final client = await ApiClient.create();
    _api = BookingsApi(client);
    _requestsApi = RideRequestsApi(client);
    _paymentsApi = PaymentsApi(client);
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
          ..sort(
            (a, b) => _bookingSortTime(b).compareTo(_bookingSortTime(a)),
          );

    final past = bookings.where((b) => !b.ride.startTime.isAfter(now)).toList()
      ..sort((a, b) => _bookingSortTime(b).compareTo(_bookingSortTime(a)));

    if (tab.value == MyRidesTab.upcoming) return upcoming;
    if (tab.value == MyRidesTab.past) return past;
    return const [];
  }

  List<RideRequest> get filteredRequests {
    final list = rideRequests.toList()
      ..sort(
        (a, b) => _requestSortTime(b).compareTo(_requestSortTime(a)),
      );
    return list;
  }

  DateTime _bookingSortTime(Booking b) => b.updatedAt ?? b.createdAt;

  DateTime _requestSortTime(RideRequest r) => r.updatedAt ?? r.createdAt;

  bool canPay(Booking booking) =>
      booking.status.toLowerCase() == 'accepted' &&
      booking.ride.startTime.isAfter(DateTime.now());

  bool isPaying(String bookingId) =>
      payingBookingIds.contains(bookingId);

  Future<void> payToConfirm(Booking booking) async {
    final id = booking.id.trim();
    if (id.isEmpty) return;
    if (payingBookingIds.contains(id)) return;

    payingBookingIds.add(id);
    payingBookingIds.refresh();

    try {
      final clientSecret =
          await _paymentsApi.createPaymentIntent(bookingId: id);

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'Help Ride',
          style: ThemeMode.system,
        ),
      );

      await Stripe.instance.presentPaymentSheet();

      final confirmed = await _pollForConfirmation(id);
      if (confirmed) {
        Get.snackbar('Payment complete', 'Booking confirmed.');
      } else {
        Get.snackbar(
          'Payment submitted',
          'Waiting for confirmation. Check back soon.',
        );
      }
    } on StripeException catch (e) {
      final code = e.error.code.toString().toLowerCase();
      if (code.contains('cancel')) {
        Get.snackbar('Payment cancelled', 'You can try again anytime.');
      } else {
        Get.snackbar(
          'Payment failed',
          e.error.message ?? 'Please try again.',
        );
      }
    } catch (e) {
      Get.snackbar('Payment failed', e.toString());
    } finally {
      payingBookingIds.remove(id);
      payingBookingIds.refresh();
    }
  }

  Future<bool> _pollForConfirmation(String bookingId) async {
    final deadline = DateTime.now().add(const Duration(seconds: 15));

    while (DateTime.now().isBefore(deadline)) {
      try {
        final list = await _api.myBookings();
        bookings.assignAll(list);
        final match = _findBooking(list, bookingId);
        if (match != null &&
            match.status.toLowerCase() == 'confirmed') {
          return true;
        }
      } catch (_) {
        // Best-effort polling.
      }

      await Future.delayed(const Duration(seconds: 3));
    }

    return false;
  }

  Booking? _findBooking(List<Booking> list, String id) {
    for (final booking in list) {
      if (booking.id == id) return booking;
    }
    return null;
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
