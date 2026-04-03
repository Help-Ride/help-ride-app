import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/session_controller.dart';
import '../../features/auth/routes/auth_routes.dart';

class SplashGate extends StatelessWidget {
  const SplashGate({super.key});

  @override
  Widget build(BuildContext context) {
    final session = Get.find<SessionController>();

    return Obx(() {
      final s = session.status.value;

      if (s == SessionStatus.authenticated) {
        Future.microtask(() async {
          await session.openVerifiedAppDestination(
            flushPendingNavigation: true,
          );
        });
      } else if (s == SessionStatus.unauthenticated) {
        Future.microtask(() => Get.offAllNamed(AuthRoutes.login));
      }

      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    });
  }
}
