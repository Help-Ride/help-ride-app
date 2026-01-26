import 'package:get/get.dart';
import '../../../shared/services/api_client.dart';
import '../controllers/my_rides_controller.dart';
import '../services/my_rides_api.dart';

class MyRidesBinding extends Bindings {
  @override
  void dependencies() {
    Get.putAsync<ApiClient>(() async => await ApiClient.create());

    Get.lazyPut<MyRidesApi>(
          () => MyRidesApi(Get.find<ApiClient>()),
    );

    Get.lazyPut<MyRidesController>(
          () => MyRidesController(Get.find<MyRidesApi>()),
    );
  }
}
