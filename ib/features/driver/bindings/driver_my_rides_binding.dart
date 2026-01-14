import 'package:get/get.dart';
import 'package:help_ride/features/driver/controllers/driver_my_rides_controller.dart';

class DriverMyRidesBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DriverMyRidesController>(
      () => DriverMyRidesController(),
      fenix: true,
    );
  }
}
