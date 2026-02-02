import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../features/auth/routes/auth_routes.dart';
import '../../../shared/controllers/session_controller.dart';
import '../routes/driver_routes.dart';

class DriverAccessMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    if (!Get.isRegistered<SessionController>()) {
      return const RouteSettings(name: AuthRoutes.login);
    }

    final session = Get.find<SessionController>();
    if (session.status.value != SessionStatus.authenticated) {
      return const RouteSettings(name: AuthRoutes.login);
    }

    if (session.requiresEmailVerification) {
      return const RouteSettings(name: AuthRoutes.verifyEmail);
    }

    if (session.isDriver) {
      return null;
    }

    if (Get.isRegistered<ThemeController>()) {
      final theme = Get.find<ThemeController>();
      if (theme.role.value != AppRole.driver) {
        theme.switchRole(AppRole.driver);
      }
    }

    return const RouteSettings(name: DriverRoutes.onboarding);
  }
}
