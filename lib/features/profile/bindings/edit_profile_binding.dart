import 'package:get/get.dart';
import '../controllers/edit_profile_controller.dart';
import '../../../shared/controllers/session_controller.dart';
import '../Services/passenger_edit_profile_service.dart';

class EditProfileBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<EditProfileController>(
          () => EditProfileController(
        Get.find<SessionController>(),
        Get.find<PassengerProfileApi>(),
      ),
    );
  }
}
