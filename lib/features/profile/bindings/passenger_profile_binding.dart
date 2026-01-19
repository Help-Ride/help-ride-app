import 'package:get/get.dart';
import '../controllers/passenger_profile_controller.dart';

class PassengerProfileBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PassengerProfileController>(
          () => PassengerProfileController(),
    );
  }
}