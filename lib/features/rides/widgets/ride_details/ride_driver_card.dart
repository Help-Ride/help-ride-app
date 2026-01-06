import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:help_ride/features/rides/models/ride.dart';
import 'package:help_ride/features/rides/widgets/ride_formatters.dart';
import 'package:help_ride/features/rides/widgets/ride_details/ride_ui.dart';
import '../../../../../core/theme/app_colors.dart';

class RideDriverCard extends StatelessWidget {
  const RideDriverCard({super.key, required this.ride});
  final Ride ride;

  @override
  Widget build(BuildContext context) {
    final driverName = ride.driver?.name ?? 'Driver';

    return AppCard(
      child: Row(
        children: [
          Avatar(initials: initials(driverName)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        driverName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Pill(text: 'Verified'),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  '⭐ 4.9  •  127 rides  •  Since 2023',
                  style: TextStyle(
                    color: AppColors.lightMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Get.snackbar('Call', 'Later'),
                        icon: const Icon(Icons.call, size: 18),
                        label: const Text('Call'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Get.snackbar('Message', 'Later'),
                        icon: const Icon(Icons.chat_bubble_outline, size: 18),
                        label: const Text('Message'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
