import 'package:get/get.dart';
import '../../features/home/controllers/home_controller.dart';
import '../../features/profile/Services/passenger_edit_profile_service.dart';
import '../../features/profile/controllers/edit_profile_controller.dart';
import '../../features/profile/controllers/passenger_profile_controller.dart';
import '../../shared/controllers/session_controller.dart';
import '../services/api_client.dart';

class ShellBinding extends Bindings {
  @override
  void dependencies() {

    // 1️⃣ ApiClient (named constructor create())
    Get.putAsync<ApiClient>(
          () async => await ApiClient.create(),
      permanent: true,
    );

    // 2️⃣ Home Controller
    Get.lazyPut<HomeController>(() => HomeController(), fenix: true);

    // 3️⃣ Session Controller
    Get.lazyPut<SessionController>(() => SessionController(), fenix: true);

    // 4️⃣ Passenger Profile API
    Get.lazyPut<PassengerProfileApi>(
          () => PassengerProfileApi(Get.find<ApiClient>()),
      fenix: true,
    );

    // 5️⃣ Passenger Profile Controller
    Get.lazyPut<PassengerProfileController>(
          () => PassengerProfileController(
        Get.find<SessionController>(),
        Get.find<PassengerProfileApi>(),
      ),
      fenix: true,
    );

    // 6️⃣ Edit Profile Controller
    Get.lazyPut<EditProfileController>(
          () => EditProfileController(
        Get.find<SessionController>(),
        Get.find<PassengerProfileApi>(),
      ),
      fenix: true,
    );

  }
}
