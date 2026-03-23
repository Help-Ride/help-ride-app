import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:help_ride/features/bookings/utils/booking_formatters.dart';
import 'package:help_ride/features/chat/services/chat_api.dart';
import 'package:help_ride/features/chat/views/chat_thread_view.dart';
import 'package:help_ride/features/rides/models/ride.dart';
import 'package:help_ride/features/rides/services/rides_api.dart';
import 'package:help_ride/features/rides/widgets/confirm_booking_sheet.dart';
import 'package:help_ride/shared/controllers/session_controller.dart';
import 'package:help_ride/shared/services/api_client.dart';
import 'package:help_ride/shared/services/api_exception.dart';

import 'package:help_ride/features/bookings/services/bookings_api.dart';

class RideDetailsController extends GetxController {
  late final RidesApi _ridesApi;
  late final BookingsApi _bookingsApi;
  late final ChatApi _chatApi;

  final loading = false.obs;
  final error = RxnString();
  final ride = Rxn<Ride>();

  final selectedSeats = 1.obs;
  final bookingPickupName = RxnString();
  final bookingPickupLat = Rxn<double>();
  final bookingPickupLng = Rxn<double>();
  final bookingDropoffName = RxnString();
  final bookingDropoffLat = Rxn<double>();
  final bookingDropoffLng = Rxn<double>();
  bool _openConfirmSheetOnLoad = false;
  bool _didAutoOpenConfirmSheet = false;
  String? _bookingId;
  String? _bookingStatus;
  String? _bookingPaymentStatus;
  String? _bookingPassengerId;

  String get rideId => Get.parameters['id'] ?? '';
  bool get hasBookingContext => _nonEmpty(_bookingId) != null;
  bool get hasBookingRouteContext =>
      _nonEmpty(bookingPickupName.value) != null ||
      _nonEmpty(bookingDropoffName.value) != null;
  bool get isBookingConfirmed =>
      _isConfirmedBookingStatus(_bookingStatus ?? '');
  bool get isBookingPaid => isPaymentPaidStatus(_bookingPaymentStatus ?? '');
  bool get canOpenBookingChat =>
      hasBookingContext && isBookingConfirmed && isBookingPaid;
  String get bookingInfoMessage =>
      'Information will be shared once ride confirmed.';

  String get tripPickupName =>
      _nonEmpty(bookingPickupName.value) ??
      _nonEmpty(ride.value?.fromCity) ??
      '-';

  String get tripDropoffName =>
      _nonEmpty(bookingDropoffName.value) ??
      _nonEmpty(ride.value?.toCity) ??
      '-';

  double? get tripPickupLat =>
      hasBookingRouteContext ? bookingPickupLat.value : null;
  double? get tripPickupLng =>
      hasBookingRouteContext ? bookingPickupLng.value : null;
  double? get tripDropoffLat =>
      hasBookingRouteContext ? bookingDropoffLat.value : null;
  double? get tripDropoffLng =>
      hasBookingRouteContext ? bookingDropoffLng.value : null;

  @override
  Future<void> onInit() async {
    super.onInit();

    final client = await ApiClient.create();
    _ridesApi = RidesApi(client);
    _bookingsApi = BookingsApi(client);
    _chatApi = ChatApi(client);

    // seats from previous screen
    final args = (Get.arguments as Map?) ?? const <String, dynamic>{};
    final rawSeats = args['seats'];
    final s = rawSeats is int
        ? rawSeats
        : int.tryParse('${rawSeats ?? 1}') ?? 1;
    selectedSeats.value = s <= 0 ? 1 : s;
    _applyBookingContextArgs(args);
    _openConfirmSheetOnLoad = args['openConfirmSheet'] == true;

    if (rideId.trim().isEmpty) {
      error.value = 'Missing ride id.';
      return;
    }

    await fetch();
  }

  void _applyBookingContextArgs(Map<dynamic, dynamic> args) {
    _bookingId = _nonEmpty(_asString(args['bookingId']));
    _bookingStatus = _nonEmpty(_asString(args['bookingStatus']));
    _bookingPaymentStatus = _nonEmpty(_asString(args['bookingPaymentStatus']));
    _bookingPassengerId = _nonEmpty(_asString(args['bookingPassengerId']));
    bookingPickupName.value = _nonEmpty(
      _asString(args['bookingPickupName'] ?? args['passengerPickupName']),
    );
    bookingPickupLat.value = _asNullableDouble(
      args['bookingPickupLat'] ?? args['passengerPickupLat'],
    );
    bookingPickupLng.value = _asNullableDouble(
      args['bookingPickupLng'] ?? args['passengerPickupLng'],
    );
    bookingDropoffName.value = _nonEmpty(
      _asString(args['bookingDropoffName'] ?? args['passengerDropoffName']),
    );
    bookingDropoffLat.value = _asNullableDouble(
      args['bookingDropoffLat'] ?? args['passengerDropoffLat'],
    );
    bookingDropoffLng.value = _asNullableDouble(
      args['bookingDropoffLng'] ?? args['passengerDropoffLng'],
    );
  }

  Future<void> fetch() async {
    loading.value = true;
    error.value = null;
    try {
      final data = await _ridesApi.getRideById(rideId);
      ride.value = data;

      // clamp seats if available smaller
      final max = data.seatsAvailable;
      if (selectedSeats.value > max) {
        selectedSeats.value = max <= 0 ? 1 : max;
      }

      if (_openConfirmSheetOnLoad &&
          !_didAutoOpenConfirmSheet &&
          data.seatsAvailable > 0 &&
          data.startTime.isAfter(DateTime.now())) {
        _didAutoOpenConfirmSheet = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!(Get.isBottomSheetOpen ?? false)) {
            openConfirmSheet();
          }
        });
      }
    } catch (e) {
      error.value = e.toString();
    } finally {
      loading.value = false;
    }
  }

  void setSeats(int s) {
    final r = ride.value;
    if (r == null) return;
    selectedSeats.value = s.clamp(
      1,
      r.seatsAvailable <= 0 ? 1 : r.seatsAvailable,
    );
  }

  double get totalPrice {
    final r = ride.value;
    if (r == null) return 0;
    return r.pricePerSeat * selectedSeats.value;
  }

  void openConfirmSheet() {
    final r = ride.value;
    if (r == null) return;

    // clamp seats before showing
    final max = r.seatsAvailable <= 0 ? 1 : r.seatsAvailable;
    final seats = selectedSeats.value.clamp(1, max);

    Get.bottomSheet(
      ConfirmBookingSheet(
        routeText: '${r.fromCity} → ${r.toCity}',
        dateText: _formatDateTime(r.startTime),
        seats: seats,
        total: r.pricePerSeat * seats,
        initialPickup: r.fromCity,
        initialDropoff: r.toCity,
        initialPickupLat: r.fromLat,
        initialPickupLng: r.fromLng,
        initialDropoffLat: r.toLat,
        initialDropoffLng: r.toLng,
        onCancel: () => Get.back(),
        onConfirm:
            ({
              required pickupName,
              required dropoffName,
              required pickupLat,
              required pickupLng,
              required dropoffLat,
              required dropoffLng,
            }) => confirmBooking(
              pickupName: pickupName,
              dropoffName: dropoffName,
              pickupLat: pickupLat,
              pickupLng: pickupLng,
              dropoffLat: dropoffLat,
              dropoffLng: dropoffLng,
            ),
      ),
      isScrollControlled: true,
      backgroundColor: const Color(0x00000000),
    );
  }

  Future<void> confirmBooking({
    required String pickupName,
    required String dropoffName,
    required double pickupLat,
    required double pickupLng,
    required double dropoffLat,
    required double dropoffLng,
  }) async {
    final r = ride.value;
    if (r == null) return;

    // clamp seats
    final max = r.seatsAvailable <= 0 ? 1 : r.seatsAvailable;
    final seats = selectedSeats.value.clamp(1, max);
    final pickup = pickupName.trim();
    final dropoff = dropoffName.trim();
    if (pickup.isEmpty || dropoff.isEmpty) {
      Get.snackbar('Missing details', 'Pickup and drop-off are required.');
      return;
    }

    loading.value = true;
    error.value = null;

    try {
      // ✅ API call
      final booking = await _bookingsApi.createBooking(
        rideId: r.id,
        seats: seats,
        passengerPickupName: pickup,
        passengerDropoffName: dropoff,
        passengerPickupLat: pickupLat,
        passengerPickupLng: pickupLng,
        passengerDropoffLat: dropoffLat,
        passengerDropoffLng: dropoffLng,
      );

      // close sheet (if open)
      if (Get.isBottomSheetOpen ?? false) Get.back();

      final bookingId = booking.id.trim();
      final bookingStatus = booking.status;
      final total = booking.totalPrice > 0
          ? booking.totalPrice
          : r.pricePerSeat * seats;

      Get.snackbar(
        'Requested',
        bookingId.isNotEmpty
            ? 'Booking $bookingStatus. ID: $bookingId'
            : 'Booking $bookingStatus.',
      );

      // optional: refresh ride to update seatsAvailable if backend reduces it
      await fetch();

      final status = booking.status;
      final routeText = '${booking.pickupLabel} → ${booking.dropoffLabel}';

      // ✅ Navigate to success screen using real booking data
      Get.toNamed(
        '/booking/success',
        arguments: {
          'route': routeText,
          'departure': _formatDateTime(r.startTime),
          'total': total,
          'ref': bookingId.isNotEmpty
              ? bookingId
              : 'RB-${DateTime.now().year}-${DateTime.now().millisecondsSinceEpoch % 1000000}',
          'status': status,
        },
      );
    } catch (e) {
      // keep sheet open and show error
      Get.snackbar('Booking failed', e.toString());
    } finally {
      loading.value = false;
    }
  }

  Future<void> openBookingChat() async {
    if (!canOpenBookingChat) return;

    final session = Get.isRegistered<SessionController>()
        ? Get.find<SessionController>()
        : null;
    final currentUserId = session?.user.value?.id ?? '';
    if (currentUserId.isEmpty) {
      Get.snackbar('Chat', 'Please sign in to chat.');
      return;
    }

    final passengerId = _nonEmpty(_bookingPassengerId) ?? currentUserId;
    final activeRideId = _nonEmpty(ride.value?.id) ?? rideId.trim();
    if (activeRideId.isEmpty) {
      Get.snackbar('Chat unavailable', 'Ride details are missing.');
      return;
    }

    try {
      final conversation = await _chatApi.createOrGetConversation(
        rideId: activeRideId,
        passengerId: passengerId,
        currentUserId: currentUserId,
        currentRole: session?.user.value?.roleDefault,
      );
      Get.to(() => ChatThreadView(conversation: conversation));
    } catch (e) {
      final message = e is ApiException
          ? e.message
          : 'Unable to open chat right now.';
      Get.snackbar('Chat unavailable', message);
    }
  }
}

String _asString(dynamic value) => value?.toString() ?? '';

String? _nonEmpty(String? value) {
  if (value == null) return null;
  final cleaned = value.trim();
  return cleaned.isEmpty ? null : cleaned;
}

double? _asNullableDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

bool _isConfirmedBookingStatus(String value) {
  final status = value.toLowerCase().trim();
  return status.contains('confirm') || status.contains('accept');
}

String _formatDateTime(DateTime dt) {
  final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
  final ampm = dt.hour >= 12 ? 'PM' : 'AM';
  final mm = dt.minute.toString().padLeft(2, '0');
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[(dt.month - 1).clamp(0, 11)]} ${dt.day}, $h:$mm $ampm';
}
