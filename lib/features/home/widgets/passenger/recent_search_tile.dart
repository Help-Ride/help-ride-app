import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../common/app_card.dart';

class RecentSearchTile extends StatelessWidget {
  const RecentSearchTile({
    super.key,
    required this.from,
    required this.to,
    required this.when,
    this.onTap,
  });

  final String from;
  final String to;
  final String when;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: AppCard(
            showShadow: false,
            child: Row(
              children: [
                Icon(
                  Icons.history,
                  color: isDark ? AppColors.darkMuted : AppColors.lightMuted,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "$from  →  $to",
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: isDark ? AppColors.darkText : AppColors.lightText,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        when,
                        style: TextStyle(
                          color: isDark ? AppColors.darkMuted : AppColors.lightMuted,
                        ),
                      ),
                    ],
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
