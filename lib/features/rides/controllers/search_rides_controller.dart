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

    final rawSeats = args['seats'];
    final parsedSeats = rawSeats is int
        ? rawSeats
        : int.tryParse((rawSeats ?? '1').toString()) ?? 1;

    seatsRequired.value = parsedSeats <= 0 ? 1 : parsedSeats;

    // If args missing, fail gracefully (don’t crash)
    if (fromCity.value.isEmpty || toCity.value.isEmpty) {
      error.value = 'Missing from/to city. Go back and select locations.';
      return;
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
      final list = await _api.searchRides(
        fromCity: fromCity.value,
        toCity: toCity.value,
        seats: seatsRequired.value,
        fromLat: fromLat.value,
        fromLng: fromLng.value,
        toLat: toLat.value,
        toLng: toLng.value,
        radiusKm: radiusKm.value,
      );

      rides.assignAll(list);

      // init default selection if missing
      for (final r in list) {
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
}
