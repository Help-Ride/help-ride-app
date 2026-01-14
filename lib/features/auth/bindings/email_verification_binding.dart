import 'package:get/get.dart';
import '../controllers/email_verification_controller.dart';

class EmailVerificationBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<EmailVerificationController>()) {
      Get.lazyPut<EmailVerificationController>(
        () => EmailVerificationController(),
      );
    }
  }
}
