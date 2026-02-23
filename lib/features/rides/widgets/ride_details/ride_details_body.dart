import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:help_ride/features/rides/controllers/ride_details_controller.dart';
import 'package:help_ride/features/rides/widgets/ride_details/ride_ui.dart';
import '../../../../../core/theme/app_colors.dart';
import 'ride_driver_card.dart';
import 'ride_trip_details_card.dart';
import 'ride_seats_card.dart';
import 'ride_amenities_card.dart';
import 'ride_pickup_instructions_card.dart';
import 'ride_stops_card.dart';
import 'ride_additional_notes_card.dart';
import 'ride_timing_card.dart';

class RideDetailsBody extends GetView<RideDetailsController> {
  const RideDetailsBody({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.loading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      final err = controller.error.value;
      if (err != null) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  err,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.error),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: controller.fetch,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        );
      }

      final ride = controller.ride.value;
      if (ride == null) {
        return const Center(child: Text('Ride not found.'));
      }

      return ListView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
        children: [
          RideDriverCard(ride: ride),
          const SizedBox(height: 14),

          const SectionTitle('Trip Details'),
          RideTripDetailsCard(
            ride: ride,
            pickupName: controller.tripPickupName,
            pickupLat: controller.tripPickupLat,
            pickupLng: controller.tripPickupLng,
            dropoffName: controller.tripDropoffName,
            dropoffLat: controller.tripDropoffLat,
            dropoffLng: controller.tripDropoffLng,
            showBookingRequestedRouteBanner: controller.hasBookingRouteContext,
          ),
          const SizedBox(height: 14),

          const SectionTitle('Timing'),
          RideTimingCard(ride: ride),
          const SizedBox(height: 14),

          const SectionTitle('Stops'),
          RideStopsCard(ride: ride),
          const SizedBox(height: 14),

          const SectionTitle('Select Seats'),
          RideSeatsCard(ride: ride),
          const SizedBox(height: 14),

          const SectionTitle('Amenities'),
          RideAmenitiesCard(ride: ride),

          if ((ride.pickupInstructions ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 14),
            const SectionTitle('Pickup Instructions'),
            RidePickupInstructionsCard(ride: ride),
          ],

          const SizedBox(height: 14),
          const SectionTitle('Additional Notes'),
          RideAdditionalNotesCard(ride: ride),
        ],
      );
    });
  }
}
