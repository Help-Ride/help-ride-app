import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:help_ride/features/onboarding/controllers/onboarding_controller.dart';
import '../controllers/session_controller.dart';
import '../../core/routes/app_routes.dart';
import '../../features/auth/routes/auth_routes.dart';

class SplashGate extends StatelessWidget {
  const SplashGate({super.key});

  @override
  Widget build(BuildContext context) {
    final session = Get.find<SessionController>();

    return Obx(() {
      final s = session.status.value;

      // 1) Onboarding gate (run once)
      if (!OnboardingController.seen()) {
        Future.microtask(() => Get.offAllNamed(AppRoutes.onboarding));
        return const SizedBox.shrink();
      }

      // 2) Session gate
      if (s == SessionStatus.authenticated) {
        Future.microtask(() => Get.offAllNamed(AppRoutes.shell)); // ✅ not home
        return const SizedBox.shrink();
      }

      if (s == SessionStatus.unauthenticated) {
        Future.microtask(() => Get.offAllNamed(AuthRoutes.login));
        return const SizedBox.shrink();
      }

      // 3) unknown -> loading
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    });
  }
}
