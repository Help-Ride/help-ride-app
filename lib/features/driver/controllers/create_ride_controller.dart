import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../shared/services/api_client.dart';
import '../../../shared/utils/input_validators.dart';
import '../../../shared/widgets/place_picker_field.dart';
import '../services/driver_rides_api.dart';
import '../utils/ride_payload_utils.dart';
import '../utils/ride_price_policy.dart';

class CreateRideController extends GetxController {
  late final DriverRidesApi _api;

  final loading = false.obs;
  final error = RxnString();

  final fromCtrl = TextEditingController();
  final toCtrl = TextEditingController();
  final stopsCtrl = TextEditingController();
  final seatsCtrl = TextEditingController();
  final priceCtrl = TextEditingController(text: '25');
  final notesCtrl = TextEditingController();

  final fromPick = Rxn<PlacePick>();
  final toPick = Rxn<PlacePick>();

  final date = Rxn<DateTime>();
  final time = Rxn<TimeOfDay>();
  final canPublishFlag = false.obs;
  final submitAttempted = false.obs;
  final pricingPreview = Rxn<RidePriceResolution>();
  final _workers = <Worker>[];

  final amenities = <String, bool>{
    'AC': false,
    'Music': false,
    'WiFi': false,
    'Pet-friendly': false,
    'Luggage space': false,
    'Child seat': false,
  }.obs;

  @override
  Future<void> onInit() async {
    super.onInit();
    final client = await ApiClient.create();
    _api = DriverRidesApi(client);

    final args = (Get.arguments as Map?) ?? {};
    final fromCity = (args['fromCity'] ?? '').toString().trim();
    final toCity = (args['toCity'] ?? '').toString().trim();
    final fromLat = _readDouble(args['fromLat']);
    final fromLng = _readDouble(args['fromLng']);
    final toLat = _readDouble(args['toLat']);
    final toLng = _readDouble(args['toLng']);
    if (fromCity.isNotEmpty) {
      fromCtrl.text = fromCity;
    }
    if (toCity.isNotEmpty) {
      toCtrl.text = toCity;
    }
    if (fromLat != null && fromLng != null) {
      fromPick.value = PlacePick(
        fullText: fromCity.isNotEmpty ? fromCity : 'Selected location',
        latLng: LatLng(fromLat, fromLng),
      );
    }
    if (toLat != null && toLng != null) {
      toPick.value = PlacePick(
        fullText: toCity.isNotEmpty ? toCity : 'Selected location',
        latLng: LatLng(toLat, toLng),
      );
    }

    fromCtrl.addListener(_refreshComputedState);
    toCtrl.addListener(_refreshComputedState);
    seatsCtrl.addListener(_refreshComputedState);
    priceCtrl.addListener(_refreshComputedState);
    _workers.addAll([
      ever(fromPick, (_) => _refreshComputedState()),
      ever(toPick, (_) => _refreshComputedState()),
      ever(date, (_) => _refreshComputedState()),
      ever(time, (_) => _refreshComputedState()),
    ]);
    _refreshComputedState();
  }

  @override
  void onClose() {
    fromCtrl.removeListener(_refreshComputedState);
    toCtrl.removeListener(_refreshComputedState);
    seatsCtrl.removeListener(_refreshComputedState);
    priceCtrl.removeListener(_refreshComputedState);
    for (final w in _workers) {
      w.dispose();
    }
    fromCtrl.dispose();
    toCtrl.dispose();
    stopsCtrl.dispose();
    seatsCtrl.dispose();
    priceCtrl.dispose();
    notesCtrl.dispose();
    super.onClose();
  }

  bool get canPublish {
    return canPublishFlag.value;
  }

  String? get fromError {
    if (!submitAttempted.value) return null;
    if (fromPick.value?.latLng != null) return null;
    return 'Select a departure location from search.';
  }

  String? get toError {
    if (!submitAttempted.value) return null;
    if (toPick.value?.latLng != null) return null;
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
      fieldLabel: 'Available seats',
      min: 1,
    );
    if (raw == null) return null;
    return submitAttempted.value || value.isNotEmpty ? raw : null;
  }

  String? get priceError {
    final value = priceCtrl.text.trim();
    final raw = InputValidators.nonNegativeDecimal(
      value,
      fieldLabel: 'Price per seat',
    );
    if (raw == null) return null;
    return submitAttempted.value || value.isNotEmpty ? raw : null;
  }

  bool _computeCanPublish() {
    return fromPick.value?.latLng != null &&
        toPick.value?.latLng != null &&
        date.value != null &&
        time.value != null &&
        InputValidators.positiveInt(
              seatsCtrl.text,
              fieldLabel: 'Available seats',
              min: 1,
            ) ==
            null &&
        InputValidators.nonNegativeDecimal(
              priceCtrl.text,
              fieldLabel: 'Price per seat',
            ) ==
            null;
  }

  void _recomputeCanPublish() {
    canPublishFlag.value = _computeCanPublish();
  }

  void _refreshComputedState() {
    _recomputeCanPublish();
    pricingPreview.value = _buildPricingPreview();
    if (submitAttempted.value && canPublish) {
      error.value = null;
    }
  }

  RidePriceResolution? _buildPricingPreview() {
    final from = fromPick.value?.latLng;
    final to = toPick.value?.latLng;
    final departure = startDateTimeLocal;
    final seats = int.tryParse(seatsCtrl.text.trim());
    final basePrice = double.tryParse(priceCtrl.text.trim());

    if (from == null ||
        to == null ||
        departure == null ||
        seats == null ||
        seats <= 0 ||
        basePrice == null ||
        basePrice < 0) {
      return null;
    }

    final distanceKm = RidePricePolicy.distanceKm(
      fromLat: from.lat,
      fromLng: from.lng,
      toLat: to.lat,
      toLng: to.lng,
    );

    return RidePricePolicy.resolvePerSeatPrice(
      basePricePerSeat: basePrice,
      seats: seats,
      distanceKm: distanceKm,
      bookingTimeLocal: DateTime.now(),
      departureTimeLocal: departure,
      sameDestination: RidePricePolicy.isSameDestination(
        from: fromCtrl.text,
        to: toCtrl.text,
      ),
    );
  }

  DateTime? get startDateTimeLocal {
    final d = date.value;
    final t = time.value;
    if (d == null || t == null) return null;
    return DateTime(d.year, d.month, d.day, t.hour, t.minute);
  }

  void toggleAmenity(String k) {
    final v = amenities[k] ?? false;
    amenities[k] = !v;
    amenities.refresh();
  }

  double? _readDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  Future<void> publish() async {
    submitAttempted.value = true;
    error.value = null;

    if (!_computeCanPublish()) {
      error.value = 'Please fix highlighted fields.';
      return;
    }

    final startLocal = startDateTimeLocal!;
    final seats = int.parse(seatsCtrl.text.trim());
    final basePrice = double.parse(priceCtrl.text.trim());

    final from = fromPick.value!;
    final to = toPick.value!;
    final fromLL = from.latLng!;
    final toLL = to.latLng!;
    final pricing =
        _buildPricingPreview() ??
        RidePricePolicy.resolvePerSeatPrice(
          basePricePerSeat: basePrice,
          seats: seats,
          distanceKm: RidePricePolicy.distanceKm(
            fromLat: fromLL.lat,
            fromLng: fromLL.lng,
            toLat: toLL.lat,
            toLng: toLL.lng,
          ),
          bookingTimeLocal: DateTime.now(),
          departureTimeLocal: startLocal,
          sameDestination: RidePricePolicy.isSameDestination(
            from: from.fullText,
            to: to.fullText,
          ),
        );
    final finalPrice = pricing.finalPricePerSeat;
    if (pricing.adjusted) {
      priceCtrl.text = _formatPrice(finalPrice);
    }
    final stops = parseRideStopsCsv(stopsCtrl.text);
    final selectedAmenities = selectedRideAmenitiesForApi(amenities);
    final additionalNotes = normalizeRideAdditionalNotes(notesCtrl.text);

    loading.value = true;
    try {
      await _api.createRide(
        fromCity: from.fullText,
        fromLat: fromLL.lat,
        fromLng: fromLL.lng,
        toCity: to.fullText,
        toLat: toLL.lat,
        toLng: toLL.lng,
        startTimeUtc: startLocal.toUtc(),
        seatsTotal: seats,
        pricePerSeat: finalPrice,
        stops: stops,
        amenities: selectedAmenities,
        additionalNotes: additionalNotes,
      );

      Get.back();
      Get.snackbar(
        'Published',
        pricing.adjusted
            ? 'Ride created. Price adjusted to \$${_formatPrice(finalPrice)}/seat by safety caps.'
            : 'Ride created successfully',
      );
    } catch (e) {
      error.value = e.toString();
      Get.snackbar('Failed', error.value ?? 'Failed');
    } finally {
      loading.value = false;
    }
  }
}

String _formatPrice(double value) {
  final fixed = value.toStringAsFixed(2);
  if (fixed.endsWith('.00')) return value.toStringAsFixed(0);
  if (fixed.endsWith('0')) return fixed.substring(0, fixed.length - 1);
  return fixed;
}
