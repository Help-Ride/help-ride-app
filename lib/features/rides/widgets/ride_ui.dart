import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class AppCard extends StatelessWidget {
  const AppCard({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF232836) : const Color(0xFFE6EAF2),
        ),
        boxShadow: isDark
            ? []
            : const [
                BoxShadow(
                  blurRadius: 20,
                  offset: Offset(0, 10),
                  color: Color(0x0A000000),
                ),
              ],
      ),
      child: child,
    );
  }
}

class Avatar extends StatelessWidget {
  const Avatar({super.key, required this.initials});
  final String initials;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 44,
      width: 44,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C2331) : const Color(0xFFE9EEF6),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          fontWeight: FontWeight.w900,
          color: isDark ? AppColors.darkText : AppColors.lightText,
        ),
      ),
    );
  }
}

class Pill extends StatelessWidget {
  const Pill({super.key, required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF122033) : const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: AppColors.driverPrimary,
        ),
      ),
    );
  }
}

class SeatChip extends StatelessWidget {
  const SeatChip({
    super.key,
    required this.text,
    required this.active,
    required this.onTap,
  });

  final String text;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 40,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active
              ? (isDark ? const Color(0xFF14382B) : const Color(0xFFE7F8EF))
              : (isDark ? AppColors.darkSurface : Colors.white),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: active
                ? AppColors.passengerPrimary
                : (isDark ? const Color(0xFF232836) : const Color(0xFFE2E6EF)),
            width: 1.5,
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: active
                ? AppColors.passengerPrimary
                : (isDark ? AppColors.darkText : AppColors.lightText),
          ),
        ),
      ),
    );
  }
}
