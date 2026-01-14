import 'package:get/get.dart';
import '../../../shared/controllers/session_controller.dart';

class DriverGateController extends GetxController {
  final SessionController session = Get.find<SessionController>();

  bool get hasDriverProfile => session.user.value?.driverProfile != null;
  bool get isVerified => session.user.value?.driverProfile?.isVerified == true;
}
