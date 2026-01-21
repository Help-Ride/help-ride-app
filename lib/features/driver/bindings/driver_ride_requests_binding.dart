import 'package:get/get.dart';
import '../controllers/driver_ride_requests_controller.dart';

class DriverRideRequestsBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(DriverRideRequestsController());
  }
}
