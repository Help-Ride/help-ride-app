import 'package:flutter/material.dart';
import 'package:help_ride/features/rides/models/ride.dart';
import '../../../../../core/theme/app_colors.dart';
import 'ride_ui.dart';

class RideAmenitiesCard extends StatelessWidget {
  const RideAmenitiesCard({super.key, required this.ride});

  final Ride ride;

  @override
  Widget build(BuildContext context) {
    final amenities = ride.amenities;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (amenities.isEmpty) {
      return AppCard(
        child: Text(
          'No amenities listed.',
          style: TextStyle(
            color: isDark ? AppColors.darkMuted : AppColors.lightMuted,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return AppCard(
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: amenities.map((item) => Tag(item)).toList(),
      ),
    );
  }
}
