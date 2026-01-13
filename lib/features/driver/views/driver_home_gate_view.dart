import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:help_ride/features/driver/widgets/driver_home.dart';
import '../controllers/driver_gate_controller.dart';

class DriverHomeGateView extends GetView<DriverGateController> {
  const DriverHomeGateView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final hasProfile = controller.session.user.value?.driverProfile != null;

      if (!hasProfile) {
        Future.microtask(() => Get.toNamed('/driver/onboarding'));
        return const SizedBox.shrink();
      }
      return const DriverHomeView();
    });
  }
}
