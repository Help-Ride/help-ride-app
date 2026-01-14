import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class InputFieldTile extends StatelessWidget {
  const InputFieldTile({
    super.key,
    required this.icon,
    required this.label,
    this.iconColor,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color? iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: isDark ? const Color(0xFF1C2331) : const Color(0xFFF3F5F8),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: SizedBox(
          height: 56,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: iconColor ??
                      (isDark ? AppColors.darkMuted : AppColors.lightMuted),
                ),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: TextStyle(
                    color: isDark ? AppColors.darkMuted : AppColors.lightMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
