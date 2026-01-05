import 'package:get/get.dart';
import 'package:help_ride/features/auth/views/register_view.dart';
import '../bindings/auth_binding.dart';
import '../views/login_view.dart';

class AuthRoutes {
  static const login = '/login';
  static const register = '/register';

  static final pages = [
    GetPage(name: login, page: () => const LoginView(), binding: AuthBinding()),
    GetPage(
      name: register,
      page: () => const RegisterView(),
      binding: AuthBinding(), // ✅ add this
    ),
  ];
}
