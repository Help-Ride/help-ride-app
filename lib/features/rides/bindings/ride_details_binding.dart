import 'package:get/get.dart';
import '../controllers/ride_details_controller.dart';

class RideDetailsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<RideDetailsController>(() => RideDetailsController());
  }
}
