import 'package:flutter/material.dart';
import 'package:help_ride/features/rides/models/ride.dart';
import 'package:help_ride/features/rides/widgets/ride_formatters.dart';
import 'ride_ui.dart';

class RideInfoCard extends StatelessWidget {
  const RideInfoCard({super.key, required this.ride});
  final Ride ride;

  @override
  Widget build(BuildContext context) {
    final created = ride.createdAt == null
        ? null
        : formatDateTime(ride.createdAt!);
    final updated = ride.updatedAt == null
        ? null
        : formatDateTime(ride.updatedAt!);
    final status = _statusLabel(ride.status);
    final seats = '${ride.seatsAvailable}/${ride.seatsTotal}';

    return AppCard(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: MiniInfo(
                  label: 'Status',
                  value: status,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: MiniInfo(
                  label: 'Price/seat',
                  value: '\$${ride.pricePerSeat.toStringAsFixed(0)}',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: MiniInfo(
                  label: 'Seats',
                  value: seats,
                ),
              ),
            ],
          ),
          if (created != null || updated != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: MiniInfo(
                    label: 'Created',
                    value: created ?? '—',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: MiniInfo(
                    label: 'Updated',
                    value: updated ?? '—',
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _statusLabel(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return '—';
    final lower = trimmed.toLowerCase();
    return lower[0].toUpperCase() + lower.substring(1);
  }
}
