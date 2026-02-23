import 'package:get/get.dart';
import 'package:help_ride/features/auth/views/register_view.dart';
import '../bindings/auth_binding.dart';
import '../bindings/email_verification_binding.dart';
import '../bindings/password_reset_binding.dart';
import '../views/email_verification_view.dart';
import '../views/login_view.dart';
import '../views/password_reset_view.dart';

class AuthRoutes {
  static const login = '/login';
  static const register = '/register';
  static const verifyEmail = '/verify-email';
  static const passwordReset = '/password-reset';

  static final pages = [
    GetPage(name: login, page: () => const LoginView(), binding: AuthBinding()),
    GetPage(
      name: register,
      page: () => const RegisterView(),
      binding: AuthBinding(), // ✅ add this
    ),
    GetPage(
      name: verifyEmail,
      page: () => const EmailVerificationView(),
      binding: EmailVerificationBinding(),
    ),
    GetPage(
      name: passwordReset,
      page: () => const PasswordResetView(),
      binding: PasswordResetBinding(),
    ),
  ];
}
