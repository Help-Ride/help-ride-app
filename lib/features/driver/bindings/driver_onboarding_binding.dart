import 'package:get/get.dart';
import '../controllers/driver_onboarding_controller.dart';

class DriverOnboardingBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DriverOnboardingController>(() => DriverOnboardingController());
  }
}
