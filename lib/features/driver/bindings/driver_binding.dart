import 'package:get/get.dart';
import '../controllers/driver_gate_controller.dart';

class DriverBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DriverGateController>(
      () => DriverGateController(),
      fenix: true,
    );
  }
}
