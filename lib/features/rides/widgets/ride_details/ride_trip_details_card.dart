import 'package:flutter/material.dart';
import 'package:help_ride/features/rides/models/ride.dart';
import 'package:help_ride/features/rides/widgets/ride_formatters.dart';
import '../../../../../core/theme/app_colors.dart';
import 'ride_ui.dart';

class RideTripDetailsCard extends StatelessWidget {
  const RideTripDetailsCard({super.key, required this.ride});
  final Ride ride;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        children: [
          const TripRow(icon: Icons.my_location, title: 'Pickup', value: ''),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              ride.fromCity,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(height: 12),

          const TripRow(
            icon: Icons.place,
            title: 'Destination',
            value: '',
            iconColor: AppColors.passengerPrimary,
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              ride.toCity,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),

          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFE9EEF6)),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: MiniInfo(
                  label: 'Date & Time',
                  value: formatDateTime(ride.startTime),
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: MiniInfo(
                  label: 'Duration',
                  value: '45 min (placeholder)',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
