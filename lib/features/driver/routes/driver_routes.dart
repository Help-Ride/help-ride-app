import 'package:get/get.dart';
import 'package:help_ride/features/driver/bindings/create_ride_binding.dart';
import 'package:help_ride/features/driver/bindings/driver_onboarding_binding.dart';
import 'package:help_ride/features/driver/bindings/driver_ride_details_binding.dart';
import 'package:help_ride/features/driver/bindings/edit_ride_binding.dart';
import 'package:help_ride/features/driver/views/create_ride_view.dart';
import 'package:help_ride/features/driver/views/driver_onboarding_view.dart';
import 'package:help_ride/features/driver/views/driver_ride_details_view.dart';
import 'package:help_ride/features/driver/views/edit_ride_view.dart';

class DriverRoutes {
  static const onboarding = '/driver/onboarding';
  static const createRide = '/driver/create-ride';
  static const rideDetails = '/driver/rides/:id';
  static const editRide = '/driver/rides/:id/edit';

  static final pages = [
    GetPage(
      name: onboarding,
      page: () => const DriverOnboardingView(),
      binding: DriverOnboardingBinding(),
    ),
    GetPage(
      name: createRide,
      page: () => const CreateRideView(),
      binding: CreateRideBinding(),
    ),
    GetPage(
      name: rideDetails,
      page: () => const DriverRideDetailsView(),
      binding: DriverRideDetailsBinding(),
    ),
    GetPage(
      name: editRide,
      page: () => const EditRideView(),
      binding: EditRideBinding(),
    ),
    // GetPage(name: '/booking/success', page: () => const BookingSuccessView()),
  ];
}
