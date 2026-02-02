import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:get/get.dart';
import '../../../shared/services/api_client.dart';
import '../routes/booking_routes.dart';
import '../models/booking.dart';
import '../services/bookings_api.dart';
import '../services/payments_api.dart';
import '../utils/booking_formatters.dart';
import '../../ride_requests/models/ride_request.dart';
import '../../ride_requests/services/ride_requests_api.dart';

enum MyRidesTab { upcoming, past, requests }

enum PaymentAttemptResult { confirmed, processing, cancelled, failed, refunded }

enum PaymentPollResult { paid, pending, failed, refunded }

enum BookingPaymentUiState {
  payNow,
  paymentPendingRetry,
  paymentFailedRetry,
  paymentComplete,
  refunded,
  hidden,
}

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
  final cancelingBookingIds = <String>{}.obs;
  final payingBookingIds = <String>{}.obs;
  final paymentIntentIds = <String, String>{}.obs;
  final paymentSessions = <String, PaymentIntentSession>{}.obs;

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
      _syncPaymentIntentIds(list);
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
          ..sort((a, b) => _bookingSortTime(b).compareTo(_bookingSortTime(a)));

    final past = bookings.where((b) => !b.ride.startTime.isAfter(now)).toList()
      ..sort((a, b) => _bookingSortTime(b).compareTo(_bookingSortTime(a)));

    if (tab.value == MyRidesTab.upcoming) return upcoming;
    if (tab.value == MyRidesTab.past) return past;
    return const [];
  }

  List<RideRequest> get filteredRequests {
    final list = rideRequests.toList()
      ..sort((a, b) => _requestSortTime(b).compareTo(_requestSortTime(a)));
    return list;
  }

  DateTime _bookingSortTime(Booking b) => b.updatedAt ?? b.createdAt;

  DateTime _requestSortTime(RideRequest r) => r.updatedAt ?? r.createdAt;

  bool canPay(Booking booking) =>
      shouldShowPayAction(booking) &&
      booking.ride.startTime.isAfter(DateTime.now());

  bool canCancelBooking(Booking booking) {
    if (!booking.ride.startTime.isAfter(DateTime.now())) return false;
    final status = booking.status.toLowerCase().trim();
    if (status.contains('cancel') ||
        status.contains('reject') ||
        status.contains('complete')) {
      return false;
    }
    return true;
  }

  bool shouldShowPayAction(Booking booking) {
    final state = paymentUiState(booking);
    return state == BookingPaymentUiState.payNow ||
        state == BookingPaymentUiState.paymentPendingRetry ||
        state == BookingPaymentUiState.paymentFailedRetry;
  }

  BookingPaymentUiState paymentUiState(Booking booking) {
    final bookingStatus = booking.status.toLowerCase().trim();
    final paymentStatus = booking.paymentStatus.toLowerCase().trim();
    final hasFutureRide = booking.ride.startTime.isAfter(DateTime.now());
    if (!hasFutureRide) return BookingPaymentUiState.hidden;

    final isAcceptedOrConfirmed =
        bookingStatus.contains('accepted') || bookingStatus.contains('confirm');
    final isCancelledOrRejected =
        bookingStatus.contains('cancel') || bookingStatus.contains('reject');
    final isPaymentPendingStatus =
        bookingStatus.contains('payment_pending') ||
        bookingStatus.contains('payment-pending');
    final isPaymentRelevantStatus =
        isAcceptedOrConfirmed || isPaymentPendingStatus;

    if (isCancelledOrRejected) {
      if (_isRefundedStatus(paymentStatus)) {
        return BookingPaymentUiState.refunded;
      }
      return BookingPaymentUiState.hidden;
    }

    if (_isRefundedStatus(paymentStatus)) {
      return BookingPaymentUiState.refunded;
    }
    if (_isPaidStatus(paymentStatus)) {
      return BookingPaymentUiState.paymentComplete;
    }
    if (_isFailedStatus(paymentStatus) && isPaymentRelevantStatus) {
      return BookingPaymentUiState.paymentFailedRetry;
    }
    if ((_isPendingStatus(paymentStatus) || isPaymentPendingStatus) &&
        isPaymentRelevantStatus) {
      return BookingPaymentUiState.paymentPendingRetry;
    }
    if (isPaymentRelevantStatus) {
      return BookingPaymentUiState.payNow;
    }

    return BookingPaymentUiState.hidden;
  }

  String payButtonLabel(Booking booking) {
    switch (paymentUiState(booking)) {
      case BookingPaymentUiState.paymentPendingRetry:
        return 'Payment in progress / retry';
      case BookingPaymentUiState.paymentFailedRetry:
        return 'Payment failed, retry';
      default:
        return 'Pay now';
    }
  }

  String? paymentStateLabel(Booking booking) {
    switch (paymentUiState(booking)) {
      case BookingPaymentUiState.paymentPendingRetry:
        return 'Payment in progress / retry';
      case BookingPaymentUiState.paymentComplete:
        return 'Payment complete';
      case BookingPaymentUiState.paymentFailedRetry:
        return 'Payment failed, retry';
      case BookingPaymentUiState.refunded:
        return 'Refunded';
      default:
        return null;
    }
  }

  bool isPaying(String bookingId) => payingBookingIds.contains(bookingId);

  bool isCancelingBooking(String bookingId) =>
      cancelingBookingIds.contains(bookingId);

  String? paymentIntentIdForBooking(String bookingId) =>
      paymentIntentIds[bookingId];

  PaymentIntentSession? paymentSessionForBooking(String bookingId) =>
      paymentSessions[bookingId];

  Future<PaymentAttemptResult> payToConfirm(Booking booking) async {
    final bookingId = booking.id.trim();
    if (bookingId.isEmpty) return PaymentAttemptResult.failed;
    if (payingBookingIds.contains(bookingId)) {
      return PaymentAttemptResult.processing;
    }

    payingBookingIds.add(bookingId);
    payingBookingIds.refresh();

    try {
      final session = await _paymentsApi.createPaymentIntent(
        bookingId: bookingId,
      );
      paymentSessions[bookingId] = session;
      paymentSessions.refresh();

      final paymentIntentId = (session.paymentIntentId ?? '').trim();
      if (paymentIntentId.isNotEmpty) {
        paymentIntentIds[bookingId] = paymentIntentId;
        paymentIntentIds.refresh();
      }

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: session.clientSecret,
          merchantDisplayName: 'HelpRide',
          applePay: const PaymentSheetApplePay(merchantCountryCode: 'CA'),
          style: ThemeMode.system,
        ),
      );

      await Stripe.instance.presentPaymentSheet();

      final pollResultRaw = await Get.toNamed(
        BookingRoutes.paymentProcessing,
        arguments: {
          'route': '${booking.ride.fromCity} \u2192 ${booking.ride.toCity}',
          'paymentIntentId':
              paymentIntentIds[bookingId] ?? booking.paymentIntentId,
          'pollFuture': _pollForPaymentStatus(
            bookingId: bookingId,
            paymentIntentId:
                paymentIntentIds[bookingId] ??
                booking.paymentIntentId ??
                session.paymentIntentId,
          ),
        },
      );
      final pollResult = pollResultRaw is String
          ? pollResultRaw
          : PaymentPollResult.pending.name;

      await fetch();

      final parsedPollResult = _parsePollResult(pollResult);
      if (parsedPollResult == PaymentPollResult.paid) {
        Get.snackbar('Payment complete', 'Booking confirmed.');
        if (Get.currentRoute != '/my-rides') {
          Get.offAllNamed('/my-rides');
        }
        return PaymentAttemptResult.confirmed;
      }
      if (parsedPollResult == PaymentPollResult.refunded) {
        Get.snackbar('Refunded', 'Payment was refunded.');
        return PaymentAttemptResult.refunded;
      }
      if (parsedPollResult == PaymentPollResult.failed) {
        Get.snackbar('Payment failed', 'Payment failed');
        return PaymentAttemptResult.failed;
      } else {
        Get.snackbar('Payment processing...', 'Waiting for PAID webhook.');
        return PaymentAttemptResult.processing;
      }
    } on StripeException catch (e) {
      final code = e.error.code.toString().toLowerCase();
      if (code.contains('cancel')) {
        Get.snackbar('Payment cancelled', 'Payment cancelled');
        return PaymentAttemptResult.cancelled;
      } else {
        Get.snackbar('Payment failed', e.error.message ?? 'Payment failed');
        return PaymentAttemptResult.failed;
      }
    } catch (e) {
      Get.snackbar('Payment failed', e.toString());
      return PaymentAttemptResult.failed;
    } finally {
      payingBookingIds.remove(bookingId);
      payingBookingIds.refresh();
    }
  }

  Future<PaymentPollResult> _pollForPaymentStatus({
    required String bookingId,
    String? paymentIntentId,
  }) async {
    final deadline = DateTime.now().add(const Duration(minutes: 2));
    final intentId = (paymentIntentId ?? '').trim();

    while (DateTime.now().isBefore(deadline)) {
      if (intentId.isNotEmpty) {
        try {
          final intent = await _paymentsApi.getPaymentIntentStatus(
            paymentIntentId: intentId,
          );
          _mergeIntentStatus(bookingId, intent);

          final mergedStatus = _mergedPaymentStatus(intent);
          if (_isPaidStatus(mergedStatus)) return PaymentPollResult.paid;
          if (_isRefundedStatus(mergedStatus)) {
            return PaymentPollResult.refunded;
          }
          if (_isFailedStatus(mergedStatus)) return PaymentPollResult.failed;
        } catch (_) {
          // Keep fallback polling on bookings endpoint.
        }
      }

      try {
        final list = await _api.myBookings();
        bookings.assignAll(list);
        _syncPaymentIntentIds(list);

        final match = _findBooking(list, bookingId);
        if (match != null) {
          final paymentStatus = match.paymentStatus.toLowerCase();
          if (_isPaidStatus(paymentStatus)) {
            return PaymentPollResult.paid;
          }
          if (_isRefundedStatus(paymentStatus)) {
            return PaymentPollResult.refunded;
          }
          if (_isFailedStatus(paymentStatus)) {
            return PaymentPollResult.failed;
          }
        }
      } catch (_) {
        // Best-effort polling.
      }

      await Future.delayed(const Duration(seconds: 3));
    }

    return PaymentPollResult.pending;
  }

  PaymentPollResult _parsePollResult(String value) {
    switch (value) {
      case 'paid':
        return PaymentPollResult.paid;
      case 'refunded':
        return PaymentPollResult.refunded;
      case 'failed':
        return PaymentPollResult.failed;
      default:
        return PaymentPollResult.pending;
    }
  }

  void _syncPaymentIntentIds(List<Booking> list) {
    final known = <String, String>{...paymentIntentIds};
    for (final booking in list) {
      final id = booking.id.trim();
      final paymentIntentId = (booking.paymentIntentId ?? '').trim();
      if (id.isEmpty || paymentIntentId.isEmpty) continue;
      known[id] = paymentIntentId;
    }
    paymentIntentIds.assignAll(known);
  }

  void _mergeIntentStatus(String bookingId, PaymentIntentStatus status) {
    final bookingKey = bookingId.trim();
    if (bookingKey.isEmpty) return;

    if (status.paymentIntentId.trim().isNotEmpty) {
      paymentIntentIds[bookingKey] = status.paymentIntentId.trim();
      paymentIntentIds.refresh();
    }

    final current = paymentSessions[bookingKey];
    paymentSessions[bookingKey] = PaymentIntentSession(
      clientSecret: current?.clientSecret ?? '',
      paymentIntentId: status.paymentIntentId.trim().isEmpty
          ? current?.paymentIntentId
          : status.paymentIntentId.trim(),
      amount: status.amount ?? current?.amount,
      currency: status.currency ?? current?.currency,
    );
    paymentSessions.refresh();
  }

  String _mergedPaymentStatus(PaymentIntentStatus status) {
    final bookingPaymentStatus = (status.bookingPaymentStatus ?? '').trim();
    if (bookingPaymentStatus.isNotEmpty) return bookingPaymentStatus;
    return status.intentStatus;
  }

  bool _isPaidStatus(String status) {
    return isPaymentPaidStatus(status);
  }

  bool _isPendingStatus(String status) {
    final v = status.toLowerCase();
    return v.contains('pending') ||
        v.contains('processing') ||
        v.contains('requires_action') ||
        v.contains('requires-confirmation') ||
        v.contains('requires_confirmation');
  }

  bool _isFailedStatus(String status) {
    final v = status.toLowerCase();
    return v.contains('failed') ||
        v.contains('cancelled') ||
        v.contains('canceled') ||
        v.contains('requires_payment_method') ||
        v.contains('declined');
  }

  bool _isRefundedStatus(String status) {
    final v = status.toLowerCase();
    return v.contains('refund');
  }

  Booking? _findBooking(List<Booking> list, String id) {
    for (final booking in list) {
      if (booking.id == id) return booking;
    }
    return null;
  }

  void _upsertBooking(Booking booking) {
    final idx = bookings.indexWhere((b) => b.id == booking.id);
    if (idx == -1) {
      bookings.insert(0, booking);
    } else {
      bookings[idx] = booking;
    }
    bookings.refresh();
    _syncPaymentIntentIds(bookings);
  }

  Future<void> cancelBooking(Booking booking) async {
    final bookingId = booking.id.trim();
    if (bookingId.isEmpty) return;
    if (cancelingBookingIds.contains(bookingId)) return;

    cancelingBookingIds.add(bookingId);
    cancelingBookingIds.refresh();
    try {
      final updated = await _api.cancelBooking(bookingId);
      _upsertBooking(updated);
      Get.snackbar('Cancelled', 'Booking cancelled.');
    } catch (e) {
      Get.snackbar('Failed', e.toString());
    } finally {
      cancelingBookingIds.remove(bookingId);
      cancelingBookingIds.refresh();
    }
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
