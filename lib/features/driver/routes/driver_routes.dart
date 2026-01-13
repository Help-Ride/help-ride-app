import 'package:get/get.dart';
import 'package:help_ride/features/driver/bindings/driver_onboarding_binding.dart';
import 'package:help_ride/features/driver/views/driver_onboarding_view.dart';

class DriverRoutes {
  static const onboarding = '/driver/onboarding';

  static final pages = [
    GetPage(
      name: onboarding,
      page: () => const DriverOnboardingView(),
      binding: DriverOnboardingBinding(),
    ),
    // GetPage(name: '/booking/success', page: () => const BookingSuccessView()),
  ];
}
