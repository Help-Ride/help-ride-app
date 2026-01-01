import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../features/home/controllers/home_controller.dart';

class RoleToggle extends StatelessWidget {
  const RoleToggle({
    super.key,
    required this.role,
    required this.onPassenger,
    required this.onDriver,
  });

  final HomeRole role;
  final VoidCallback onPassenger;
  final VoidCallback onDriver;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F2F6),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE6EAF2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Pill(
            label: "Passenger",
            active: role == HomeRole.passenger,
            activeColor: AppColors.passengerPrimary,
            onTap: onPassenger,
          ),
          _Pill(
            label: "Driver",
            active: role == HomeRole.driver,
            activeColor: AppColors.driverPrimary,
            onTap: onDriver,
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.active,
    required this.activeColor,
    required this.onTap,
  });

  final String label;
  final bool active;
  final Color activeColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          boxShadow: active
              ? const [
                  BoxShadow(
                    blurRadius: 18,
                    offset: Offset(0, 10),
                    color: Color(0x14000000),
                  ),
                ]
              : const [],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: active ? activeColor : AppColors.lightMuted,
          ),
        ),
      ),
    );
  }
}
