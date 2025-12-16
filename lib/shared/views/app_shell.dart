import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_controller.dart';
import '../../features/home/views/home_view.dart';
import '../../features/profile/views/passenger_profile_view.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int index = 0;

  final pages = const [
    HomeView(),
    _Placeholder(title: 'My Rides'),
    _Placeholder(title: 'Messages'),
    PassengerProfileView(),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Get.find<ThemeController>();

    return Scaffold(
      body: pages[index],
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          child: _BottomNavBar(
            index: index,
            isDark: theme.isDark.value,
            onChanged: (i) => setState(() => index = i),
          ),
        ),
      ),
    );
  }
}

class _BottomNavBar extends StatelessWidget {
  const _BottomNavBar({
    required this.index,
    required this.onChanged,
    required this.isDark,
  });

  final int index;
  final ValueChanged<int> onChanged;
  final bool isDark;

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
        children: [
          _NavItem(
            label: 'Home',
            icon: Icons.home_rounded,
            selected: index == 0,
            active: active,
            inactive: inactive,
            onTap: () => onChanged(0),
          ),
          _NavItem(
            label: 'My Rides',
            icon: Icons.access_time_rounded,
            selected: index == 1,
            active: active,
            inactive: inactive,
            onTap: () => onChanged(1),
          ),
          _NavItem(
            label: 'Messages',
            icon: Icons.chat_bubble_outline_rounded,
            selected: index == 2,
            active: active,
            inactive: inactive,
            onTap: () => onChanged(2),
          ),
          _NavItem(
            label: 'Profile',
            icon: Icons.person_outline_rounded,
            selected: index == 3,
            active: active,
            inactive: inactive,
            onTap: () => onChanged(3),
          ),
        ],
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
            mainAxisSize: MainAxisSize.min, // 🔑 prevents overflow
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 24, color: selected ? active : inactive),
              const SizedBox(height: 4),
              FittedBox(
                // 🔑 text never overflows
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
