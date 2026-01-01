import 'package:get/get.dart';
import 'package:help_ride/features/onboarding/view/onboarding_view.dart';
import '../bindings/auth_binding.dart';
import '../views/login_view.dart';

class AuthRoutes {
  static const login = '/login';
  static const onboarding = '/onboarding';

  static final pages = [
    GetPage(name: login, page: () => LoginView(), binding: AuthBinding()),
    GetPage(name: onboarding, page: () => OnboardingScreen(), binding: AuthBinding()),
  ];
}
