import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../models/passenger_my_ride_list.dart';
import '../services/my_rides_api.dart';

class MyRidesController extends GetxController {
  MyRidesController(this._api);

  final MyRidesApi _api;
  final selectedTab = 0.obs; // 0 = Upcoming, 1 = Past
  final isLoading = false.obs;

  final allRides = <PassengerMyRideList>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchMyRides();
  }

  void changeTab(int index) {
    selectedTab.value = index;
  }

  String formatRideDate(DateTime dateTime) {
    final local = dateTime.toLocal();
    return DateFormat('MMM d, h:mm a').format(local);
  }

  Future<void> fetchMyRides() async {
    try {
      isLoading.value = true;
      final result = await _api.getMyRides();
      allRides.assignAll(result);
    } catch (e) {
      Get.snackbar('Error', e.toString());
      print("error--${e.toString()}");
    } finally {
      isLoading.value = false;
    }
  }

  /// 🔥 Upcoming rides
  List<PassengerMyRideList> get upcomingRides {
    final now = DateTime.now();
    return allRides.where((e) {
      final rideTime = e.ride?.startTime;
      return rideTime != null && rideTime.isAfter(now);
    }).toList();
  }

  /// 🔥 Past rides
  List<PassengerMyRideList> get pastRides {
    final now = DateTime.now();
    return allRides.where((e) {
      final rideTime = e.ride?.startTime;
      return rideTime != null && rideTime.isBefore(now);
    }).toList();
  }
}
