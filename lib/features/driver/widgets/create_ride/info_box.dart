import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class InfoBox extends StatelessWidget {
  const InfoBox({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.driverPrimary.withOpacity(0.10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.driverPrimary.withOpacity(0.16)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: AppColors.driverPrimary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'How it works\n\nOnce you publish your ride, passengers can search and request seats. You will be notified when someone requests, and you can manage requests from your rides list.',
              style: TextStyle(
                color: isDark ? AppColors.darkText : AppColors.lightText,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
