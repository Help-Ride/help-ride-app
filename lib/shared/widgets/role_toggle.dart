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

    return Container(
      height: 44,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F4F9),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE3E8F2)),
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
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _Segment(
              selected: !isPassenger,
              label: 'Driver',
              onTap: onDriver,
              selectedColor: driverColor,
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
  });

  final bool selected;
  final String label;
  final VoidCallback onTap;
  final Color selectedColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? Colors.white : Colors.transparent,
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
                color: selected ? selectedColor : const Color(0xFF7B8798),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
