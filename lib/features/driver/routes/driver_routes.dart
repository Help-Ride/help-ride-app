import 'package:get/get.dart';
import 'package:help_ride/features/driver/bindings/create_ride_binding.dart';
import 'package:help_ride/features/driver/bindings/driver_ride_requests_binding.dart';
import 'package:help_ride/features/driver/bindings/driver_ride_details_binding.dart';
import 'package:help_ride/features/driver/bindings/edit_ride_binding.dart';
import 'package:help_ride/features/driver/bindings/driver_onboarding_binding.dart';
import 'package:help_ride/features/driver/middlewares/driver_access_middleware.dart';
import 'package:help_ride/features/driver/views/driver_active_ride_view.dart';
import 'package:help_ride/features/driver/views/create_ride_view.dart';
import 'package:help_ride/features/driver/views/driver_ride_requests_view.dart';
import 'package:help_ride/features/driver/views/driver_ride_details_view.dart';
import 'package:help_ride/features/driver/views/edit_ride_view.dart';
import 'package:help_ride/features/driver/views/driver_onboarding_view.dart';

class DriverRoutes {
  static const onboarding = '/driver/onboarding';
  static const createRide = '/driver/create-ride';
  static const rideRequests = '/driver/ride-requests';
  static const rideDetails = '/driver/rides/:id';
  static const editRide = '/driver/rides/:id/edit';
  static const activeRide = '/driver/active-ride';

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
      middlewares: [DriverAccessMiddleware()],
    ),
    GetPage(
      name: rideRequests,
      page: () => const DriverRideRequestsView(),
      binding: DriverRideRequestsBinding(),
      middlewares: [DriverAccessMiddleware()],
    ),
    GetPage(
      name: rideDetails,
      page: () => const DriverRideDetailsView(),
      binding: DriverRideDetailsBinding(),
      middlewares: [DriverAccessMiddleware()],
    ),
    GetPage(
      name: editRide,
      page: () => const EditRideView(),
      binding: EditRideBinding(),
      middlewares: [DriverAccessMiddleware()],
    ),
    GetPage(
      name: activeRide,
      page: () => const DriverActiveRideView(),
      middlewares: [DriverAccessMiddleware()],
    ),
    // GetPage(name: '/booking/success', page: () => const BookingSuccessView()),
  ];
}
