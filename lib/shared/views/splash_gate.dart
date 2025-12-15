import 'package:flutter/material.dart';
import 'package:get/get.dart';
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

      if (s == SessionStatus.authenticated) {
        Future.microtask(() => Get.offAllNamed(AppRoutes.home));
      } else if (s == SessionStatus.unauthenticated) {
        Future.microtask(() => Get.offAllNamed(AuthRoutes.login));
      }

      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    });
  }
}
