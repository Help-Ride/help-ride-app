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
  final canPublishFlag = false.obs;
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

    fromCtrl.addListener(_recomputeCanPublish);
    toCtrl.addListener(_recomputeCanPublish);
    seatsCtrl.addListener(_recomputeCanPublish);
    priceCtrl.addListener(_recomputeCanPublish);
    _workers.addAll([
      ever(fromPick, (_) => _recomputeCanPublish()),
      ever(toPick, (_) => _recomputeCanPublish()),
      ever(date, (_) => _recomputeCanPublish()),
      ever(time, (_) => _recomputeCanPublish()),
    ]);
    _recomputeCanPublish();
  }

  @override
  void onClose() {
    fromCtrl.removeListener(_recomputeCanPublish);
    toCtrl.removeListener(_recomputeCanPublish);
    seatsCtrl.removeListener(_recomputeCanPublish);
    priceCtrl.removeListener(_recomputeCanPublish);
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

  bool _computeCanPublish() {
    final seats = int.tryParse(seatsCtrl.text.trim()) ?? 0;
    final price = double.tryParse(priceCtrl.text.trim()) ?? -1;

    return fromPick.value?.latLng != null &&
        toPick.value?.latLng != null &&
        date.value != null &&
        time.value != null &&
        seats > 0 &&
        price >= 0;
  }

  void _recomputeCanPublish() {
    canPublishFlag.value = _computeCanPublish();
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
    error.value = null;

    if (!_computeCanPublish()) {
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
