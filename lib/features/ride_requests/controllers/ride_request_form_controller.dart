import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:get/get.dart';
import 'dart:math' as math;
import '../../../shared/services/api_client.dart';
import '../../../shared/utils/input_validators.dart';
import '../../../shared/widgets/place_picker_field.dart';
import '../models/ride_request.dart';
import '../services/ride_requests_api.dart';
import '../../bookings/controllers/my_rides_controller.dart';
import '../../bookings/services/bookings_api.dart';

class RideRequestFormController extends GetxController {
  static const double _minRouteDistanceKm = 0.1;

  late final RideRequestsApi _api;
  late final BookingsApi _bookingsApi;

  final loading = false.obs;
  final error = RxnString();

  final fromCtrl = TextEditingController();
  final toCtrl = TextEditingController();
  final seatsCtrl = TextEditingController(text: '1');

  final fromPick = Rxn<PlacePick>();
  final toPick = Rxn<PlacePick>();
  final pickupLocation = Rxn<RideRequestLocationDraft>();
  final dropoffLocation = Rxn<RideRequestLocationDraft>();

  final date = Rxn<DateTime>();
  final time = Rxn<TimeOfDay>();
  final arrivalTime = Rxn<TimeOfDay>();
  final rideType = 'one-time'.obs;
  final tripType = 'one-way'.obs;

  final canSubmitFlag = false.obs;
  final submitAttempted = false.obs;
  final _workers = <Worker>[];

  RideRequest? _editing;

  bool get isEditing => _editing != null;

  @override
  Future<void> onInit() async {
    super.onInit();
    final client = await ApiClient.create();
    _api = RideRequestsApi(client);
    _bookingsApi = BookingsApi(client);

    _hydrateFromArgs();

    fromCtrl.addListener(_recomputeCanSubmit);
    toCtrl.addListener(_recomputeCanSubmit);
    seatsCtrl.addListener(_recomputeCanSubmit);

    _workers.addAll([
      ever(fromPick, (_) => _recomputeCanSubmit()),
      ever(toPick, (_) => _recomputeCanSubmit()),
      ever(date, (_) => _recomputeCanSubmit()),
      ever(time, (_) => _recomputeCanSubmit()),
    ]);

    _recomputeCanSubmit();
  }

  @override
  void onClose() {
    fromCtrl.removeListener(_recomputeCanSubmit);
    toCtrl.removeListener(_recomputeCanSubmit);
    seatsCtrl.removeListener(_recomputeCanSubmit);
    for (final w in _workers) {
      w.dispose();
    }
    fromCtrl.dispose();
    toCtrl.dispose();
    seatsCtrl.dispose();
    super.onClose();
  }

  void _hydrateFromArgs() {
    final args = (Get.arguments as Map?) ?? {};
    final request = args['request'];
    if (request is RideRequest) {
      _editing = request;
      fromCtrl.text = request.fromCity;
      toCtrl.text = request.toCity;
      seatsCtrl.text = request.seatsNeeded.toString();
      date.value = request.preferredDate;
      time.value = _parseTime(request.preferredTime ?? '');
      arrivalTime.value = request.arrivalTime == null
          ? null
          : _parseTime(request.arrivalTime!);
      rideType.value = request.rideType;
      tripType.value = request.tripType;
      final fromLat = request.fromLat;
      final fromLng = request.fromLng;
      final toLat = request.toLat;
      final toLng = request.toLng;
      if (fromLat != null && fromLng != null) {
        pickupLocation.value = RideRequestLocationDraft(
          name: request.fromCity,
          lat: fromLat,
          lng: fromLng,
        );
      }
      if (toLat != null && toLng != null) {
        dropoffLocation.value = RideRequestLocationDraft(
          name: request.toCity,
          lat: toLat,
          lng: toLng,
        );
      }
      return;
    }

    final fromCity = (args['fromCity'] ?? '').toString();
    final toCity = (args['toCity'] ?? '').toString();
    fromCtrl.text = fromCity;
    toCtrl.text = toCity;

    final seats = args['seats'];
    final parsedSeats = seats is int
        ? seats
        : int.tryParse((seats ?? '1').toString()) ?? 1;
    seatsCtrl.text = parsedSeats.toString();

    final fromLat = _readDouble(args['fromLat']);
    final fromLng = _readDouble(args['fromLng']);
    final toLat = _readDouble(args['toLat']);
    final toLng = _readDouble(args['toLng']);
    if (fromCity.isNotEmpty && fromLat != null && fromLng != null) {
      setPickupPlace(
        PlacePick(fullText: fromCity, latLng: LatLng(fromLat, fromLng)),
      );
    }
    if (toCity.isNotEmpty && toLat != null && toLng != null) {
      setDropoffPlace(
        PlacePick(fullText: toCity, latLng: LatLng(toLat, toLng)),
      );
    }
  }

  void setPickupPlace(PlacePick place) {
    fromPick.value = place;
    pickupLocation.value = RideRequestLocationDraft.fromPlacePick(place);
    fromCtrl.text = place.fullText;
    _recomputeCanSubmit();
  }

  void setDropoffPlace(PlacePick place) {
    toPick.value = place;
    dropoffLocation.value = RideRequestLocationDraft.fromPlacePick(place);
    toCtrl.text = place.fullText;
    _recomputeCanSubmit();
  }

  void _recomputeCanSubmit() {
    canSubmitFlag.value = _computeCanSubmit();
    if (submitAttempted.value && canSubmitFlag.value) {
      error.value = null;
    }
  }

  bool _computeCanSubmit() {
    final seatsErrorRaw = InputValidators.positiveInt(
      seatsCtrl.text,
      fieldLabel: 'Seats needed',
      min: 1,
    );

    final hasRoute = isEditing
        ? fromCtrl.text.trim().isNotEmpty && toCtrl.text.trim().isNotEmpty
        : pickupLocation.value != null && dropoffLocation.value != null;

    return hasRoute &&
        date.value != null &&
        time.value != null &&
        seatsErrorRaw == null;
  }

  String? get pickupError {
    if (isEditing || !submitAttempted.value) return null;
    if (pickupLocation.value != null) return null;
    return 'Select a pickup location from search.';
  }

  String? get dropoffError {
    if (isEditing || !submitAttempted.value) return null;
    if (dropoffLocation.value != null) return null;
    return 'Select a destination from search.';
  }

  String? get dateError {
    if (!submitAttempted.value || date.value != null) return null;
    return 'Date is required.';
  }

  String? get timeError {
    if (!submitAttempted.value || time.value != null) return null;
    return 'Time is required.';
  }

  String? get seatsError {
    final value = seatsCtrl.text.trim();
    final raw = InputValidators.positiveInt(
      value,
      fieldLabel: 'Seats needed',
      min: 1,
    );
    if (raw == null) return null;
    return submitAttempted.value || value.isNotEmpty ? raw : null;
  }

  DateTime? get preferredDateTimeLocal {
    final d = date.value;
    final t = time.value;
    if (d == null || t == null) return null;
    return DateTime(d.year, d.month, d.day, t.hour, t.minute);
  }

  String? _formatTime(TimeOfDay? t) {
    if (t == null) return null;
    final hh = t.hour.toString().padLeft(2, '0');
    final mm = t.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  TimeOfDay? _parseTime(String raw) {
    if (raw.trim().isEmpty) return null;
    final parts = raw.split(':');
    if (parts.length < 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return TimeOfDay(hour: h, minute: m);
  }

  double? _readDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  Future<void> submit() async {
    submitAttempted.value = true;
    error.value = null;
    if (!_computeCanSubmit()) {
      error.value = 'Please fix highlighted fields.';
      return;
    }

    final seats = int.parse(seatsCtrl.text.trim());
    final preferredLocal = preferredDateTimeLocal!;
    if (preferredLocal.isBefore(DateTime.now())) {
      error.value = 'Preferred date/time must be in the future.';
      return;
    }
    final preferredTime = _formatTime(time.value)!;
    final arrival = _formatTime(arrivalTime.value);

    loading.value = true;
    try {
      if (isEditing) {
        final id = _editing!.id;
        await _api.updateRideRequest(
          id,
          preferredDateUtc: preferredLocal.toUtc(),
          preferredTime: preferredTime,
          arrivalTime: arrival,
          seatsNeeded: seats,
        );
        _afterSuccess('Updated', 'Ride request updated.');
      } else {
        final pickup = pickupLocation.value;
        final dropoff = dropoffLocation.value;
        if (pickup == null || dropoff == null) {
          error.value = 'Pick both locations using the map search.';
          loading.value = false;
          return;
        }
        final routeDistanceKm = _distanceKmBetween(pickup, dropoff);
        if (routeDistanceKm < _minRouteDistanceKm) {
          error.value =
              'Pickup and drop-off are too close. Please choose different locations.';
          Get.snackbar('Failed', error.value!);
          loading.value = false;
          return;
        }
        final preferredUtc = preferredLocal.toUtc();
        final nowUtc = DateTime.now().toUtc();
        final leadMinutes = preferredUtc.difference(nowUtc).inMinutes;
        final useJitFlow = leadMinutes <= 120;
        if (useJitFlow) {
          await _submitJitRequest(
            pickup: pickup,
            dropoff: dropoff,
            preferredLocal: preferredLocal,
            preferredTime: preferredTime,
            arrival: arrival,
            seats: seats,
          );
        } else {
          await _submitOfferRequest(
            pickup: pickup,
            dropoff: dropoff,
            preferredLocal: preferredLocal,
            preferredTime: preferredTime,
            arrival: arrival,
            seats: seats,
          );
        }
      }
    } on StripeException catch (e) {
      final code = e.error.code.toString().toLowerCase();
      if (code.contains('cancel')) {
        error.value = 'Payment cancelled.';
      } else {
        error.value = e.error.message ?? 'Payment failed.';
      }
      Get.snackbar('Failed', error.value ?? 'Failed');
    } catch (e) {
      error.value = e.toString();
      Get.snackbar('Failed', error.value ?? 'Failed');
    } finally {
      loading.value = false;
    }
  }

  Future<void> _submitOfferRequest({
    required RideRequestLocationDraft pickup,
    required RideRequestLocationDraft dropoff,
    required DateTime preferredLocal,
    required String preferredTime,
    required String? arrival,
    required int seats,
  }) async {
    try {
      await _api.createRideRequest(
        fromCity: pickup.name,
        fromLat: pickup.lat,
        fromLng: pickup.lng,
        toCity: dropoff.name,
        toLat: dropoff.lat,
        toLng: dropoff.lng,
        preferredDateUtc: preferredLocal.toUtc(),
        preferredTime: preferredTime,
        arrivalTime: arrival,
        seatsNeeded: seats,
        rideType: rideType.value,
        tripType: tripType.value,
        mode: RideRequestMode.offer,
      );
      _afterSuccess('Requested', 'Ride request submitted.');
    } on RideRequestJitRequiredException {
      await _submitJitRequest(
        pickup: pickup,
        dropoff: dropoff,
        preferredLocal: preferredLocal,
        preferredTime: preferredTime,
        arrival: arrival,
        seats: seats,
      );
    }
  }

  Future<void> _submitJitRequest({
    required RideRequestLocationDraft pickup,
    required RideRequestLocationDraft dropoff,
    required DateTime preferredLocal,
    required String preferredTime,
    required String? arrival,
    required int seats,
  }) async {
    final intent = await _api.createJitIntent(
      fromCity: pickup.name,
      fromLat: pickup.lat,
      fromLng: pickup.lng,
      toCity: dropoff.name,
      toLat: dropoff.lat,
      toLng: dropoff.lng,
      preferredDateUtc: preferredLocal.toUtc(),
      preferredTime: preferredTime,
      arrivalTime: arrival,
      seatsNeeded: seats,
      rideType: rideType.value,
      tripType: tripType.value,
    );

    await Stripe.instance.initPaymentSheet(
      paymentSheetParameters: SetupPaymentSheetParameters(
        paymentIntentClientSecret: intent.clientSecret,
        merchantDisplayName: 'HelpRide',
        applePay: const PaymentSheetApplePay(merchantCountryCode: 'CA'),
        style: ThemeMode.system,
      ),
    );
    await Stripe.instance.presentPaymentSheet();
    // JIT request is created by backend webhook/callback after successful payment.
    // Mobile app should not call POST /ride-requests for JIT flow.
    await _showFindingDriverAndRefresh();
    _afterSuccess('Payment complete', 'Finding driver now...');
  }

  Future<void> _showFindingDriverAndRefresh() async {
    if (!(Get.isDialogOpen ?? false)) {
      Get.dialog<void>(const _FindingDriverDialog(), barrierDismissible: false);
    }
    try {
      for (var attempt = 0; attempt < 4; attempt++) {
        await Future.wait([_api.myRideRequests(), _bookingsApi.myBookings()]);
        if (Get.isRegistered<MyRidesController>()) {
          await Get.find<MyRidesController>().fetch();
        }
        if (attempt < 3) {
          await Future.delayed(const Duration(seconds: 2));
        }
      }
    } finally {
      if (Get.isDialogOpen ?? false) {
        Get.back<void>();
      }
    }
  }

  double _distanceKmBetween(
    RideRequestLocationDraft from,
    RideRequestLocationDraft to,
  ) {
    const earthRadiusKm = 6371.0;
    final dLat = _degToRad(to.lat - from.lat);
    final dLng = _degToRad(to.lng - from.lng);
    final a =
        math.pow(math.sin(dLat / 2), 2) +
        math.cos(_degToRad(from.lat)) *
            math.cos(_degToRad(to.lat)) *
            math.pow(math.sin(dLng / 2), 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  double _degToRad(double deg) => deg * (math.pi / 180.0);

  void _afterSuccess(String title, String message) {
    if (Get.isRegistered<MyRidesController>()) {
      Get.find<MyRidesController>().fetch();
    }
    Get.back();
    Get.snackbar(title, message);
  }
}

class RideRequestLocationDraft {
  const RideRequestLocationDraft({
    required this.name,
    required this.lat,
    required this.lng,
  });

  final String name;
  final double lat;
  final double lng;

  factory RideRequestLocationDraft.fromPlacePick(PlacePick place) {
    final latLng = place.latLng;
    if (latLng == null) {
      throw ArgumentError('Missing coordinates for selected place');
    }
    return RideRequestLocationDraft(
      name: place.fullText.trim(),
      lat: latLng.lat,
      lng: latLng.lng,
    );
  }
}

class _FindingDriverDialog extends StatelessWidget {
  const _FindingDriverDialog();

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: AlertDialog(
        content: Row(
          children: const [
            SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Payment successful. Finding driver...',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
