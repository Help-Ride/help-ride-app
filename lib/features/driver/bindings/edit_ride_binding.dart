import 'package:get/get.dart';
import 'package:help_ride/features/driver/controllers/edit_ride_controller.dart';

class EditRideBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<EditRideController>(() => EditRideController(), fenix: true);
  }
}
