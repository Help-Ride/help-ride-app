import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../shared/services/api_client.dart';
import '../../../shared/widgets/place_picker_field.dart';
import '../models/ride_request.dart';
import '../services/ride_requests_api.dart';
import '../../bookings/controllers/my_rides_controller.dart';

class RideRequestFormController extends GetxController {
  late final RideRequestsApi _api;

  final loading = false.obs;
  final error = RxnString();

  final fromCtrl = TextEditingController();
  final toCtrl = TextEditingController();
  final seatsCtrl = TextEditingController(text: '1');

  final fromPick = Rxn<PlacePick>();
  final toPick = Rxn<PlacePick>();

  final date = Rxn<DateTime>();
  final time = Rxn<TimeOfDay>();
  final arrivalTime = Rxn<TimeOfDay>();
  final rideType = 'one-time'.obs;
  final tripType = 'one-way'.obs;

  final canSubmitFlag = false.obs;
  final _workers = <Worker>[];

  RideRequest? _editing;

  bool get isEditing => _editing != null;

  @override
  Future<void> onInit() async {
    super.onInit();
    final client = await ApiClient.create();
    _api = RideRequestsApi(client);

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
      time.value = _parseTime(request.preferredTime);
      arrivalTime.value =
          request.arrivalTime == null ? null : _parseTime(request.arrivalTime!);
      rideType.value = request.rideType;
      tripType.value = request.tripType;
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
      fromPick.value = PlacePick(fullText: fromCity, latLng: LatLng(fromLat, fromLng));
    }
    if (toCity.isNotEmpty && toLat != null && toLng != null) {
      toPick.value = PlacePick(fullText: toCity, latLng: LatLng(toLat, toLng));
    }
  }

  void _recomputeCanSubmit() {
    canSubmitFlag.value = _computeCanSubmit();
  }

  bool _computeCanSubmit() {
    final seats = int.tryParse(seatsCtrl.text.trim()) ?? 0;

    final hasRoute = isEditing
        ? fromCtrl.text.trim().isNotEmpty && toCtrl.text.trim().isNotEmpty
        : fromPick.value?.latLng != null && toPick.value?.latLng != null;

    return hasRoute && date.value != null && time.value != null && seats > 0;
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
    error.value = null;
    if (!_computeCanSubmit()) {
      error.value = 'Fill route, date/time, and seats needed.';
      return;
    }

    final seats = int.parse(seatsCtrl.text.trim());
    final preferredLocal = preferredDateTimeLocal!;
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
        final from = fromPick.value;
        final to = toPick.value;
        if (from?.latLng == null || to?.latLng == null) {
          error.value = 'Pick both locations using the map search.';
          loading.value = false;
          return;
        }
        await _api.createRideRequest(
          fromCity: from!.fullText,
          fromLat: from.latLng!.lat,
          fromLng: from.latLng!.lng,
          toCity: to!.fullText,
          toLat: to.latLng!.lat,
          toLng: to.latLng!.lng,
          preferredDateUtc: preferredLocal.toUtc(),
          preferredTime: preferredTime,
          arrivalTime: arrival,
          seatsNeeded: seats,
          rideType: rideType.value,
          tripType: tripType.value,
        );
        _afterSuccess('Requested', 'Ride request submitted.');
      }
    } catch (e) {
      error.value = e.toString();
      Get.snackbar('Failed', error.value ?? 'Failed');
    } finally {
      loading.value = false;
    }
  }

  void _afterSuccess(String title, String message) {
    if (Get.isRegistered<MyRidesController>()) {
      Get.find<MyRidesController>().fetch();
    }
    Get.back();
    Get.snackbar(title, message);
  }
}
