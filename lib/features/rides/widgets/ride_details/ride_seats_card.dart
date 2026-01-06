import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:help_ride/features/rides/controllers/ride_details_controller.dart';
import 'package:help_ride/features/rides/models/ride.dart';
import '../../../../../core/theme/app_colors.dart';
import 'ride_ui.dart';

class RideSeatsCard extends GetView<RideDetailsController> {
  const RideSeatsCard({super.key, required this.ride});
  final Ride ride;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Obx(() {
        final max = ride.seatsAvailable <= 0 ? 1 : ride.seatsAvailable;
        final selected = controller.selectedSeats.value.clamp(1, max);
        final options = List<int>.generate(max, (i) => i + 1);

        return Row(
          children: [
            Expanded(
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: options.map((n) {
                  final active = n == selected;
                  return SeatChip(
                    text: '$n seat${n == 1 ? '' : 's'}',
                    active: active,
                    onTap: () => controller.setSeats(n),
                  );
                }).toList(),
              ),
            ),
            Text(
              '${ride.seatsAvailable} available',
              style: const TextStyle(
                color: AppColors.lightMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        );
      }),
    );
  }
}
