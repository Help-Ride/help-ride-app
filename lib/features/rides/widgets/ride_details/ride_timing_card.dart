import 'package:flutter/material.dart';
import 'package:help_ride/features/rides/models/ride.dart';
import 'package:help_ride/features/rides/widgets/ride_formatters.dart';
import 'ride_ui.dart';

class RideTimingCard extends StatelessWidget {
  const RideTimingCard({super.key, required this.ride});

  final Ride ride;

  @override
  Widget build(BuildContext context) {
    final arrival = ride.arrivalTime;
    return AppCard(
      child: Row(
        children: [
          Expanded(
            child: MiniInfo(
              label: 'Start time',
              value: formatDateTime(ride.startTime),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: MiniInfo(
              label: 'Arrival',
              value: arrival == null ? 'Not set' : formatDateTime(arrival),
            ),
          ),
        ],
      ),
    );
  }
}
