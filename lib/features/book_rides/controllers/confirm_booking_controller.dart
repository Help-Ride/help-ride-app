import 'dart:math';
import 'package:get/get.dart';

class BookingConfirmedController extends GetxController {
  late final String route;
  late final String departureTime;
  late final double totalPrice;
  late final String bookingReference;

  @override
  void onInit() {
    super.onInit();

    final args = Get.arguments;

    if (args is Map<String, dynamic>) {
      route = args['route'] ?? '';
      departureTime = args['departureTime'] ?? '';
      totalPrice = (args['totalPrice'] ?? 0).toDouble();
    } else {
      // Fallback (safety)
      route = '';
      departureTime = '';
      totalPrice = 0;
    }

    bookingReference = _generateBookingReference();
  }

  String _generateBookingReference() {
    final random = Random();
    final now = DateTime.now();
    final randomNum = random.nextInt(1000).toString().padLeft(3, '0');
    return 'RB-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-$randomNum';
  }

  void goToMyRides() {
    // TODO
  }

  void backToHome() {
    Get.offAllNamed('/shell'); // better than popUntil
  }
}
