import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../features/home/controllers/home_controller.dart';

class RoleToggle extends StatelessWidget {
  const RoleToggle({
    super.key,
    required this.role,
    required this.onPassenger,
    required this.onDriver,
    this.passengerColor = AppColors.passengerPrimary,
    this.driverColor = AppColors.driverPrimary,
  });

  final HomeRole role;
  final VoidCallback onPassenger;
  final VoidCallback onDriver;

  final Color passengerColor;
  final Color driverColor;

  @override
  Widget build(BuildContext context) {
    final isPassenger = role == HomeRole.passenger;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 44,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C2331) : const Color(0xFFF1F4F9),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? const Color(0xFF232836) : const Color(0xFFE3E8F2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: _Segment(
              selected: isPassenger,
              label: 'Passenger',
              onTap: onPassenger,
              selectedColor: passengerColor,
              isDark: isDark,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _Segment(
              selected: !isPassenger,
              label: 'Driver',
              onTap: onDriver,
              selectedColor: driverColor,
              isDark: isDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.selected,
    required this.label,
    required this.onTap,
    required this.selectedColor,
    required this.isDark,
  });

  final bool selected;
  final String label;
  final VoidCallback onTap;
  final Color selectedColor;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? (isDark ? const Color(0xFF111827) : Colors.white)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: selected
                    ? selectedColor
                    : (isDark ? const Color(0xFF9AA3B2) : const Color(0xFF7B8798)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
