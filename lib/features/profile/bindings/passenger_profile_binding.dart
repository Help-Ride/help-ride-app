import 'package:get/get.dart';
import '../../../shared/controllers/session_controller.dart';
import '../../../shared/services/api_client.dart';
import '../Services/passenger_edit_profile_service.dart';
import '../controllers/passenger_profile_controller.dart';
import '../controllers/edit_profile_controller.dart';

class PassengerProfileBinding extends Bindings {
  @override
  void dependencies() {

    // Passenger Profile API
    Get.lazyPut<PassengerProfileApi>(
          () => PassengerProfileApi(Get.find<ApiClient>()),
      fenix: true,
    );

    // Profile Controller
    Get.lazyPut<PassengerProfileController>(
          () => PassengerProfileController(
        Get.find<SessionController>(),
        Get.find<PassengerProfileApi>(),
      ),
      fenix: true,
    );

    // Edit Profile Controller
    Get.lazyPut<EditProfileController>(
          () => EditProfileController(
        Get.find<SessionController>(),
        Get.find<PassengerProfileApi>(),
      ),
      fenix: true,
    );
  }
}
