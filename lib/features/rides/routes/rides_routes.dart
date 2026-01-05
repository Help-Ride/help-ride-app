import 'package:get/get.dart';
import '../bindings/search_rides_binding.dart';
import '../views/search_rides_view.dart';

class RidesRoutes {
  static const search = '/rides/search';

  static final pages = [
    GetPage(
      name: search,
      page: () => const SearchRidesView(),
      binding: SearchRidesBinding(),
    ),
  ];
}
