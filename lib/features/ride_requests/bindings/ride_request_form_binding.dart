import 'package:get/get.dart';
import '../controllers/ride_request_form_controller.dart';

class RideRequestFormBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(RideRequestFormController());
  }
}
