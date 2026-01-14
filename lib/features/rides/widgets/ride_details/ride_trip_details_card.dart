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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final duration = _formatDuration(ride.startTime, ride.arrivalTime);
    return AppCard(
      child: Column(
        children: [
          const TripRow(icon: Icons.my_location, title: 'Pickup', value: ''),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              ride.fromCity,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: isDark ? AppColors.darkText : AppColors.lightText,
              ),
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
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: isDark ? AppColors.darkText : AppColors.lightText,
              ),
            ),
          ),

          const SizedBox(height: 12),
          Divider(
            height: 1,
            color: isDark ? const Color(0xFF232836) : const Color(0xFFE9EEF6),
          ),
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
              Expanded(
                child: MiniInfo(
                  label: 'Duration',
                  value: duration,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDuration(DateTime start, DateTime? end) {
    if (end == null) return '—';
    final diff = end.difference(start);
    if (diff.isNegative) return '—';
    final mins = diff.inMinutes;
    if (mins < 60) return '${mins} min';
    final h = mins ~/ 60;
    final m = mins % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}m';
  }
}
