import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:help_ride/features/rides/controllers/ride_details_controller.dart';
import '../../../../../core/theme/app_colors.dart';

class RideDetailsBottomBar extends GetView<RideDetailsController> {
  const RideDetailsBottomBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final ride = controller.ride.value;
      if (ride == null) return const SizedBox.shrink();

      final total = controller.totalPrice;

      return Container(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE9EEF6))),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '\$${total.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '\$${ride.pricePerSeat.toStringAsFixed(0)} × ${controller.selectedSeats.value} seat',
                    style: const TextStyle(
                      color: AppColors.lightMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 46,
              child: ElevatedButton(
                onPressed: ride.seatsAvailable <= 0
                    ? null
                    : controller.openConfirmSheet,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.passengerPrimary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFFE9EEF6),
                  disabledForegroundColor: const Color(0xFF9AA3B2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                ),
                child: const Text(
                  'Request Ride',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}
