import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../core/routes/app_routes.dart';
import '../../../shared/controllers/session_controller.dart';
import '../Models/passenger_search_ride_model.dart';
import '../services/passenger_search_rides_api.dart';

enum HomeRole { passenger, driver }

class HomeController extends GetxController {
  HomeController(this._api, this._session);

  final role = HomeRole.passenger.obs;
  final recentSearches = <PassengerSearchRidesModel>[].obs;
  final isLoading = false.obs;

  final PassengerRidesApi _api;
  final SessionController _session;

  void setRole(HomeRole r) => role.value = r;

  String get headerName {
    final user = _session.user.value;
    final fullName = (user?.name ?? '').trim();

    if (fullName.isNotEmpty) {
      final first = fullName.split(RegExp(r'\s+')).first.trim();
      if (first.isNotEmpty) return first;
    }

    final email = (user?.email ?? '').trim();
    if (email.isNotEmpty && email.contains('@')) {
      final prefix = email.split('@').first.trim();
      if (prefix.isNotEmpty) return prefix;
    }

    return 'User';
  }


  String formatRideTime(String utcTime) {
    if (utcTime.isEmpty) return '';

    final dtUtc = DateTime.parse(utcTime);
    final local = dtUtc.toLocal();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final date = DateTime(local.year, local.month, local.day);

    String dayText;

    if (date == today) {
      dayText = "Today";
    } else if (date == tomorrow) {
      dayText = "Tomorrow";
    } else {
      dayText = DateFormat("MMM d").format(local);
    }

    final timeText = DateFormat("h:mm a").format(local);
    return "$dayText, $timeText";
  }


  void addRecentSearch(PassengerSearchRidesModel ride) {
    // Remove duplicates based on fromCity + toCity
    recentSearches.removeWhere((r) =>
    r.fromCity == ride.fromCity && r.toCity == ride.toCity);

    // Add new search at top
    recentSearches.insert(0, ride);

    // Optional: limit list size
    if (recentSearches.length > 5) {
      recentSearches.removeLast();
    }
  }


  Future<void> searchRides({
    required String fromCity,
    required String toCity,
    int seats = 1,
  }) async {
    try {
      isLoading.value = true;

      final rides = await _api.searchRides(
        fromCity: fromCity,
        toCity: toCity,
        seats: seats,
      );

      recentSearches.assignAll(rides);
      // Add to recent searches list
      if (rides.isNotEmpty) {
        addRecentSearch(rides.first);
      }

      // Get.toNamed(AppRoutes.bookRides, arguments: rides);
    } catch (e) {
      Get.snackbar('Error', e.toString());
    } finally {
      isLoading.value = false;
    }
  }
}
