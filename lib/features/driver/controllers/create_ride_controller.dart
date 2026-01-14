import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../shared/services/api_client.dart';
import '../../../shared/widgets/place_picker_field.dart';
import '../services/driver_rides_api.dart';

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

  bool get canPublish {
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

  void toggleAmenity(String k) {
    final v = amenities[k] ?? false;
    amenities[k] = !v;
    amenities.refresh();
  }

  Future<void> publish() async {
    error.value = null;

    if (!canPublish) {
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
      await _api.createRide(
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
      Get.snackbar('Published', 'Ride created successfully');
    } catch (e) {
      error.value = e.toString();
      Get.snackbar('Failed', error.value ?? 'Failed');
    } finally {
      loading.value = false;
    }
  }
}
