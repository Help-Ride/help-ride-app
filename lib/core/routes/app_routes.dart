import 'package:get/get.dart';
import 'package:help_ride/features/onboarding/view/onboarding_view.dart';
import 'package:help_ride/shared/views/app_shell.dart';
import '../../features/auth/routes/auth_routes.dart';
import '../../features/home/views/home_view.dart';
import '../../features/profile/views/passenger_profile_view.dart';
import '../../shared/views/splash_gate.dart';

class AppRoutes {
  static const gate = '/';
  static const home = '/home';
  static const profile = '/profile';
  static const login = '/login';
  static const shell = '/shell';
  static const onboarding = '/onboarding';

  static final pages = [
    GetPage(name: gate, page: () => const SplashGate()),
    ...AuthRoutes.pages, // contains /login
    GetPage(name: home, page: () => const HomeView()),
    GetPage(name: profile, page: () => const PassengerProfileView()),
    GetPage(name: shell, page: () => const AppShell()),
    GetPage(name: onboarding, page: () => const OnboardingScreen()),
  ];
}
