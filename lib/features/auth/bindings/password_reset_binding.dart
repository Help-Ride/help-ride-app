import 'package:get/get.dart';
import '../controllers/password_reset_controller.dart';

class PasswordResetBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<PasswordResetController>()) {
      Get.lazyPut<PasswordResetController>(() => PasswordResetController());
    }
  }
}
