import 'package:flutter/material.dart';
import 'package:get/get.dart';
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
  Widget build(BuildContext context) {
    final session = Get.find<SessionController>();
    final theme = Get.find<ThemeController>();

    return Obx(() {
      // 🔒 Only show shell if authenticated
      if (session.status.value != SessionStatus.authenticated) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }

      final role = (session.user.value?.roleDefault ?? 'passenger')
          .toString()
          .toLowerCase();

      final config = role == 'driver' ? _driverConfig() : _passengerConfig();

      // ✅ Prevent "index out of range" when role changes
      if (index >= config.items.length) index = 0;

      return Scaffold(
        body: config.pages[index],
        bottomNavigationBar: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: _BottomNavBar(
              index: index,
              isDark: theme.isDark.value,
              items: config.items,
              onChanged: (i) => setState(() => index = i),
            ),
          ),
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
    _Placeholder(title: 'My Rides'),
    _Placeholder(title: 'Messages'),
    PassengerProfileView(),
  ];

  final items = const [
    _NavItemData(label: 'Home', icon: Icons.home_rounded),
    _NavItemData(label: 'My Rides', icon: Icons.access_time_rounded),
    _NavItemData(label: 'Messages', icon: Icons.chat_bubble_outline_rounded),
    _NavItemData(label: 'Profile', icon: Icons.person_outline_rounded),
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

  final items = const [
    _NavItemData(label: 'Home', icon: Icons.home_rounded),
    _NavItemData(label: 'Create', icon: Icons.add_circle_outline_rounded),
    _NavItemData(label: 'Requests', icon: Icons.list_alt_rounded),
    _NavItemData(label: 'Profile', icon: Icons.person_outline_rounded),
  ];

  return _NavConfig(items, pages);
}

/* -------------------- UI COMPONENTS -------------------- */

class _NavItemData {
  final String label;
  final IconData icon;
  const _NavItemData({required this.label, required this.icon});
}

class _BottomNavBar extends StatelessWidget {
  const _BottomNavBar({
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
    final bg = isDark ? const Color(0xFF121218) : Colors.white;
    final inactive = isDark ? const Color(0xFF9A9AA6) : const Color(0xFF8A8FA3);
    final active = AppColors.primary;

    return Container(
      height: 82,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            blurRadius: 22,
            offset: Offset(0, 10),
            color: Color(0x33000000),
          ),
        ],
      ),
      child: Row(
        children: List.generate(items.length, (i) {
          final item = items[i];
          return _NavItem(
            label: item.label,
            icon: item.icon,
            selected: index == i,
            active: active,
            inactive: inactive,
            onTap: () => onChanged(i),
          );
        }),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.label,
    required this.icon,
    required this.selected,
    required this.active,
    required this.inactive,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final Color active;
  final Color inactive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          margin: const EdgeInsets.all(8),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? active.withOpacity(0.14) : Colors.transparent,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 24, color: selected ? active : inactive),
              const SizedBox(height: 4),
              FittedBox(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected ? active : inactive,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: Text('$title (coming soon)')));
  }
}
