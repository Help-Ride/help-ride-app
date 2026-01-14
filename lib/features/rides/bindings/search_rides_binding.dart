import 'package:get/get.dart';
import '../controllers/search_rides_controller.dart';

class SearchRidesBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SearchRidesController>(() => SearchRidesController());
  }
}
