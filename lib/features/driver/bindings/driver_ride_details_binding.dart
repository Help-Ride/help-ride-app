import 'package:get/get.dart';
import 'package:help_ride/features/driver/controllers/driver_ride_details_controller.dart';

class DriverRideDetailsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DriverRideDetailsController>(
      () => DriverRideDetailsController(),
      fenix: true,
    );
  }
}
