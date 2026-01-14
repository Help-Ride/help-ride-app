// features/driver/bindings/driver_gate_binding.dart
import 'package:get/get.dart';
import '../controllers/driver_gate_controller.dart';

class DriverGateBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DriverGateController>(
      () => DriverGateController(),
      fenix: true,
    );
  }
}
