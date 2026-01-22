import 'package:get/get.dart';
import '../controllers/book_ride_detail_controller.dart';

class BookRideDetailBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<BookRideDetailController>(
          () => BookRideDetailController(),
    );
  }
}
