import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/theme/app_colors.dart';

Future<String?> showRideScopeSheet({
  required BuildContext context,
  required String title,
  required String subtitle,
  bool includeOccurrence = true,
  String? recommendedScope,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final textPrimary = isDark ? AppColors.darkText : AppColors.lightText;
  final textMuted = isDark ? AppColors.darkMuted : AppColors.lightMuted;
  final options = <_RideScopeOption>[
    if (includeOccurrence)
      const _RideScopeOption(
        value: 'occurrence',
        title: 'This occurrence only',
        description: 'Update or cancel only the selected ride.',
      ),
    const _RideScopeOption(
      value: 'future',
      title: 'This and future occurrences',
      description: 'Apply to the selected ride and later rides in this series.',
    ),
    const _RideScopeOption(
      value: 'series',
      title: 'Entire series',
      description: 'Apply to all rides in the recurring series.',
    ),
  ];

  return Get.bottomSheet<String>(
    Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: TextStyle(color: textMuted, height: 1.4),
              ),
              const SizedBox(height: 18),
              ...options.map(
                (option) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () => Get.back(result: option.value),
                    child: Ink(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF111827)
                            : const Color(0xFFF6F8FB),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: option.value == recommendedScope
                              ? AppColors.driverPrimary
                              : (isDark
                                    ? const Color(0xFF232836)
                                    : const Color(0xFFE2E8F0)),
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
                                  option.title,
                                  style: TextStyle(
                                    color: textPrimary,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  option.description,
                                  style: TextStyle(
                                    color: textMuted,
                                    fontSize: 13,
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (option.value == recommendedScope)
                            const Padding(
                              padding: EdgeInsets.only(left: 10),
                              child: Icon(
                                Icons.check_circle,
                                color: AppColors.driverPrimary,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Get.back<String?>(),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
  );
}

class _RideScopeOption {
  const _RideScopeOption({
    required this.value,
    required this.title,
    required this.description,
  });

  final String value;
  final String title;
  final String description;
}
