import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:help_ride/features/bookings/controllers/my_rides_controller.dart';
import 'package:help_ride/features/bookings/views/my_rides_view.dart';
import 'package:help_ride/features/driver/controllers/driver_gate_controller.dart';
import 'package:help_ride/features/driver/controllers/driver_home_controller.dart';
import 'package:help_ride/features/driver/controllers/driver_my_rides_controller.dart';
import 'package:help_ride/features/driver/views/driver_my_rides_view.dart';
import '../../core/theme/theme_controller.dart';
import '../controllers/session_controller.dart';
import '../services/location_sync_service.dart';
import '../../core/constants/app_constants.dart';

// pages
import '../../features/home/views/home_view.dart';
import '../../features/chat/views/messages_view.dart';
import '../../features/profile/views/passenger_profile_view.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> with WidgetsBindingObserver {
  int index = 0;
  bool _openDriverEditorOnLoad = false;
  bool _redirectingToVerification = false;
  late final Worker _roleWorker;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _applyNavigationArgs(Get.arguments);
    Get.lazyPut<DriverMyRidesController>(
      () => DriverMyRidesController(),
      fenix: true,
    );
    Get.lazyPut<MyRidesController>(() => MyRidesController(), fenix: true);
    Get.lazyPut<DriverGateController>(
      () => DriverGateController(),
      fenix: true,
    );
    Get.lazyPut<DriverHomeController>(
      () => DriverHomeController(),
      fenix: true,
    );

    final theme = Get.find<ThemeController>();
    _roleWorker = ever<AppRole>(theme.role, (_) {
      if (!mounted) return;
      setState(() => index = 0);
    });

    unawaited(_syncLocationOnAppActive());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _roleWorker.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_syncLocationOnAppActive());
    }
  }

  void _applyNavigationArgs(dynamic argsRaw) {
    if (argsRaw is! Map) return;
    final args = argsRaw.cast<dynamic, dynamic>();
    final parsed = _parseTabIndex(args['tab']);
    if (parsed == null || parsed < 0) return;
    index = parsed;
    _openDriverEditorOnLoad = _parseBool(args['openDriverEditorOnLoad']);
  }

  bool _parseBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value == null) return false;
    final normalized = value.toString().trim().toLowerCase();
    return normalized == 'true' || normalized == '1' || normalized == 'yes';
  }

  int? _parseTabIndex(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    final normalized = value.toString().trim().toLowerCase();
    switch (normalized) {
      case 'home':
        return 0;
      case 'rides':
      case 'myrides':
      case 'my_rides':
      case 'my-rides':
        return 1;
      case 'messages':
        return 2;
      case 'profile':
        return 3;
      default:
        return int.tryParse(normalized);
    }
  }

  Future<void> _syncLocationOnAppActive() async {
    if (!Get.isRegistered<SessionController>()) return;
    final session = Get.find<SessionController>();
    if (session.status.value != SessionStatus.authenticated) return;

    try {
      await LocationSyncService.instance.syncMyLocation(
        requestPermission: false,
      );
    } catch (_) {
      // Best-effort sync on open/resume.
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = Get.find<SessionController>();
    final theme = Get.find<ThemeController>();

    return Obx(() {
      if (session.status.value != SessionStatus.authenticated) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }

      final requiredVerification = session.nextRequiredVerification;
      if (requiredVerification != null) {
        if (!_redirectingToVerification) {
          _redirectingToVerification = true;
          Future.microtask(() => session.openVerifiedAppDestination());
        }
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      _redirectingToVerification = false;

      final uiRole = theme.role.value;
      final driverGate = Get.find<DriverGateController>();
      final allowDriverProfileTabWithoutProfile =
          uiRole == AppRole.driver &&
          !driverGate.hasDriverProfile &&
          index == 3;
      final hideBottomNavForDriverOnboarding =
          uiRole == AppRole.driver &&
          !driverGate.hasDriverProfile &&
          !allowDriverProfileTabWithoutProfile;
      final config = uiRole == AppRole.driver
          ? _driverConfig(openDriverEditorOnLoad: _openDriverEditorOnLoad)
          : _passengerConfig(openDriverEditorOnLoad: _openDriverEditorOnLoad);

      if (index >= config.items.length) index = 0;
      final activeIndex = hideBottomNavForDriverOnboarding ? 0 : index;
      if (activeIndex == 3 && _openDriverEditorOnLoad) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || !_openDriverEditorOnLoad) return;
          setState(() => _openDriverEditorOnLoad = false);
        });
      }

      final isDark = Theme.of(context).brightness == Brightness.dark;
      return Scaffold(
        body: config.pages[activeIndex],
        bottomNavigationBar: hideBottomNavForDriverOnboarding
            ? null
            : _FigmaBottomNavBar(
                index: activeIndex,
                isDark: isDark,
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

_NavConfig _passengerConfig({required bool openDriverEditorOnLoad}) {
  final pages = [
    const HomeView(),
    const MyRidesView(),
    const MessagesView(),
    PassengerProfileView(openDriverEditorOnLoad: openDriverEditorOnLoad),
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

_NavConfig _driverConfig({required bool openDriverEditorOnLoad}) {
  final pages = [
    const HomeView(),
    const DriverMyRidesView(),
    const MessagesView(),
    PassengerProfileView(openDriverEditorOnLoad: openDriverEditorOnLoad),
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
      selectedIcon: Icons.add_circle,
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
    final bg = isDark ? const Color(0xFF0F1116) : Colors.white;
    final border = isDark ? const Color(0xFF1C2130) : const Color(0xFFE9ECF2);
    final selected = isDark ? Colors.white : const Color(0xFF111827);
    final unselected = isDark
        ? const Color(0xFF9AA3B2)
        : const Color(0xFF6B7280);
    final selectedBg = isDark
        ? const Color(0xFF1B2230)
        : const Color(0xFFF4F7FB);

    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          border: Border(top: BorderSide(color: border, width: 1)),
          boxShadow: [
            BoxShadow(
              color: isDark ? const Color(0x2A000000) : const Color(0x080F172A),
              blurRadius: 18,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(items.length, (i) {
            final item = items[i];
            final isSelected = index == i;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: InkWell(
                  onTap: () => onChanged(i),
                  borderRadius: BorderRadius.circular(18),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOut,
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? selectedBg : Colors.transparent,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          curve: Curves.easeOut,
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? (isDark
                                      ? Colors.white.withValues(alpha: 0.08)
                                      : Colors.white)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            isSelected ? item.selectedIcon : item.icon,
                            size: 22,
                            color: isSelected ? selected : unselected,
                          ),
                        ),
                        const SizedBox(height: 5),
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
              ),
            );
          }),
        ),
      ),
    );
  }
}
