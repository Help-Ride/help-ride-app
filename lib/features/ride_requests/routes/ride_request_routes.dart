import 'package:get/get.dart';
import '../bindings/ride_request_form_binding.dart';
import '../views/ride_request_form_view.dart';

class RideRequestRoutes {
  static const create = '/ride-requests/create';
  static const edit = '/ride-requests/edit';

  static final pages = [
    GetPage(
      name: create,
      page: () => const RideRequestFormView(),
      binding: RideRequestFormBinding(),
    ),
    GetPage(
      name: edit,
      page: () => const RideRequestFormView(),
      binding: RideRequestFormBinding(),
    ),
  ];
}
