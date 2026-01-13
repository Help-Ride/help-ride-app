import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../home/widgets/common/app_card.dart';

class MiniStatCard extends StatelessWidget {
  const MiniStatCard({
    super.key,
    required this.title,
    required this.subtitle,
    this.badge,
    this.accent = AppColors.driverPrimary,
  });

  final String title;
  final String subtitle;
  final String? badge;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
              if (badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    badge!,
                    style: TextStyle(
                      color: accent,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(subtitle, style: const TextStyle(color: AppColors.lightMuted)),
        ],
      ),
    );
  }
}
