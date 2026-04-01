import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:help_ride/core/constants/app_constants.dart';
import 'package:help_ride/features/driver/controllers/driver_gate_controller.dart';
import 'package:help_ride/features/driver/views/driver_home_gate_view.dart';
import 'package:help_ride/features/driver/views/driver_onboarding_view.dart';
import 'package:help_ride/features/notifications/controllers/notification_center_controller.dart';
import 'package:help_ride/features/notifications/views/notification_center_sheet.dart';
import 'package:help_ride/features/notifications/widgets/notification_bell_button.dart';
import 'package:help_ride/features/notifications/widgets/priority_notification_banner.dart';
import '../../../shared/widgets/role_toggle.dart';
import '../controllers/home_controller.dart';
import '../widgets/passenger/passenger_home.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final driverGate = Get.find<DriverGateController>();
    final notifications = Get.find<NotificationCenterController>();

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
                _HomeHeader(controller: c, notifications: notifications),
                _HomeNotificationSlot(
                  controller: c,
                  notifications: notifications,
                ),
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
  const _HomeHeader({required this.controller, required this.notifications});

  final HomeController controller;
  final NotificationCenterController notifications;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark
        ? const Color(0xFFEDEDF4)
        : const Color(0xFF111111);
    final muted = isDark ? const Color(0xFF9A9AA6) : const Color(0xFF6B7280);

    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 430;
        final toggleWidth = narrow ? constraints.maxWidth : 236.0;

        return Obx(() {
          final isDriver = controller.role.value == HomeRole.driver;
          final subtitle = isDriver
              ? 'Stay ahead of ride requests, bookings, and payout changes.'
              : 'Search faster, manage bookings, and catch urgent trip changes.';
          final roleToggle = RoleToggle(
            role: controller.role.value,
            onPassenger: () => controller.setRole(HomeRole.passenger),
            onDriver: () => controller.setRole(HomeRole.driver),
          );

          return Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hello, ${controller.headerName}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: textPrimary,
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            height: 1,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: muted,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Obx(
                    () => NotificationBellButton(
                      unreadCount: notifications.unreadCount,
                      onTap: () => showNotificationCenterSheet(context),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Align(
                alignment: Alignment.centerLeft,
                child: SizedBox(width: toggleWidth, child: roleToggle),
              ),
              const SizedBox(height: 12),
            ],
          );
        });
      },
    );
  }
}

class _HomeNotificationSlot extends StatelessWidget {
  const _HomeNotificationSlot({
    required this.controller,
    required this.notifications,
  });

  final HomeController controller;
  final NotificationCenterController notifications;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final role = controller.role.value == HomeRole.driver
          ? AppRole.driver
          : AppRole.passenger;
      final urgent = notifications.urgentNotificationForRole(role);
      if (urgent == null) {
        return const SizedBox.shrink();
      }

      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: PriorityNotificationBanner(
          notification: urgent,
          onTap: () => notifications.openNotification(urgent),
        ),
      );
    });
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
