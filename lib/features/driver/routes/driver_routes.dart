import 'package:get/get.dart';
import 'package:help_ride/features/driver/bindings/create_ride_binding.dart';
import 'package:help_ride/features/driver/bindings/driver_onboarding_binding.dart';
import 'package:help_ride/features/driver/views/create_ride_view.dart';
import 'package:help_ride/features/driver/views/driver_onboarding_view.dart';

class DriverRoutes {
  static const onboarding = '/driver/onboarding';
  static const createRide = '/driver/create-ride';

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
    // GetPage(name: '/booking/success', page: () => const BookingSuccessView()),
  ];
}
