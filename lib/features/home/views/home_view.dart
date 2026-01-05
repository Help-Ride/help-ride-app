import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/role_toggle.dart';
import '../../../shared/controllers/session_controller.dart';
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
              _HomeHeader(controller: c),
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

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    final session = Get.isRegistered<SessionController>()
        ? Get.find<SessionController>()
        : null;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Cap toggle width so it doesn't crush the title.
        final toggleMaxWidth = (constraints.maxWidth * 0.48).clamp(
          170.0,
          240.0,
        );

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left header: must be flexible and safe for long names/titles.
            Expanded(
              child: Obx(() {
                final isPassenger = controller.role.value == HomeRole.passenger;

                final firstName = (session?.user.value?.name ?? 'User')
                    .toString()
                    .trim();
                final name = firstName.isEmpty
                    ? 'User'
                    : firstName.split(' ').first;

                if (isPassenger) {
                  // "Hello," (small) + Name (big)
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Hello,",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          color: AppColors.lightText,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          color: AppColors.lightText,
                          height: 1.0,
                        ),
                      ),
                    ],
                  );
                }

                // Driver title: allow 2 lines and ellipsis as last resort.
                return const Text(
                  "Driver Dashboard",
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: AppColors.lightText,
                    height: 1.05,
                  ),
                );
              }),
            ),

            const SizedBox(width: 12),

            // Right: role toggle with capped width.
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: toggleMaxWidth),
              child: Align(
                alignment: Alignment.topRight,
                child: Obx(() {
                  return RoleToggle(
                    role: controller.role.value,
                    onPassenger: () => controller.setRole(HomeRole.passenger),
                    onDriver: () => controller.setRole(HomeRole.driver),
                  );
                }),
              ),
            ),
          ],
        );
      },
    );
  }
}
