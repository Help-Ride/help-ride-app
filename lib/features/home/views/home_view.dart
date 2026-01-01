import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/role_toggle.dart';
import '../controllers/home_controller.dart';
import '../widgets/passenger/passenger_home.dart';
import '../widgets/driver/driver_home.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final c = controller;

    return Scaffold(
      backgroundColor: AppColors.lightBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Obx(() {
                      final isPassenger = c.role.value == HomeRole.passenger;
                      return Text(
                        isPassenger ? "Hello, John" : "Driver Dashboard",
                        style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          color: AppColors.lightText,
                        ),
                      );
                    }),
                  ),
                  const SizedBox(width: 10),

                  // ✅ here
                  Obx(() {
                    return RoleToggle(
                      role: c.role.value,
                      onPassenger: () => c.setRole(HomeRole.passenger),
                      onDriver: () => c.setRole(HomeRole.driver),
                    );
                  }),
                ],
              ),

              const SizedBox(height: 18),

              Expanded(
                child: Obx(() {
                  return c.role.value == HomeRole.passenger
                      ? const PassengerHome()
                      : const DriverHome();
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
