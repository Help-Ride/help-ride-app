import 'dart:ui';

import 'package:get/get.dart';
import 'package:help_ride/features/rides/models/ride.dart';
import 'package:help_ride/features/rides/services/rides_api.dart';
import 'package:help_ride/features/rides/widgets/confirm_booking_sheet.dart';
import 'package:help_ride/shared/services/api_client.dart';

// ✅ add this import (create file below if not exists)
import 'package:help_ride/features/bookings/services/bookings_api.dart';

class RideDetailsController extends GetxController {
  late final RidesApi _ridesApi;
  late final BookingsApi _bookingsApi;

  final loading = false.obs;
  final error = RxnString();
  final ride = Rxn<Ride>();

  final selectedSeats = 1.obs;

  String get rideId => Get.parameters['id'] ?? '';

  @override
  Future<void> onInit() async {
    super.onInit();

    final client = await ApiClient.create();
    _ridesApi = RidesApi(client);
    _bookingsApi = BookingsApi(client);

    // seats from previous screen
    final args = (Get.arguments as Map?) ?? {};
    final rawSeats = args['seats'];
    final s = rawSeats is int
        ? rawSeats
        : int.tryParse('${rawSeats ?? 1}') ?? 1;
    selectedSeats.value = s <= 0 ? 1 : s;

    if (rideId.trim().isEmpty) {
      error.value = 'Missing ride id.';
      return;
    }

    await fetch();
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
        onCancel: () => Get.back(),
        onConfirm: confirmBooking, // ✅ now uses API
      ),
      isScrollControlled: true,
      backgroundColor: const Color(0x00000000),
    );
  }

  Future<void> confirmBooking() async {
    final r = ride.value;
    if (r == null) return;

    // clamp seats
    final max = r.seatsAvailable <= 0 ? 1 : r.seatsAvailable;
    final seats = selectedSeats.value.clamp(1, max);

    loading.value = true;
    error.value = null;

    try {
      // ✅ API call
      final booking = await _bookingsApi.createBooking(
        rideId: r.id,
        seats: seats,
      );

      // close sheet (if open)
      if (Get.isBottomSheetOpen ?? false) Get.back();

      final bookingId = (booking['id'] ?? '').toString();
      final bookingStatus = (booking['status'] ?? 'pending').toString();
      final total = r.pricePerSeat * seats;

      Get.snackbar(
        'Requested',
        bookingId.isNotEmpty
            ? 'Booking $bookingStatus. ID: $bookingId'
            : 'Booking $bookingStatus.',
      );

      // optional: refresh ride to update seatsAvailable if backend reduces it
      await fetch();

      // ✅ Navigate to success screen using real booking data
      Get.toNamed(
        '/booking/success',
        arguments: {
          'route': '${r.fromCity} → ${r.toCity}',
          'departure': _formatDateTime(r.startTime),
          'total': total,
          'ref': bookingId.isNotEmpty
              ? bookingId
              : 'RB-${DateTime.now().year}-${DateTime.now().millisecondsSinceEpoch % 1000000}',
        },
      );
    } catch (e) {
      // keep sheet open and show error
      Get.snackbar('Booking failed', e.toString());
    } finally {
      loading.value = false;
    }
  }
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
