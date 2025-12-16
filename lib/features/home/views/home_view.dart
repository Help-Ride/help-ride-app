import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../shared/controllers/session_controller.dart';
import '../../../core/routes/app_routes.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final session = Get.find<SessionController>();

    return Obx(() {
      // 🔒 Session guard
      if (session.status.value != SessionStatus.authenticated) {
        Future.microtask(() => Get.offAllNamed(AppRoutes.login));
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }

      final email = session.email;
      final role = session.role;

      return Scaffold(
        appBar: AppBar(
          title: const Text('Home'),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                await session.logout();
                Get.offAllNamed(AppRoutes.login);
              },
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Email: $email'),
              const SizedBox(height: 8),
              Text('Role: $role'),
            ],
          ),
        ),
      );
    });
  }
}
