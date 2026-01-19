import 'package:get/get.dart';
import '../../features/home/controllers/home_controller.dart';
import '../../features/home/services/passenger_search_rides_api.dart';
import '../controllers/session_controller.dart';
import '../services/api_client.dart';

class ShellBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PassengerRidesApi>(
      () => PassengerRidesApi(Get.find<ApiClient>()),
      fenix: true,
    );

    Get.lazyPut<HomeController>(
      () => HomeController(
        Get.find<PassengerRidesApi>(),
        Get.find<SessionController>(),
      ),
      fenix: true,
    );
  }
}
