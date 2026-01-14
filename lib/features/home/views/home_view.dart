import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:help_ride/features/driver/views/driver_home_gate_view.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/role_toggle.dart';
import '../../../shared/controllers/session_controller.dart';
import '../controllers/home_controller.dart';
import '../widgets/passenger/passenger_home.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final c = controller;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
                      : const DriverHomeGateView();
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        // ✅ Option A: fixed toggle width so text never becomes "Passe..."
        // Tune this number if needed (210–240 is usually safe).
        const double toggleWidth = 230;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left header: flexible area for greeting/title
            Expanded(
              child: Obx(() {
                final isPassenger = controller.role.value == HomeRole.passenger;

                final fullName = (session?.user.value?.name ?? 'User')
                    .toString()
                    .trim();
                final name = fullName.isEmpty
                    ? 'User'
                    : fullName.split(' ').first;

                if (isPassenger) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Hello,",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          color: isDark ? AppColors.darkText : AppColors.lightText,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          color: isDark ? AppColors.darkText : AppColors.lightText,
                          height: 1.0,
                        ),
                      ),
                    ],
                  );
                }

                return Text(
                  "Driver Dashboard",
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: isDark ? AppColors.darkText : AppColors.lightText,
                    height: 1.05,
                  ),
                );
              }),
            ),

            const SizedBox(width: 12),

            // Right: role toggle with fixed width
            SizedBox(
              width: toggleWidth,
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
