import 'package:get/get.dart';
import '../../features/home/controllers/home_controller.dart';

class ShellBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<HomeController>(() => HomeController(), fenix: true);
  }
}
