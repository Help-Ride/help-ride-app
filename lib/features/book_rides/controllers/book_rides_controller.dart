import 'package:get/get.dart';
import '../../home/Models/passenger_search_ride_model.dart';
import '../Models/ride_model.dart';

class BookRidesController extends GetxController {
  final isLoading = false.obs;
  final availableRides = <Ride>[].obs;
  final selectedSeats = <int, int>{}.obs;

  /// Initialize data from previous screen
  void setRides(List<PassengerSearchRidesModel>? apiRides) {
    if (apiRides == null || apiRides.isEmpty) return;

    availableRides.assignAll(
      apiRides.map(_mapToUiRide).toList(),
    );

    /// Default seat selection = 1
    for (int i = 0; i < availableRides.length; i++) {
      selectedSeats[i] = 1;
    }
  }

  Ride _mapToUiRide(PassengerSearchRidesModel r) {
    return Ride(
      driverName: r.driver?.name ?? 'Unknown',
      driverInitials:
      (r.driver?.name?.isNotEmpty ?? false)
          ? r.driver!.name![0]
          : 'U',
      rating:  0.0,
      totalRides:  0,
      departureTime: formatRideTime(r.startTime.toString()),
      duration:  0,
      availableSeats: r.seatsAvailable ?? 0,
      pricePerSeat: double.parse(r.pricePerSeat.toString()),
      isVerified:  false,
    );
  }

  void updateSeats(int index, int seats) {
    selectedSeats[index] = seats;
  }

  String formatRideTime(String? isoTime) {
    if (isoTime == null) return '';
    final date = DateTime.tryParse(isoTime);
    if (date == null) return '';
    return '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
