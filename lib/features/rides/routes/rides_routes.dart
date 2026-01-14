import 'package:get/get.dart';
import 'package:help_ride/features/rides/bindings/ride_details_binding.dart';
import 'package:help_ride/features/rides/views/ride_details_view.dart';
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
    // wherever your GetPages are (AppRoutes or feature routes)
    GetPage(
      name: '/rides/:id',
      page: () => const RideDetailsView(),
      binding: RideDetailsBinding(),
    ),
    // GetPage(name: '/booking/success', page: () => const BookingSuccessView()),
  ];
}
