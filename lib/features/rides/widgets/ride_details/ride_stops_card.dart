import 'package:flutter/material.dart';
import 'package:help_ride/features/rides/models/ride.dart';
import '../../../../../core/theme/app_colors.dart';
import 'ride_ui.dart';

class RideStopsCard extends StatelessWidget {
  const RideStopsCard({super.key, required this.ride});

  final Ride ride;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final stops = ride.stops
        .map((stop) => stop.trim())
        .where((stop) => stop.isNotEmpty)
        .toList();

    if (stops.isEmpty) {
      return AppCard(
        child: Text(
          'No intermediate stops.',
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
        children: stops.map((stop) => Tag(stop)).toList(),
      ),
    );
  }
}
