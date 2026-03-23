import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../models/driver_ride_management.dart';

class DriverRideListFilters extends StatelessWidget {
  const DriverRideListFilters({
    super.key,
    required this.active,
    required this.onChange,
  });

  final DriverRideListFilter active;
  final ValueChanged<DriverRideListFilter> onChange;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final items = <(DriverRideListFilter, String)>[
      (DriverRideListFilter.all, 'All'),
      (DriverRideListFilter.oneTime, 'One-time'),
      (DriverRideListFilter.recurring, 'Recurring'),
      (DriverRideListFilter.cancelled, 'Cancelled'),
      (DriverRideListFilter.occurrences, 'Occurrences'),
    ];

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: items.map((item) {
          final selected = active == item.$1;
          return InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: () => onChange(item.$1),
            child: Ink(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.driverPrimary.withValues(alpha: 0.12)
                    : (isDark ? const Color(0xFF111827) : Colors.white),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: selected
                      ? AppColors.driverPrimary
                      : (isDark
                            ? const Color(0xFF232836)
                            : const Color(0xFFE1E7F0)),
                ),
              ),
              child: Text(
                item.$2,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: selected
                      ? AppColors.driverPrimary
                      : (isDark ? AppColors.darkMuted : AppColors.lightMuted),
                ),
              ),
            ),
          );
        }).toList(growable: false),
      ),
    );
  }
}
