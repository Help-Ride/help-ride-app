import 'package:flutter/material.dart';
import 'package:help_ride/features/rides/models/ride.dart';
import 'package:help_ride/features/rides/widgets/ride_formatters.dart';
import '../../../../../core/theme/app_colors.dart';
import 'ride_ui.dart';

class RideTripDetailsCard extends StatelessWidget {
  const RideTripDetailsCard({
    super.key,
    required this.ride,
    this.pickupName,
    this.pickupLat,
    this.pickupLng,
    this.dropoffName,
    this.dropoffLat,
    this.dropoffLng,
    this.showBookingRequestedRouteBanner = false,
  });

  final Ride ride;
  final String? pickupName;
  final double? pickupLat;
  final double? pickupLng;
  final String? dropoffName;
  final double? dropoffLat;
  final double? dropoffLng;
  final bool showBookingRequestedRouteBanner;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppColors.darkMuted : AppColors.lightMuted;
    final textPrimary = isDark ? AppColors.darkText : AppColors.lightText;
    final pickupValue = _nonEmpty(pickupName) ?? ride.fromCity;
    final dropoffValue = _nonEmpty(dropoffName) ?? ride.toCity;
    final pickupCoords = _coordsText(pickupLat, pickupLng);
    final dropoffCoords = _coordsText(dropoffLat, dropoffLng);
    final duration = _formatDuration(ride.startTime, ride.arrivalTime);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showBookingRequestedRouteBanner) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF122033)
                    : const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Showing pickup/drop-off from your booking request',
                style: TextStyle(
                  color: AppColors.driverPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          const TripRow(icon: Icons.my_location, title: 'Pickup', value: ''),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              pickupValue,
              softWrap: true,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                height: 1.15,
                color: textPrimary,
              ),
            ),
          ),
          if (pickupCoords != null) ...[
            const SizedBox(height: 2),
            Text(
              pickupCoords,
              style: TextStyle(color: muted, fontWeight: FontWeight.w600),
            ),
          ],
          const SizedBox(height: 12),

          const TripRow(
            icon: Icons.place,
            title: 'Drop-off',
            value: '',
            iconColor: AppColors.passengerPrimary,
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              dropoffValue,
              softWrap: true,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                height: 1.15,
                color: textPrimary,
              ),
            ),
          ),
          if (dropoffCoords != null) ...[
            const SizedBox(height: 2),
            Text(
              dropoffCoords,
              style: TextStyle(color: muted, fontWeight: FontWeight.w600),
            ),
          ],

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
                child: MiniInfo(label: 'Duration', value: duration),
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
    if (mins < 60) return '$mins min';
    final h = mins ~/ 60;
    final m = mins % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}m';
  }
}

String? _nonEmpty(String? value) {
  if (value == null) return null;
  final cleaned = value.trim();
  return cleaned.isEmpty ? null : cleaned;
}

String? _coordsText(double? lat, double? lng) {
  if (lat == null || lng == null) return null;
  return '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}';
}
