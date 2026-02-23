import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:help_ride/features/rides/models/ride.dart';
import 'package:help_ride/features/rides/services/rides_api.dart';
import '../../../shared/services/api_client.dart';
import '../../../shared/utils/input_validators.dart';
import '../../../shared/widgets/place_picker_field.dart';
import '../services/driver_rides_api.dart';
import '../utils/ride_payload_utils.dart';
import '../utils/ride_price_policy.dart';

class EditRideController extends GetxController {
  late final DriverRidesApi _driverApi;
  late final RidesApi _ridesApi;

  final loading = false.obs;
  final error = RxnString();
  final ride = Rxn<Ride>();

  final fromCtrl = TextEditingController();
  final toCtrl = TextEditingController();
  final stopsCtrl = TextEditingController();
  final seatsCtrl = TextEditingController();
  final priceCtrl = TextEditingController();
  final notesCtrl = TextEditingController();

  final fromPick = Rxn<PlacePick>();
  final toPick = Rxn<PlacePick>();

  final date = Rxn<DateTime>();
  final time = Rxn<TimeOfDay>();
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

  String get rideId => Get.parameters['id'] ?? '';

  @override
  Future<void> onInit() async {
    super.onInit();
    final client = await ApiClient.create();
    _driverApi = DriverRidesApi(client);
    _ridesApi = RidesApi(client);

    if (rideId.trim().isEmpty) {
      error.value = 'Missing ride id.';
      return;
    }

    await _loadRide();
    _bindInputListeners();
    _refreshPricingPreview();
  }

  @override
  void onClose() {
    fromCtrl.removeListener(_refreshPricingPreview);
    toCtrl.removeListener(_refreshPricingPreview);
    seatsCtrl.removeListener(_refreshPricingPreview);
    priceCtrl.removeListener(_refreshPricingPreview);
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

  bool get canSave {
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

  DateTime? get startDateTimeLocal {
    final d = date.value;
    final t = time.value;
    if (d == null || t == null) return null;
    return DateTime(d.year, d.month, d.day, t.hour, t.minute);
  }

  void _bindInputListeners() {
    fromCtrl.addListener(_refreshPricingPreview);
    toCtrl.addListener(_refreshPricingPreview);
    seatsCtrl.addListener(_refreshPricingPreview);
    priceCtrl.addListener(_refreshPricingPreview);
    _workers.addAll([
      ever(fromPick, (_) => _refreshPricingPreview()),
      ever(toPick, (_) => _refreshPricingPreview()),
      ever(date, (_) => _refreshPricingPreview()),
      ever(time, (_) => _refreshPricingPreview()),
    ]);
  }

  void _refreshPricingPreview() {
    pricingPreview.value = _buildPricingPreview();
    if (submitAttempted.value && canSave) {
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

  Future<void> _loadRide() async {
    loading.value = true;
    error.value = null;
    try {
      final data = await _ridesApi.getRideById(rideId);
      ride.value = data;
      _fillFields(data);
      _refreshPricingPreview();
    } catch (e) {
      error.value = e.toString();
    } finally {
      loading.value = false;
    }
  }

  @override
  Future<void> refresh() => _loadRide();

  void _fillFields(Ride r) {
    fromCtrl.text = r.fromCity;
    toCtrl.text = r.toCity;
    seatsCtrl.text = r.seatsTotal.toString();
    priceCtrl.text = r.pricePerSeat.toString();
    stopsCtrl.text = r.stops.join(', ');
    notesCtrl.text = r.notes ?? '';

    fromPick.value = PlacePick(
      fullText: r.fromCity,
      latLng: LatLng(r.fromLat, r.fromLng),
    );
    toPick.value = PlacePick(
      fullText: r.toCity,
      latLng: LatLng(r.toLat, r.toLng),
    );

    final local = r.startTime.toLocal();
    date.value = DateTime(local.year, local.month, local.day);
    time.value = TimeOfDay(hour: local.hour, minute: local.minute);

    applyRideAmenitiesFromApi(amenities, r.amenities);
    amenities.refresh();
  }

  void toggleAmenity(String k) {
    final v = amenities[k] ?? false;
    amenities[k] = !v;
    amenities.refresh();
  }

  Future<void> save() async {
    submitAttempted.value = true;
    error.value = null;

    if (!canSave) {
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
      await _driverApi.updateRide(
        rideId: rideId,
        fromCity: from.fullText,
        fromLat: fromLL.lat,
        fromLng: fromLL.lng,
        toCity: to.fullText,
        toLat: toLL.lat,
        toLng: toLL.lng,
        startTimeUtc: startLocal.toUtc(),
        seatsTotal: seats,
        pricePerSeat: finalPrice,
        arrivalTimeUtc: ride.value?.arrivalTime?.toUtc(),
        stops: stops,
        amenities: selectedAmenities,
        additionalNotes: additionalNotes,
      );

      Get.back();
      Get.snackbar(
        'Updated',
        pricing.adjusted
            ? 'Ride updated. Price adjusted to \$${_formatPrice(finalPrice)}/seat by safety caps.'
            : 'Ride updated successfully',
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
