import 'package:get/get.dart';
import 'package:help_ride/shared/bindings/shell_binding.dart';
import 'package:help_ride/shared/views/app_shell.dart';
import '../../features/auth/routes/auth_routes.dart';
import '../../features/create ride request/bindings/create_ride_request_binding.dart';
import '../../features/create ride request/screen/create_ride_request_screen.dart';
import '../../shared/views/splash_gate.dart';

class AppRoutes {
  static const gate = '/';
  static const shell = '/shell';
  static const login = '/login';
  static const register = '/register';

  // Rides routes
  static const createRideRequest = '/create-ride-request';

  static final pages = [
    GetPage(name: gate, page: () => const SplashGate()),
    ...AuthRoutes.pages, // /login etc.
    GetPage(name: shell, page: () => const AppShell(), binding: ShellBinding()),
    GetPage(
      name: createRideRequest,
      page: () => const CreateRideRequestScreen(),
      binding: CreateRideRequestBinding(),
    ),
  ];
}
