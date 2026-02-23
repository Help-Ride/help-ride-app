import 'package:flutter/material.dart';
import 'package:help_ride/features/rides/models/ride.dart';
import '../../../../../core/theme/app_colors.dart';
import 'ride_ui.dart';

class RideAmenitiesCard extends StatelessWidget {
  const RideAmenitiesCard({super.key, required this.ride});

  final Ride ride;

  @override
  Widget build(BuildContext context) {
    final amenities = ride.amenities
        .map(_amenityLabel)
        .where((item) => item.isNotEmpty)
        .toList();
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

String _amenityLabel(String value) {
  final token = value.trim().toLowerCase();
  if (token.isEmpty) return '';
  switch (token) {
    case 'ac':
      return 'AC';
    case 'wifi':
      return 'WiFi';
    case 'pet_friendly':
    case 'pet-friendly':
      return 'Pet-friendly';
    case 'luggage_space':
    case 'luggage-space':
      return 'Luggage space';
    case 'child_seat':
    case 'child-seat':
      return 'Child seat';
    default:
      final words = token
          .replaceAll(RegExp(r'[_\-]+'), ' ')
          .split(' ')
          .where((w) => w.trim().isNotEmpty)
          .toList();
      return words
          .map((w) => '${w[0].toUpperCase()}${w.substring(1)}')
          .join(' ');
  }
}
