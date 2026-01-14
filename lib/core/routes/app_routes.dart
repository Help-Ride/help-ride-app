import 'package:get/get.dart';
import 'package:help_ride/features/bookings/routes/booking_routes.dart';
import 'package:help_ride/features/driver/routes/driver_routes.dart';
import 'package:help_ride/features/rides/routes/rides_routes.dart';
import 'package:help_ride/shared/bindings/shell_binding.dart';
import 'package:help_ride/shared/views/app_shell.dart';
import '../../features/auth/routes/auth_routes.dart';
import '../../shared/views/splash_gate.dart';

class AppRoutes {
  static const gate = '/';
  static const shell = '/shell';
  static const login = '/login';

  static final pages = [
    GetPage(name: gate, page: () => const SplashGate()),
    ...AuthRoutes.pages, // /login etc.
    ...RidesRoutes.pages, // /rides/search etc.
    ...BookingRoutes.pages, // /booking/success etc.
    ...DriverRoutes.pages, // /driver/onboarding etc.
    GetPage(name: shell, page: () => const AppShell(), binding: ShellBinding()),
  ];
}
