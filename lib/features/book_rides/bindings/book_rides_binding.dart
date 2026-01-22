import 'package:get/get.dart';
import '../controllers/book_rides_controller.dart';

class BookRidesBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<BookRidesController>(() => BookRidesController());
  }
}
