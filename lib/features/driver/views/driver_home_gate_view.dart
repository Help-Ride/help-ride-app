import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:help_ride/features/driver/controllers/driver_onboarding_controller.dart';
import 'package:help_ride/features/driver/widgets/driver_home.dart';
import '../controllers/driver_gate_controller.dart';
import 'driver_onboarding_view.dart';

class DriverHomeGateView extends GetView<DriverGateController> {
  const DriverHomeGateView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (!controller.hasDriverProfile) {
        if (!Get.isRegistered<DriverOnboardingController>()) {
          Get.lazyPut<DriverOnboardingController>(
            () => DriverOnboardingController(),
            fenix: true,
          );
        }
        return const DriverOnboardingView();
      }
      return const DriverHomeView();
    });
  }
}
