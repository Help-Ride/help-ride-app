import 'package:get/get.dart';
import 'package:help_ride/shared/bindings/shell_binding.dart';
import 'package:help_ride/shared/views/app_shell.dart';
import '../../features/auth/routes/auth_routes.dart';
import '../../features/my-rides/bindings/my_rides_binding.dart';
import '../../features/my-rides/views/screens/my_rides_screen.dart';
import '../../shared/views/splash_gate.dart';

class AppRoutes {
  static const gate = '/';
  static const shell = '/shell';
  static const login = '/login';
  static const register = '/register';

  static const myRides = '/my-rides';


  static final pages = [
    GetPage(name: gate, page: () => const SplashGate()),
    ...AuthRoutes.pages, // /login etc.
    GetPage(name: shell, page: () => const AppShell(), binding: ShellBinding()),
    GetPage(
      name: myRides,
      page: () =>  MyRidesView(),
      binding: MyRidesBinding(),
    ),
  ];
}
