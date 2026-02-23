import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class PickerTile extends StatelessWidget {
  const PickerTile({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isEmpty = value.trim().isEmpty;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: isDark ? AppColors.darkText : AppColors.lightText,
          ),
        ),
        const SizedBox(height: 8),
        Material(
          color: isDark ? const Color(0xFF1C2331) : const Color(0xFFF3F5F8),
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: Container(
              constraints: const BoxConstraints(minHeight: 56),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  Icon(
                    icon,
                    color: isDark ? AppColors.darkMuted : AppColors.lightMuted,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      isEmpty ? 'Select' : value,
                      maxLines: 2,
                      softWrap: true,
                      style: TextStyle(
                        color: isEmpty
                            ? (isDark
                                  ? AppColors.darkMuted
                                  : AppColors.lightMuted)
                            : (isDark
                                  ? AppColors.darkText
                                  : AppColors.lightText),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
