import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:help_ride/features/bookings/controllers/my_rides_controller.dart';
import 'package:help_ride/features/bookings/views/my_rides_view.dart';
import 'package:help_ride/features/driver/controllers/driver_gate_controller.dart';
import 'package:help_ride/features/driver/controllers/driver_onboarding_controller.dart';
import '../../core/theme/theme_controller.dart';
import '../controllers/session_controller.dart';
import '../../core/theme/app_colors.dart';

// pages
import '../../features/home/views/home_view.dart';
import '../../features/profile/views/passenger_profile_view.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int index = 0;

  @override
  void initState() {
    super.initState();

    Get.lazyPut<MyRidesController>(() => MyRidesController(), fenix: true);
    Get.lazyPut<DriverGateController>(
      () => DriverGateController(),
      fenix: true,
    );
    Get.lazyPut<DriverOnboardingController>(
      () => DriverOnboardingController(),
      fenix: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = Get.find<SessionController>();
    final theme = Get.find<ThemeController>();

    return Obx(() {
      if (session.status.value != SessionStatus.authenticated) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }

      final role = (session.user.value?.roleDefault ?? 'passenger')
          .toString()
          .toLowerCase();

      final config = role == 'driver' ? _driverConfig() : _passengerConfig();

      if (index >= config.items.length) index = 0;

      return Scaffold(
        body: config.pages[index],
        bottomNavigationBar: _FigmaBottomNavBar(
          index: index,
          isDark: theme.isDark.value,
          items: config.items,
          onChanged: (i) => setState(() => index = i),
        ),
      );
    });
  }
}

/* -------------------- ROLE CONFIG -------------------- */

class _NavConfig {
  final List<_NavItemData> items;
  final List<Widget> pages;
  _NavConfig(this.items, this.pages);
}

_NavConfig _passengerConfig() {
  final pages = const [
    HomeView(),
    MyRidesView(),
    _Placeholder(title: 'Messages'),
    PassengerProfileView(),
  ];

  final items = const [
    _NavItemData(
      label: 'Home',
      icon: Icons.home_outlined,
      selectedIcon: Icons.home_rounded,
    ),
    _NavItemData(
      label: 'My Rides',
      icon: Icons.location_on_outlined,
      selectedIcon: Icons.location_on,
    ),
    _NavItemData(
      label: 'Messages',
      icon: Icons.chat_bubble_outline_rounded,
      selectedIcon: Icons.chat_bubble_rounded,
    ),
    _NavItemData(
      label: 'Profile',
      icon: Icons.person_outline_rounded,
      selectedIcon: Icons.person_rounded,
    ),
  ];

  return _NavConfig(items, pages);
}

_NavConfig _driverConfig() {
  final pages = const [
    HomeView(),
    _Placeholder(title: 'Create Ride'),
    _Placeholder(title: 'Requests'),
    PassengerProfileView(),
  ];

  // Keep same bottom nav labels if you want the exact Figma bar.
  // Driver-specific tabs can come later.
  final items = const [
    _NavItemData(
      label: 'Home',
      icon: Icons.home_outlined,
      selectedIcon: Icons.home_rounded,
    ),
    _NavItemData(
      label: 'My Rides',
      icon: Icons.location_on_outlined,
      selectedIcon: Icons.location_on,
    ),
    _NavItemData(
      label: 'Messages',
      icon: Icons.chat_bubble_outline_rounded,
      selectedIcon: Icons.chat_bubble_rounded,
    ),
    _NavItemData(
      label: 'Profile',
      icon: Icons.person_outline_rounded,
      selectedIcon: Icons.person_rounded,
    ),
  ];

  return _NavConfig(items, pages);
}

/* -------------------- MODELS -------------------- */

class _NavItemData {
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  const _NavItemData({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });
}

/* -------------------- FIGMA BOTTOM NAV -------------------- */

class _FigmaBottomNavBar extends StatelessWidget {
  const _FigmaBottomNavBar({
    required this.index,
    required this.onChanged,
    required this.isDark,
    required this.items,
  });

  final int index;
  final ValueChanged<int> onChanged;
  final bool isDark;
  final List<_NavItemData> items;

  @override
  Widget build(BuildContext context) {
    // Figma look: flat white bar, no pill, minimal/no shadow
    final bg = isDark ? const Color(0xFF0F1116) : Colors.white;
    final border = isDark ? const Color(0xFF1C2130) : const Color(0xFFE9ECF2);

    // Selected = near-black in light mode (matches screenshot)
    final selected = isDark ? Colors.white : const Color(0xFF111827);
    final unselected = isDark
        ? const Color(0xFF9AA3B2)
        : const Color(0xFF6B7280);

    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          border: Border(top: BorderSide(color: border, width: 1)),
        ),
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(items.length, (i) {
            final item = items[i];
            final isSelected = index == i;
            return Expanded(
              child: InkWell(
                onTap: () => onChanged(i),
                borderRadius: BorderRadius.circular(14),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isSelected ? item.selectedIcon : item.icon,
                        size: 24,
                        color: isSelected ? selected : unselected,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.0,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isSelected ? selected : unselected,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

/* -------------------- PLACEHOLDER -------------------- */

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: Text('$title (coming soon)')));
  }
}
