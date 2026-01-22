import 'package:get/get.dart';

import '../controller/create_ride_request_controller.dart';

class CreateRideRequestBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CreateRideRequestController>(() => CreateRideRequestController());
  }
}
