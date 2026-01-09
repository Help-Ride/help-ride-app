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
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,

        child: AppCard(
          child: Row(
            children: [
              const Icon(Icons.history, color: AppColors.lightMuted),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "$from  →  $to",
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      when,
                      style: const TextStyle(color: AppColors.lightMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
