import 'package:get/get.dart';

import '../controllers/confirm_booking_controller.dart';

class BookingConfirmedBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<BookingConfirmedController>(
          () => BookingConfirmedController(),
    );
  }
}
