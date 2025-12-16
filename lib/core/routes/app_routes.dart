import 'package:get/get.dart';
import 'package:help_ride/features/auth/views/login_view.dart';
import '../../features/auth/routes/auth_routes.dart';
import '../../features/home/views/home_view.dart';
import '../../shared/views/splash_gate.dart';

class AppRoutes {
  static const gate = '/';
  static const login = '/login';
  static const home = '/home';

  static final pages = [
    GetPage(name: gate, page: () => const SplashGate()),
    GetPage(name: login, page: () => LoginView()),
    ...AuthRoutes.pages,
    GetPage(name: home, page: () => const HomeView()),
  ];
}
