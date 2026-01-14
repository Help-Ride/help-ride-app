import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../controllers/my_rides_controller.dart';

class RidesTabs extends StatelessWidget {
  const RidesTabs({super.key, required this.active, required this.onChange});

  final MyRidesTab active;
  final ValueChanged<MyRidesTab> onChange;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C2331) : const Color(0xFFEFF2F6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF232836) : const Color(0xFFE3E8F2),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _TabPill(
              text: 'Upcoming',
              active: active == MyRidesTab.upcoming,
              onTap: () => onChange(MyRidesTab.upcoming),
              isDark: isDark,
            ),
          ),
          Expanded(
            child: _TabPill(
              text: 'Past',
              active: active == MyRidesTab.past,
              onTap: () => onChange(MyRidesTab.past),
              isDark: isDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _TabPill extends StatelessWidget {
  const _TabPill({
    required this.text,
    required this.active,
    required this.onTap,
    required this.isDark,
  });

  final String text;
  final bool active;
  final VoidCallback onTap;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active
              ? (isDark ? const Color(0xFF111827) : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: active
              ? [
                  BoxShadow(
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                    color: isDark
                        ? Colors.black.withOpacity(0.4)
                        : const Color(0x12000000),
                  ),
                ]
              : const [],
        ),
        child: Text(
          text,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: active
                ? (isDark ? AppColors.darkText : AppColors.lightText)
                : (isDark ? AppColors.darkMuted : AppColors.lightMuted),
          ),
        ),
      ),
    );
  }
}
