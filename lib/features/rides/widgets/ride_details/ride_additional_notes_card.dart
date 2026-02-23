import 'package:flutter/material.dart';
import 'package:help_ride/features/rides/models/ride.dart';
import '../../../../../core/theme/app_colors.dart';
import 'ride_ui.dart';

class RideAdditionalNotesCard extends StatelessWidget {
  const RideAdditionalNotesCard({super.key, required this.ride});

  final Ride ride;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final notes = (ride.notes ?? '').trim();
    final text = notes.isEmpty ? 'No additional notes provided.' : notes;

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
