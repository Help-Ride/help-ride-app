import 'package:flutter/material.dart';
import '../models/place_result.dart';
import '../../../core/theme/app_colors.dart';

class PlaceTile extends StatelessWidget {
  const PlaceTile({super.key, required this.place, required this.onTap});

  final PlaceResult place;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      onTap: onTap,
      leading: Icon(
        Icons.place,
        color: isDark ? AppColors.darkMuted : AppColors.lightMuted,
      ),
      title: Text(
        place.primaryText,
        style: TextStyle(
          fontWeight: FontWeight.w800,
          color: isDark ? AppColors.darkText : AppColors.lightText,
        ),
      ),
      subtitle: place.secondaryText.isEmpty
          ? null
          : Text(
              place.secondaryText,
              style: TextStyle(
                color: isDark ? AppColors.darkMuted : AppColors.lightMuted,
              ),
            ),
    );
  }
}
