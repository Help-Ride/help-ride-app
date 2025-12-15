import 'package:get/get.dart';
import '../../features/auth/routes/auth_routes.dart';
import '../../features/home/views/home_view.dart';
import '../../shared/views/splash_gate.dart';

class AppRoutes {
  static const gate = '/';
  static const home = '/home';

  static final pages = [
    GetPage(name: gate, page: () => const SplashGate()),
    ...AuthRoutes.pages,
    GetPage(name: home, page: () => const HomeView()),
  ];
}
