import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:help_ride/features/driver/controllers/driver_gate_controller.dart';
import 'package:help_ride/features/driver/views/driver_home_gate_view.dart';
import 'package:help_ride/features/driver/views/driver_onboarding_view.dart';
import '../../../shared/widgets/role_toggle.dart';
import '../controllers/home_controller.dart';
import '../widgets/passenger/passenger_home.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final driverGate = Get.find<DriverGateController>();

    return Obx(() {
      final showDriverOnboardingFullscreen =
          c.role.value == HomeRole.driver && !driverGate.hasDriverProfile;

      if (showDriverOnboardingFullscreen) {
        return const DriverOnboardingView();
      }

      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
            child: Column(
              children: [
                _HomeHeader(controller: c),
                const SizedBox(height: 12),
                Expanded(child: _RoleHomeContent(controller: c)),
              ],
            ),
          ),
        ),
      );
    });
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 430;
        final toggleWidth = constraints.maxWidth < 680 ? 220.0 : 232.0;

        return Obx(() {
          final roleToggle = RoleToggle(
            role: controller.role.value,
            onPassenger: () => controller.setRole(HomeRole.passenger),
            onDriver: () => controller.setRole(HomeRole.driver),
          );
          if (narrow) {
            return SizedBox(width: double.infinity, child: roleToggle);
          }
          return Align(
            alignment: Alignment.centerRight,
            child: SizedBox(width: toggleWidth, child: roleToggle),
          );
        });
      },
    );
  }
}

class _RoleHomeContent extends StatelessWidget {
  const _RoleHomeContent({required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isPassenger = controller.role.value == HomeRole.passenger;
      const duration = Duration(milliseconds: 280);

      return Stack(
        fit: StackFit.expand,
        children: [
          IgnorePointer(
            ignoring: !isPassenger,
            child: AnimatedOpacity(
              duration: duration,
              curve: Curves.easeOutCubic,
              opacity: isPassenger ? 1 : 0,
              child: AnimatedSlide(
                duration: duration,
                curve: Curves.easeOutCubic,
                offset: isPassenger ? Offset.zero : const Offset(-0.04, 0),
                child: const PassengerHome(),
              ),
            ),
          ),
          IgnorePointer(
            ignoring: isPassenger,
            child: AnimatedOpacity(
              duration: duration,
              curve: Curves.easeOutCubic,
              opacity: isPassenger ? 0 : 1,
              child: AnimatedSlide(
                duration: duration,
                curve: Curves.easeOutCubic,
                offset: isPassenger ? const Offset(0.04, 0) : Offset.zero,
                child: const DriverHomeGateView(),
              ),
            ),
          ),
        ],
      );
    });
  }
}
