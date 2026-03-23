import 'package:get/get.dart';

import '../controllers/driver_ride_series_controller.dart';

class DriverRideSeriesBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DriverRideSeriesController>(
      () => DriverRideSeriesController(),
      fenix: true,
    );
  }
}
