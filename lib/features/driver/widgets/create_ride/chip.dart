import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class SelectChip extends StatelessWidget {
  const SelectChip({
    super.key,
    required this.text,
    required this.active,
    required this.activeColor,
    required this.onTap,
  });

  final String text;
  final bool active;
  final Color activeColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: active
                ? activeColor.withOpacity(isDark ? 0.22 : 0.12)
                : (isDark ? AppColors.darkSurface : Colors.white),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: active
                  ? activeColor
                  : (isDark ? const Color(0xFF232836) : const Color(0xFFE2E6EF)),
              width: 1.4,
            ),
          ),
          child: Text(
            text,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: active
                  ? activeColor
                  : (isDark ? AppColors.darkText : AppColors.lightText),
            ),
          ),
        ),
      ),
    );
  }
}
