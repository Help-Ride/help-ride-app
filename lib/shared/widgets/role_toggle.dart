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
        mainAxisSize: MainAxisSize.min, // important
        children: [
          Expanded(
            child: _Segment(
              selected: isPassenger,
              label: 'Passenger',
              onTap: onPassenger,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _Segment(
              selected: !isPassenger,
              label: 'Driver',
              onTap: onDriver,
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
  });

  final bool selected;
  final String label;
  final VoidCallback onTap;

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
            // keep padding tight so it doesn't overflow on small widths
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: selected
                    ? AppColors.passengerPrimary
                    : const Color(0xFF7B8798),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
