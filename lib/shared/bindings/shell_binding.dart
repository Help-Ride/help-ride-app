import 'package:get/get.dart';
import '../../features/home/controllers/home_controller.dart';
import '../../features/my-rides/controllers/my_rides_controller.dart';
import '../../features/my-rides/services/my_rides_api.dart';
import '../services/api_client.dart';

// class ShellBinding extends Bindings {
//   @override
//   void dependencies() {
//     Get.putAsync<ApiClient>(
//           () async => await ApiClient.create(),
//       permanent: true,
//     );
//
//     // My Rides Controller
//     Get.lazyPut<MyRidesController>(
//           () => MyRidesController(),
//     );
//     Get.lazyPut<HomeController>(() => HomeController(), fenix: true);
//   }
// }
class ShellBinding extends Bindings {
  @override
  void dependencies() {
    // ApiClient (ASYNC & GLOBAL)
    Get.putAsync<ApiClient>(
          () async => await ApiClient.create(),
      permanent: true,
    );

    // Passenger Rides API

    // My Rides API
    Get.lazyPut<MyRidesApi>(
          () => MyRidesApi(Get.find<ApiClient>()),
    );

    // Controllers
    Get.lazyPut<MyRidesController>(
          () => MyRidesController(Get.find<MyRidesApi>()),
    );

    Get.lazyPut<HomeController>(() => HomeController(), fenix: true);
  }
}
