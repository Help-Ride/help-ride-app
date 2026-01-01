import 'package:flutter/material.dart';
import '../models/place_result.dart';
import '../../../core/theme/app_colors.dart';

class PlaceTile extends StatelessWidget {
  const PlaceTile({super.key, required this.place, required this.onTap});

  final PlaceResult place;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: const Icon(Icons.place, color: AppColors.lightMuted),
      title: Text(
        place.primaryText,
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      subtitle: place.secondaryText.isEmpty
          ? null
          : Text(
              place.secondaryText,
              style: const TextStyle(color: AppColors.lightMuted),
            ),
    );
  }
}
