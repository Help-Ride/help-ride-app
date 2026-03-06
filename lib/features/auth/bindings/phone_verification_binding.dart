import 'package:get/get.dart';
import '../controllers/phone_verification_controller.dart';

class PhoneVerificationBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<PhoneVerificationController>()) {
      Get.lazyPut<PhoneVerificationController>(
        () => PhoneVerificationController(),
      );
    }
  }
}
