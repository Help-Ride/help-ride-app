import 'package:get/get.dart';
import '../../features/home/controllers/home_controller.dart';
import '../../features/notifications/controllers/notification_center_controller.dart';

class ShellBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<HomeController>(() => HomeController(), fenix: true);
    Get.lazyPut<NotificationCenterController>(
      () => NotificationCenterController(),
      fenix: true,
    );
  }
}
