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

    final missingCoords = fromLat.value == null ||
        fromLng.value == null ||
        toLat.value == null ||
        toLng.value == null;
    if (missingCoords) {
      error.value = 'Missing location coordinates. Select places from suggestions.';
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
      final fromLatValue = fromLat.value;
      final fromLngValue = fromLng.value;
      final toLatValue = toLat.value;
      final toLngValue = toLng.value;
      if (fromLatValue == null ||
          fromLngValue == null ||
          toLatValue == null ||
          toLngValue == null) {
        throw Exception('Missing location coordinates.');
      }

      final list = await _api.searchRides(
        seats: seatsRequired.value,
        fromLat: fromLatValue,
        fromLng: fromLngValue,
        toLat: toLatValue,
        toLng: toLngValue,
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
