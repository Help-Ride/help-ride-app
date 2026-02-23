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
    final inactiveText = isDark
        ? const Color(0xFF9AA3B2)
        : const Color(0xFF7B8798);

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
      child: LayoutBuilder(
        builder: (context, constraints) {
          final pillWidth = (constraints.maxWidth - 4) / 2;
          return Stack(
            children: [
              AnimatedAlign(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                alignment: isPassenger
                    ? Alignment.centerLeft
                    : Alignment.centerRight,
                child: Container(
                  width: pillWidth,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF111827) : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                        color: isDark
                            ? Colors.black.withValues(alpha: 0.35)
                            : const Color(0x10000000),
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: _RoleLabel(
                      selected: isPassenger,
                      label: 'Passenger',
                      onTap: isPassenger ? null : onPassenger,
                      selectedColor: passengerColor,
                      inactiveColor: inactiveText,
                    ),
                  ),
                  Expanded(
                    child: _RoleLabel(
                      selected: !isPassenger,
                      label: 'Driver',
                      onTap: isPassenger ? onDriver : null,
                      selectedColor: driverColor,
                      inactiveColor: inactiveText,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _RoleLabel extends StatelessWidget {
  const _RoleLabel({
    required this.selected,
    required this.label,
    required this.onTap,
    required this.selectedColor,
    required this.inactiveColor,
  });

  final bool selected;
  final String label;
  final VoidCallback? onTap;
  final Color selectedColor;
  final Color inactiveColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Center(
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: selected ? selectedColor : inactiveColor,
            ),
            child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ),
      ),
    );
  }
}
