import 'package:get/get.dart';
import '../../features/auth/routes/auth_routes.dart';
import '../../features/home/views/home_view.dart';
import '../../features/profile/views/passenger_profile_view.dart';
import '../../shared/views/splash_gate.dart';

class AppRoutes {
  static const gate = '/';
  static const home = '/home';
  static const profile = '/profile';
  static const login = '/login';

  static final pages = [
    GetPage(name: gate, page: () => const SplashGate()),
    ...AuthRoutes.pages, // contains /login
    GetPage(name: home, page: () => const HomeView()),
    GetPage(name: profile, page: () => const PassengerProfileView()),
  ];
}
