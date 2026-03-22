import 'package:get/get.dart';
import '../controllers/auth_code_controller.dart';

class AuthCodeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AuthCodeController>(() => AuthCodeController());
  }
}
