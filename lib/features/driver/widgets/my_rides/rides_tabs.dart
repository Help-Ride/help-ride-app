import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../controllers/driver_my_rides_controller.dart';

class DriverRidesTabs extends StatelessWidget {
  const DriverRidesTabs({
    super.key,
    required this.active,
    required this.onChange,
  });

  final DriverRidesTab active;
  final ValueChanged<DriverRidesTab> onChange;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF2F6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE3E8F2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _Pill(
              text: 'Upcoming',
              active: active == DriverRidesTab.upcoming,
              onTap: () => onChange(DriverRidesTab.upcoming),
            ),
          ),
          Expanded(
            child: _Pill(
              text: 'Past',
              active: active == DriverRidesTab.past,
              onTap: () => onChange(DriverRidesTab.past),
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text, required this.active, required this.onTap});

  final String text;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: active
              ? const [
                  BoxShadow(
                    blurRadius: 12,
                    offset: Offset(0, 6),
                    color: Color(0x12000000),
                  ),
                ]
              : const [],
        ),
        child: Text(
          text,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: active ? AppColors.lightText : AppColors.lightMuted,
          ),
        ),
      ),
    );
  }
}
