import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../shared/controllers/session_controller.dart';
import '../../../core/routes/app_routes.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final session = Get.find<SessionController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await session.logout();
              Get.offAllNamed(AppRoutes.gate);
            },
          ),
        ],
      ),
      body: const Center(child: Text('Logged in ✅')),
    );
  }
}
