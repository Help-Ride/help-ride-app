import 'package:flutter/material.dart';
import 'package:help_ride/features/rides/models/ride.dart';
import '../../../../../core/theme/app_colors.dart';
import 'ride_ui.dart';

class RidePickupInstructionsCard extends StatelessWidget {
  const RidePickupInstructionsCard({super.key, required this.ride});

  final Ride ride;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final instructions = (ride.pickupInstructions ?? ride.notes ?? '').trim();
    final text = instructions.isEmpty
        ? 'No pickup instructions provided.'
        : instructions;

    return AppCard(
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: isDark ? AppColors.darkText : AppColors.lightText,
        ),
      ),
    );
  }
}
