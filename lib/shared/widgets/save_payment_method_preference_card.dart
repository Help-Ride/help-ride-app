import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class SavePaymentMethodPreferenceCard extends StatelessWidget {
  const SavePaymentMethodPreferenceCard({
    super.key,
    required this.value,
    required this.onChanged,
    required this.title,
    required this.description,
    required this.isDark,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final String title;
  final String description;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark ? AppColors.darkText : AppColors.lightText;
    final muted = isDark ? AppColors.darkMuted : AppColors.lightMuted;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF232836) : const Color(0xFFE6EAF2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: TextStyle(color: muted, height: 1.35, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.passengerPrimary,
            activeTrackColor: AppColors.passengerPrimary.withValues(
              alpha: 0.35,
            ),
          ),
        ],
      ),
    );
  }
}
