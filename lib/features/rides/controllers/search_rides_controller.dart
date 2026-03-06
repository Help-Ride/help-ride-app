import 'package:get/get.dart';
import '../../../shared/services/api_client.dart';
import '../models/ride.dart';
import '../services/rides_api.dart';

class SearchRidesController extends GetxController {
  late final RidesApi _api;

  final rides = <Ride>[].obs;
  final loading = false.obs;
  final error = RxnString();

  // inputs (passed in)
  final fromCity = ''.obs;
  final toCity = ''.obs;
  final seatsRequired = 1.obs;
  final fromLat = RxnDouble();
  final fromLng = RxnDouble();
  final toLat = RxnDouble();
  final toLng = RxnDouble();
  final radiusKm = RxnDouble();
  final focusRideId = RxnString();

  // per-ride seat selection
  final selectedSeats = <String, int>{}.obs;

  @override
  Future<void> onInit() async {
    super.onInit();

    final client = await ApiClient.create();
    _api = RidesApi(client);

    final args = (Get.arguments as Map?) ?? {};

    fromCity.value = (args['fromCity'] ?? '').toString().trim();
    toCity.value = (args['toCity'] ?? '').toString().trim();
    fromLat.value = _readDouble(args['fromLat']);
    fromLng.value = _readDouble(args['fromLng']);
    toLat.value = _readDouble(args['toLat']);
    toLng.value = _readDouble(args['toLng']);
    radiusKm.value = _readDouble(args['radiusKm']);
    final focusId = (args['focusRideId'] ?? args['rideId'] ?? '')
        .toString()
        .trim();
    focusRideId.value = focusId.isEmpty ? null : focusId;

    final rawSeats = args['seats'];
    final parsedSeats = rawSeats is int
        ? rawSeats
        : int.tryParse((rawSeats ?? '1').toString()) ?? 1;

    seatsRequired.value = parsedSeats <= 0 ? 1 : parsedSeats;

    final missingCoords =
        fromLat.value == null ||
        fromLng.value == null ||
        toLat.value == null ||
        toLng.value == null;
    if (missingCoords) {
      if (focusRideId.value == null || focusRideId.value!.isEmpty) {
        error.value =
            'Missing location coordinates. Select places from suggestions.';
        return;
      }
    }

    await fetch();
  }

  int getSelectedSeats(String rideId, int maxSeats) {
    final v = selectedSeats[rideId] ?? 1;
    return v.clamp(1, maxSeats);
  }

  void setSelectedSeats(String rideId, int seats) {
    selectedSeats[rideId] = seats;
    selectedSeats.refresh(); // ✅ ensure UI updates
  }

  Future<void> fetch() async {
    loading.value = true;
    error.value = null;

    try {
      final fromLatValue = fromLat.value;
      final fromLngValue = fromLng.value;
      final toLatValue = toLat.value;
      final toLngValue = toLng.value;
      if (fromLatValue == null ||
          fromLngValue == null ||
          toLatValue == null ||
          toLngValue == null) {
        await _loadFocusedRideOnly();
        return;
      }

      final list = await _api.searchRides(
        seats: seatsRequired.value,
        fromLat: fromLatValue,
        fromLng: fromLngValue,
        toLat: toLatValue,
        toLng: toLngValue,
        radiusKm: radiusKm.value,
      );

      final prioritized = await _prioritizeFocusedRide(list);
      rides.assignAll(prioritized);

      // init default selection if missing
      for (final r in prioritized) {
        selectedSeats.putIfAbsent(r.id, () => 1);
      }
      selectedSeats.refresh();
    } catch (e) {
      error.value = e.toString();
    } finally {
      loading.value = false;
    }
  }

  double? _readDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  Future<void> _loadFocusedRideOnly() async {
    final rideId = focusRideId.value?.trim() ?? '';
    if (rideId.isEmpty) {
      throw Exception('Missing location coordinates.');
    }
    final ride = await _api.getRideById(rideId);
    fromCity.value = ride.fromCity;
    toCity.value = ride.toCity;
    fromLat.value = ride.fromLat;
    fromLng.value = ride.fromLng;
    toLat.value = ride.toLat;
    toLng.value = ride.toLng;
    rides.assignAll([ride]);
    selectedSeats[ride.id] = 1;
    selectedSeats.refresh();
  }

  Future<List<Ride>> _prioritizeFocusedRide(List<Ride> list) async {
    final rideId = focusRideId.value?.trim() ?? '';
    if (rideId.isEmpty) return list;

    final reordered = [...list];
    final existingIndex = reordered.indexWhere((ride) => ride.id == rideId);
    if (existingIndex != -1) {
      final matched = reordered.removeAt(existingIndex);
      reordered.insert(0, matched);
      return reordered;
    }

    try {
      final ride = await _api.getRideById(rideId);
      reordered.insert(0, ride);
    } catch (_) {
      // Ignore if the exact ride can not be fetched.
    }
    return reordered;
  }
}
