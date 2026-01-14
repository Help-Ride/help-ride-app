import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:help_ride/features/rides/models/ride.dart';
import 'package:help_ride/features/rides/services/rides_api.dart';
import '../../../shared/services/api_client.dart';
import '../../../shared/widgets/place_picker_field.dart';
import '../services/driver_rides_api.dart';

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
  }

  @override
  void onClose() {
    fromCtrl.dispose();
    toCtrl.dispose();
    stopsCtrl.dispose();
    seatsCtrl.dispose();
    priceCtrl.dispose();
    notesCtrl.dispose();
    super.onClose();
  }

  bool get canSave {
    final seats = int.tryParse(seatsCtrl.text.trim()) ?? 0;
    final price = double.tryParse(priceCtrl.text.trim()) ?? -1;

    return fromPick.value?.latLng != null &&
        toPick.value?.latLng != null &&
        date.value != null &&
        time.value != null &&
        seats > 0 &&
        price >= 0;
  }

  DateTime? get startDateTimeLocal {
    final d = date.value;
    final t = time.value;
    if (d == null || t == null) return null;
    return DateTime(d.year, d.month, d.day, t.hour, t.minute);
  }

  Future<void> _loadRide() async {
    loading.value = true;
    error.value = null;
    try {
      final data = await _ridesApi.getRideById(rideId);
      ride.value = data;
      _fillFields(data);
    } catch (e) {
      error.value = e.toString();
    } finally {
      loading.value = false;
    }
  }

  Future<void> refresh() => _loadRide();

  void _fillFields(Ride r) {
    fromCtrl.text = r.fromCity;
    toCtrl.text = r.toCity;
    seatsCtrl.text = r.seatsTotal.toString();
    priceCtrl.text = r.pricePerSeat.toString();

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
  }

  void toggleAmenity(String k) {
    final v = amenities[k] ?? false;
    amenities[k] = !v;
    amenities.refresh();
  }

  Future<void> save() async {
    error.value = null;

    if (!canSave) {
      error.value = 'Fill route, date/time, seats and price.';
      return;
    }

    final startLocal = startDateTimeLocal!;
    final seats = int.parse(seatsCtrl.text.trim());
    final price = double.parse(priceCtrl.text.trim());

    final from = fromPick.value!;
    final to = toPick.value!;
    final fromLL = from.latLng!;
    final toLL = to.latLng!;

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
        pricePerSeat: price,
      );

      Get.back();
      Get.snackbar('Updated', 'Ride updated successfully');
    } catch (e) {
      error.value = e.toString();
      Get.snackbar('Failed', error.value ?? 'Failed');
    } finally {
      loading.value = false;
    }
  }
}
